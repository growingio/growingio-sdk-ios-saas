//
//  GrowingAnalytics
//  Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import "GrowingAsaFetcher.h"
#import <objc/runtime.h>
#import <pthread.h>
#import "GrowingCocoaLumberjack.h"
#import "GrowingFileStore.h"
#import "GrowingGlobal.h"

static NSErrorDomain const kGrowingAsaFetcherErrorDomain = @"GrowingAsaFetcherErrorDomain";
typedef NS_ERROR_ENUM(kGrowingAsaFetcherErrorDomain, GrowingAsaFetcherError) {
    GrowingAsaFetcherErrorTrackingRestrictedOrDenied = 1,
    GrowingAsaFetcherErrorMissingData = 2,
    GrowingAsaFetcherErrorCorruptResponse = 3,
    GrowingAsaFetcherErrorRequestClientError = 4,
    GrowingAsaFetcherErrorRequestServerError = 5,
    GrowingAsaFetcherErrorRequestNetworkError = 6,
    GrowingAsaFetcherErrorUnsupportedPlatform = 7,
    GrowingAsaFetcherErrorTimedOut = 100,
    GrowingAsaFetcherErrorTokenInvalid = 101
};

CGFloat const GrowingAsaFetcherDefaultTimeOut = 15.0f;
static NSInteger const _retryCount = 3;
static CGFloat const _retryDelay = 5.0f;
static CGFloat const _eachRequestTimeOut = 5.0f;
static pthread_rwlock_t _lock = PTHREAD_RWLOCK_INITIALIZER;

@interface GrowingAsaFetcher ()

@property (nonatomic, assign) NSInteger retriesLeft;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, weak) NSURLSessionDataTask *task;

@end

@implementation GrowingAsaFetcher

#pragma mark - Init

+ (instancetype)sharedInstance {
    static GrowingAsaFetcher *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GrowingAsaFetcher alloc] init];
    });
    return instance;
}

#pragma mark - Public Method

+ (void)startFetchWithTimeOut:(CGFloat)timeOut {
    if (self.status >= GrowingAsaFetcherStatusFetching) {
        return;
    }
    
    if (GrowingFileStore.didUploadActivate) {
        
        self.status = GrowingAsaFetcherStatusCompleted;
        return;
    }
    
    if (SDKDoNotTrack()) {
        self.status = GrowingAsaFetcherStatusDenied;
        return;
    }
    
    if (!g_asaEnabled) {
        self.status = GrowingAsaFetcherStatusDenied;
        return;
    }
    
    if (@available(iOS 14.3, *)) {
        Class cls = NSClassFromString(@"AAAttribution");
        if (cls == nil) {
            self.status = GrowingAsaFetcherStatusDenied;
            return;
        }
    } else {
        Class cls = NSClassFromString(@"ADClient");
        if (cls == nil) {
            self.status = GrowingAsaFetcherStatusDenied;
            return;
        }
    }
    
    GIOLogDebug(@"AsaFetcher start fetch with time out %.2f sec", timeOut);
    self.status = GrowingAsaFetcherStatusFetching;
    [GrowingAsaFetcher sharedInstance].retriesLeft = _retryCount;
    [[GrowingAsaFetcher sharedInstance] fetchAttribution];
    
    
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeOut * NSEC_PER_SEC));
    dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.status != GrowingAsaFetcherStatusFetching) {
            return;
        }
        
        [GrowingAsaFetcher sharedInstance].retriesLeft = 0;
        if (@available(iOS 14.3, *)) {
            if ([GrowingAsaFetcher sharedInstance].token.length > 0) {
                NSString *token = [GrowingAsaFetcher sharedInstance].token;
                GrowingAsaFetcher.asaData = [GrowingAsaFetcher mapDictionaryForUpload:@{@"token" : token}
                                                                                isIAd:NO];
            }
            
            if ([GrowingAsaFetcher sharedInstance].task) {
                if ([GrowingAsaFetcher sharedInstance].task.state == NSURLSessionTaskStateRunning) {
                    [[GrowingAsaFetcher sharedInstance].task cancel];
                }
                [GrowingAsaFetcher sharedInstance].task = nil;
            }
        }
        GrowingAsaFetcher.status = GrowingAsaFetcherStatusFailure;
        GIOLogError(@"AsaFetcher error: total time is out");
    });
}

