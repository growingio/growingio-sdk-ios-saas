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


#import "GrowingBaseModel.h"
#import "GrowingInstance.h"
#import "NSDictionary+GrowingHelper.h"
#import "NSArray+GrowingHelper.h"
#import "NSData+GrowingHelper.h"
#import "GrowingCocoaLumberjack.h"
#import "GrowingNetworkPreflight.h"

static NSMutableArray<NSMutableDictionary*> *allTypeInstance = nil;
static NSMutableDictionary *allAccountIdDict = nil;

@interface GrowingBaseModel()<NSURLSessionDelegate>
{
    NSOperationQueue *_queue;
}

@property (nonatomic, retain)  NSMutableURLRequest *request;

@end

@implementation GrowingBaseModel

- (NSOperationQueue*)modelOperationQueue
{
    if (!_queue)
    {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

+ (instancetype)shareInstanceWithType:(GrowingModelType)type
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allTypeInstance = [[NSMutableArray alloc] initWithCapacity:GrowingModelTypeCount];
        for (NSUInteger i = 0 ; i < GrowingModelTypeCount ; i ++)
        {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [allTypeInstance addObject:dict];
        }
    });
    
    NSMutableDictionary *dict = allTypeInstance[type];
    GrowingBaseModel *obj = nil;
    @synchronized (dict) {
        obj = [dict valueForKey:NSStringFromClass(self)];
        if (!obj)
        {
            obj = [[self alloc] init];
            obj ->_modelType = type;
            [dict setValue:obj forKey:NSStringFromClass(self)];
        }
    }
    return obj;
}

+ (instancetype)sdkInstance
{
    return [self shareInstanceWithType:GrowingModelTypeSDKCircle];
}

+ (instancetype)eventInstance
{
    return [self shareInstanceWithType:GrowingModelTypeEvent];
}

- (void)authorityVerification:(NSMutableURLRequest *)request
{
    
}

- (BOOL)authorityErrorHandle:(void(^)(BOOL flag))finishBlock
{
    finishBlock = nil;
    return NO;
}

- (void)startTaskWithURL:(NSString *)url
              httpMethod:(NSString *)httpMethod
              parameters:(id)parameters 
                 success:(GROWNetworkSuccessBlock)success
                 failure:(GROWNetworkFailureBlock)failure
{
    [self startTaskWithURL:url
                httpMethod:httpMethod
                parameters:parameters
              outsizeBlock:nil
             configRequest:nil
            isSendingEvent:NO
                       STM:0
          timeoutInSeconds:0
             isFromHTTPDNS:NO
                   success:success
                   failure:failure];
}

- (void)startTaskWithURL:(NSString *)url
              httpMethod:(NSString *)httpMethod
              parameters:(id)parameters 
        timeoutInSeconds:(NSUInteger)timeout
                 success:(GROWNetworkSuccessBlock)success
                 failure:(GROWNetworkFailureBlock)failure
{
    [self startTaskWithURL:url
                httpMethod:httpMethod
                parameters:parameters
              outsizeBlock:nil
             configRequest:nil
            isSendingEvent:NO
                       STM:0
          timeoutInSeconds:timeout
             isFromHTTPDNS:NO
                   success:success
                   failure:failure];
}