+ (void)retry {
    if (self.status >= GrowingAsaFetcherStatusFetching) {
        return;
    }
    
    GIOLogDebug(@"AsaFetcher begin retry");
    self.status = GrowingAsaFetcherStatusFetching;
    [GrowingAsaFetcher sharedInstance].retriesLeft = 1; 
    [[GrowingAsaFetcher sharedInstance] fetchAttribution];
}

#pragma mark - Private Method

- (void)fetchAttribution {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (@available(iOS 14.3, *)) {
            if (self.token.length > 0) {
                [self attributionWithToken:self.token];
            } else {
                [self fetchFromAdServices];
            }
        } else {
            [self fetchFromIAd];
        }
    });
}

- (void)saveAttributionDetails:(NSDictionary *_Nullable)attributionDetails isIAd:(BOOL)isIAd error:(NSError *_Nullable)error {
    
    if (GrowingAsaFetcher.status != GrowingAsaFetcherStatusFetching) {
        return;
    }
    
    if (error) {
        GIOLogError(@"AsaFetcher error: %@", error.description);
        switch (error.code) {
            case GrowingAsaFetcherErrorMissingData:
            case GrowingAsaFetcherErrorCorruptResponse:
            case GrowingAsaFetcherErrorRequestClientError:
            case GrowingAsaFetcherErrorRequestServerError:
            case GrowingAsaFetcherErrorRequestNetworkError: {
                
                int64_t retryDelay = 0;
                switch (self.retriesLeft) {
                    case 2:
                        retryDelay = _retryDelay * NSEC_PER_SEC;
                        break;
                    default:
                        retryDelay = 2 * NSEC_PER_SEC;
                        break;
                }
                self.retriesLeft--;
                if (self.retriesLeft <= 0) {
                    GrowingAsaFetcher.asaData = [GrowingAsaFetcher mapDictionaryForUpload:attributionDetails isIAd:isIAd];
                    GrowingAsaFetcher.status = GrowingAsaFetcherStatusFailure;
                    return;
                }
                dispatch_time_t retryTime = dispatch_time(DISPATCH_TIME_NOW, retryDelay);
                dispatch_after(retryTime, dispatch_get_main_queue(), ^{
                    [self fetchAttribution];
                });
                return;
            }
            case GrowingAsaFetcherErrorTimedOut:
            case GrowingAsaFetcherErrorTokenInvalid: {
                self.retriesLeft--;
                if (self.retriesLeft <= 0) {
                    GrowingAsaFetcher.asaData = [GrowingAsaFetcher mapDictionaryForUpload:attributionDetails isIAd:isIAd];
                    GrowingAsaFetcher.status = GrowingAsaFetcherStatusFailure;
                    return;
                }
                [self fetchAttribution];
            }
                return;
            case GrowingAsaFetcherErrorTrackingRestrictedOrDenied:
            case GrowingAsaFetcherErrorUnsupportedPlatform:
                GrowingAsaFetcher.status = GrowingAsaFetcherStatusDenied;
                return;
        }
    }
    
    GrowingAsaFetcher.asaData = [GrowingAsaFetcher mapDictionaryForUpload:attributionDetails isIAd:isIAd];
    GrowingAsaFetcher.status = GrowingAsaFetcherStatusSuccess;
}

+ (nullable NSDictionary *)mapDictionaryForUpload:(NSDictionary *)dic isIAd:(BOOL)isIAd {
    if (dic.allKeys.count == 0) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:dic];
    [result setObject:isIAd ? @"iad" : @"adss" forKey:@"src"];
    return result;
}