- (void)startTaskWithURL:(NSString *)url
              httpMethod:(NSString *)httpMethod
              parameters:(id)parameters 
            outsizeBlock:(void (^)(unsigned long long))outsizeBlock
           configRequest:(void (^)(NSMutableURLRequest *))configRequest
          isSendingEvent:(BOOL)isSendingEvent
                     STM:(unsigned long long int)STM
        timeoutInSeconds:(NSUInteger)timeout
           isFromHTTPDNS:(BOOL)isFromHTTPDNS
                 success:(GROWNetworkSuccessBlock)success
                 failure:(GROWNetworkFailureBlock)failure
{
    NSURL *u = [NSURL URLWithString:url];
    self.request = [[NSMutableURLRequest alloc] initWithURL:u];
    [self.request setHTTPMethod:httpMethod];
    if (timeout > 0)
    {
        self.request.timeoutInterval = (NSTimeInterval)timeout;
    }

    if (configRequest != nil)
    {
        configRequest(self.request);
    }

    [self authorityVerification:self.request];
    
    if (self.modelType == GrowingModelTypeOptions) {
        [self.request setValue:@"POST" forHTTPHeaderField:@"Access-Control-Request-Method"];
        [self.request setValue:@"Accept, Content-Type, X-Timestamp, X-Crypt-Codec, X-Compress-Codec"
            forHTTPHeaderField:@"Access-Control-Request-Headers"];
        NSString *origin = [NSString stringWithFormat:@"%@://%@", u.scheme, u.host];
        [self.request setValue:origin forHTTPHeaderField:@"Origin"];
    } else {
        [self.request addValue:[GROWGetTimestamp() stringValue] forHTTPHeaderField:@"X-Timestamp"];
        [self.request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        NSData *JSONData = nil;
        if (parameters)
        {
            JSONData = [parameters growingHelper_jsonData];
        }

        if (isSendingEvent)
        {
            JSONData = [JSONData growingHelper_LZ4String];

            JSONData = [JSONData growingHelper_xorEncryptWithHint:(STM & 0xFF)];
            [self.request addValue:@"3" forHTTPHeaderField:@"X-Compress-Codec"]; 
            [self.request addValue:@"1" forHTTPHeaderField:@"X-Crypt-Codec"]; 
            [self.request addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];

        }
        else if (JSONData.length > 0)
        {
            [self.request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        }

        [self.request setHTTPBody:JSONData];
        
        if (outsizeBlock)
        {
            outsizeBlock(JSONData.length);
        }
    }    
    
    if (!success) success = ^( NSHTTPURLResponse *httpResponse , NSData *data ){};
    if (!failure) failure = ^( NSHTTPURLResponse *httpResponse , NSData *data, NSError *error ){};
    
    NSURLSession *session;
    
    
    if (!isFromHTTPDNS)
    {
        session = [NSURLSession sharedSession];
    }
    else
    {
        [self.request addValue:[GrowingNetworkConfig.sharedInstance growingApiHost] forHTTPHeaderField:@"host"];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:configuration
                                                delegate:self
                                                     delegateQueue:self.modelOperationQueue];
    }
    
    NSURLSessionTask *task = [session dataTaskWithRequest:self.request
                                        completionHandler:^(NSData * _Nullable data,
                                                            NSURLResponse * _Nullable _response,
                                                            NSError * _Nullable connectionError) {
                               NSHTTPURLResponse *response = (id)_response;
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (connectionError) {
                                       GIOLogError(@"Request(%p) failed with connection error: %@", self.request, connectionError);
                                       failure(response,data,connectionError);
                                       return;
                                   }
                                   
                                   if (self.modelType == GrowingModelTypeOptions) {
                                       if (response.statusCode >= 200 && response.statusCode < 400) {
                                           success(response, data);
                                       } else {
                                           failure(response,data,connectionError);
                                       }
                                       return;
                                   }
                                   
                                   if (self.modelType != GrowingModelTypeEvent
                                       && response.statusCode == 403)
                                   {
                                       BOOL shouldReturn = [self authorityErrorHandle:^(BOOL flag) {
                                           if (flag) {
                                               [self startTaskWithURL:url
                                                           httpMethod:httpMethod
                                                           parameters:parameters
                                                         outsizeBlock:outsizeBlock
                                                        configRequest:configRequest
                                                       isSendingEvent:isSendingEvent
                                                                  STM:STM
                                                     timeoutInSeconds:timeout
                                                        isFromHTTPDNS:isFromHTTPDNS
                                                              success:success
                                                              failure:failure];
                                           } else {
                                               if (failure) {
                                                   failure(response,data,connectionError);
                                               }
                                           }
                                       }];
                                       
                                       if (shouldReturn) {
                                           return;
                                       }
                                   }
                                   
                                   if (self.modelType == GrowingModelTypeEvent) {
                                       if (response.statusCode == 413) {
                                           success(response, data);
                                           return;
                                       } else if (response.statusCode == 403) {
                                           failure(response,data,connectionError);
                                           [GrowingNetworkPreflight sendPreflight];
                                           return;
                                       }
                                   }
                                   
                                   if (response.statusCode != 200) {
                                       GIOLogError(@"Request(%p) failed with unexpected status code: %ld.", self.request, response.statusCode);
                                       failure(response,data,connectionError);
                                       return;
                                   }
                                   
                                   GIOLogDebug(@"Request(%p) succeeded: %ld.", self.request, response.statusCode);
                                   success(response, data);
                               });
                           }];
    GIOLogDebug(@"Request(%p) has been sent.", self.request);
    
    [task resume];
}



- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    if (!challenge) {
        return;
    }
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    
    NSString* host = [[self.request allHTTPHeaderFields] objectForKey:@"host"];
    if (!host) {
        host = self.request.URL.host;
    }
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([self evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:host]) {
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    
    completionHandler(disposition,credential);
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain
{
    
    NSMutableArray *policies = [NSMutableArray array];
    if (domain) {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    } else {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }
    
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
    
    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    return (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);

}

@end