#pragma mark iAd.framework

- (void)fetchFromIAd {
    Class cls = NSClassFromString(@"ADClient");
    if (cls == nil) {
        GrowingAsaFetcher.status = GrowingAsaFetcherStatusDenied;
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL sel = NSSelectorFromString(@"sharedClient");
    if (![cls respondsToSelector:sel]) {
        GrowingAsaFetcher.status = GrowingAsaFetcherStatusDenied;
        return;
    }
    
    id instance = [cls performSelector:sel];
    if (instance == nil) {
        GrowingAsaFetcher.status = GrowingAsaFetcherStatusDenied;
        return;
    }
    
    SEL iAdDetailSelector = NSSelectorFromString(@"requestAttributionDetailsWithBlock:");
    if (![instance respondsToSelector:iAdDetailSelector]) {
        GrowingAsaFetcher.status = GrowingAsaFetcherStatusDenied;
        return;
    }
    
    
    __block Class lock = [GrowingAsaFetcher class];
    __block BOOL completed = NO;
    [instance performSelector:iAdDetailSelector withObject:^(NSDictionary *attributionDetails, NSError *error) {
        @synchronized (lock) {
            if (completed) {
                return;
            } else {
                completed = YES;
            }
        }
        [self saveAttributionDetails:attributionDetails isIAd:YES error:error];
    }];
    
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_eachRequestTimeOut * NSEC_PER_SEC));
    dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (lock) {
            if (completed) {
                return;
            } else {
                completed = YES;
            }
        }
        [self saveAttributionDetails:nil isIAd:YES error:[NSError errorWithDomain:kGrowingAsaFetcherErrorDomain
                                                                             code:GrowingAsaFetcherErrorTimedOut
                                                                         userInfo:@{NSLocalizedDescriptionKey: @"time is out"}]];
    });
#pragma clang diagnostic pop
}

#pragma mark AdServices.framework

- (void)fetchFromAdServices {
    Class cls = NSClassFromString(@"AAAttribution");
    if (cls == nil) {
        GrowingAsaFetcher.status = GrowingAsaFetcherStatusDenied;
        return;
    }
    
    SEL sel = NSSelectorFromString(@"attributionTokenWithError:");
    if (![cls respondsToSelector:sel]) {
        GrowingAsaFetcher.status = GrowingAsaFetcherStatusDenied;
        return;
    }
    
    NSMethodSignature *methodSignature = [cls methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:sel];
    [invocation setTarget:cls];
    __autoreleasing NSError *error;
    __autoreleasing NSError **errorPointer = &error;
    [invocation setArgument:&errorPointer atIndex:2];
    [invocation invoke];
    
    if (error) {
        GIOLogError(@"AsaFetcher error: request token error");
        switch (error.code) {
            case 1:
            case 2: {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"request token failed"};
                [self saveAttributionDetails:nil
                                       isIAd:NO
                                       error:[NSError errorWithDomain:kGrowingAsaFetcherErrorDomain
                                                                 code:GrowingAsaFetcherErrorTokenInvalid
                                                             userInfo:userInfo]];
            }
                return;
            case 3:
                GrowingAsaFetcher.status = GrowingAsaFetcherStatusDenied;
                return;
            default:
                GrowingAsaFetcher.status = GrowingAsaFetcherStatusDenied;
                return;
        }
    }
    
    NSString *__unsafe_unretained tmpToken = nil;
    [invocation getReturnValue:&tmpToken];
    NSString *token = tmpToken;
    GIOLogDebug(@"AsaFetcher request token succeed, token = %@", token);
    [self attributionWithToken:token];
}

- (void)attributionWithToken:(NSString *)token {
    self.token = token;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURL *url = [NSURL URLWithString:@"https://api-adservices.apple.com/api/v1/"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:_eachRequestTimeOut];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    NSData *postData = [token dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (error.code == NSURLErrorCancelled) {
                return;
            }
            GrowingAsaFetcherError code = error.code == NSURLErrorTimedOut ? GrowingAsaFetcherErrorTimedOut
                                                                           : GrowingAsaFetcherErrorRequestNetworkError;
            [self saveAttributionDetails:@{@"token" : token}
                                   isIAd:NO
                                   error:[NSError errorWithDomain:kGrowingAsaFetcherErrorDomain
                                                             code:code
                                                         userInfo:error.userInfo]];
            return;
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 200) {
                NSError *resError;
                NSDictionary *resDic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&resError];
                if (resError) {
                    [self saveAttributionDetails:@{@"token" : token}
                                           isIAd:NO
                                           error:[NSError errorWithDomain:kGrowingAsaFetcherErrorDomain
                                                                     code:GrowingAsaFetcherErrorCorruptResponse
                                                                 userInfo:resError.userInfo]];
                    return;
                }
                
                NSMutableDictionary *details = [NSMutableDictionary dictionaryWithDictionary:resDic];
                details[@"token"] = token;
                [self saveAttributionDetails:details isIAd:NO error:nil];
            } else if (statusCode == 400 || statusCode == 404) {
                
                self.token = nil;
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"The token is invalid"};
                [self saveAttributionDetails:nil
                                       isIAd:NO
                                       error:[NSError errorWithDomain:kGrowingAsaFetcherErrorDomain
                                                                 code:GrowingAsaFetcherErrorTokenInvalid
                                                             userInfo:userInfo]];
            } else {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey :
                                               @"The server is temporarily down or not reachable."
                                               @"The request may be valid, but you need to retry the request at a later point."};
                [self saveAttributionDetails:@{@"token" : token}
                                       isIAd:NO
                                       error:[NSError errorWithDomain:kGrowingAsaFetcherErrorDomain
                                                                 code:GrowingAsaFetcherErrorRequestNetworkError
                                                             userInfo:userInfo]];
            }
        }
    }];
    [task resume];
    self.task = task;
}

#pragma mark - Setter & Getter

+ (GrowingAsaFetcherStatus)status {
    pthread_rwlock_rdlock(&_lock);
    int status = ((NSNumber *)objc_getAssociatedObject(self, _cmd)).intValue;
    pthread_rwlock_unlock(&_lock);
    return status;
}

+ (void)setStatus:(GrowingAsaFetcherStatus)status {
    if (self.status == status) {
        return;
    }
    
    pthread_rwlock_wrlock(&_lock);
    objc_setAssociatedObject(self, @selector(status), @(status), OBJC_ASSOCIATION_ASSIGN);
    pthread_rwlock_unlock(&_lock);
    GIOLogDebug(@"AsaFetcher fetch status change to %@", [self statusDescription]);
}

+ (NSString *)statusDescription {
    switch (self.status) {
        case GrowingAsaFetcherStatusDenied:
            return @"denied";
            break;
        case GrowingAsaFetcherStatusFetching:
            return @"fetching";
            break;
        case GrowingAsaFetcherStatusSuccess:
            return @"success";
            break;
        case GrowingAsaFetcherStatusFailure:
            return @"failure";
            break;
        case GrowingAsaFetcherStatusCompleted:
            return @"completed";
            break;
        default:
            break;
    }
}

+ (NSDictionary *)asaData {
    return objc_getAssociatedObject(self, _cmd);
}

+ (void)setAsaData:(NSDictionary *)asaData {
    objc_setAssociatedObject(self, @selector(asaData), asaData, OBJC_ASSOCIATION_COPY_NONATOMIC);
    GIOLogDebug(@"AsaFetcher set ASA data = %@", asaData);
}

- (void)setRetriesLeft:(NSInteger)retriesLeft {
    _retriesLeft = retriesLeft;
    GIOLogDebug(@"AsaFetcher retry left %ld", (long)_retriesLeft);
}

@end
