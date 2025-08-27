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


#import "GrowingEventModel.h"
#import "GrowingUserDefaults.h"

#define TTL_24_HOUR_IN_SECONDS (24 * 60 * 60)
#define IPEXPIRETIME_KEY @"HTTPDNS_IPExpireTime"
#define IPFROMHTTPDNS_KEY @"HTTPDNS_IPFROMHTTPDNS"

@interface GrowingEventModel() <NSURLSessionTaskDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, copy)   NSString *IPFromHTTPDNS;
@property (nonatomic, strong) NSDate *IPExpireTime;

@end

@implementation GrowingEventModel

@synthesize IPFromHTTPDNS = _IPFromHTTPDNS;
@synthesize IPExpireTime = _IPExpireTime;

- (NSString*)IPFromHTTPDNS
{
    NSString* result = nil;
    if ([self isIPFromHTTPDNSValid]) {
        if(!_IPFromHTTPDNS) {
            _IPFromHTTPDNS = [[GrowingUserDefaults shareInstance] valueForKey:IPFROMHTTPDNS_KEY];
        }
        result = _IPFromHTTPDNS;
    }
    return result;
}

- (void)setIPFromHTTPDNS:(NSString *)IPFromHTTPDNS
{
    _IPFromHTTPDNS = IPFromHTTPDNS;
    [[GrowingUserDefaults shareInstance] setValue:IPFromHTTPDNS forKey:IPFROMHTTPDNS_KEY];
}

- (NSDate*)IPExpireTime
{
    if(!_IPExpireTime) {
        NSString* IPExpireTimeInterval = [[GrowingUserDefaults shareInstance] valueForKey:IPEXPIRETIME_KEY];
        if (IPExpireTimeInterval) {
            _IPExpireTime = [NSDate dateWithTimeIntervalSince1970: IPExpireTimeInterval.doubleValue];
        }
    }
    return _IPExpireTime;
}
- (void)setIPExpireTime:(NSDate *)IPExpireTime
{
    _IPExpireTime = IPExpireTime;
    [[GrowingUserDefaults shareInstance] setValue:@([IPExpireTime timeIntervalSince1970]).stringValue forKey:IPEXPIRETIME_KEY];
}

- (BOOL)isIPFromHTTPDNSValid
{
    return self.IPExpireTime && ([[NSDate date] timeIntervalSinceDate:self.IPExpireTime] < 0);
}

- (instancetype)init
{
    if (self = [super init]) {
        self.modelOperationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}


- (void)uploadEvents:(id)data 
         toURLString:(NSString *)urlString
      diagnoseEnable:(BOOL)diagnoseEnable
              withAI:(NSString *)ai
              andSTM:(unsigned long long)stm
             outsizeBlock:(void (^)(unsigned long long))outsizeBlock
             succeed:(void (^)(void))succeed
                fail:(void (^)(NSError *))fail
{
    [self tryUploadEvents:data
         isThroughHTTPDNS: ([self isIPFromHTTPDNSValid])
            toURLString:(NSString *)urlString
           diagnoseEnable:diagnoseEnable
                   withAI:ai
                   andSTM:stm
             outsizeBlock:outsizeBlock
                  succeed:succeed
                     fail:fail];
}

- (void)tryUploadEvents:(id)data 
       isThroughHTTPDNS: (BOOL)isThroughHTTPDNS
       toURLString:(NSString *)urlString
      diagnoseEnable:(BOOL)diagnoseEnable
              withAI:(NSString *)ai
              andSTM:(unsigned long long)stm
        outsizeBlock:(void (^)(unsigned long long))outsizeBlock
             succeed:(void (^)(void))succeed
                fail:(void (^)(NSError *))fail
{
    NSString *hostString = [NSURL URLWithString: urlString].host;
    if (isThroughHTTPDNS && ![self isIPFromHTTPDNSValid]) {
        BOOL isExistPendingRequestIPFromHTTPDNS = [self asyncRequestIPFromHTTPDNSForHost:hostString completionHandler:^(BOOL isRequestSuccessfully){
            if (isRequestSuccessfully) {
                [self tryUploadEvents:data
                     isThroughHTTPDNS: YES
                        toURLString:(NSString *)urlString
                       diagnoseEnable:diagnoseEnable
                               withAI:ai
                               andSTM:stm
                         outsizeBlock:outsizeBlock
                              succeed:succeed
                                 fail:fail];
            }
            else
            {
                fail(nil);
            }
        }];
        
        
        
        if (!isExistPendingRequestIPFromHTTPDNS) {
            fail(nil);
        }
    }
    else
    {
        NSString *taskURL = urlString;
        BOOL isFromHTTPDNS = NO;
        if (isThroughHTTPDNS && self.IPFromHTTPDNS)
        {
            
            NSRange hostRange = [urlString rangeOfString: hostString];
            taskURL = [urlString stringByReplacingCharactersInRange:hostRange
                                                                 withString:self.IPFromHTTPDNS];
            isFromHTTPDNS = YES;
        }
        [self startTaskWithURL:taskURL
                    httpMethod:@"POST"
                    parameters:data
                  outsizeBlock:outsizeBlock
                 configRequest:(diagnoseEnable
                                ? ^void(NSMutableURLRequest * urlRequest){
                                    [urlRequest setValue:ai forHTTPHeaderField:@"X-GrowingIO-UID"];
                                }
                                : nil)
                isSendingEvent:YES
                           STM:stm
              timeoutInSeconds:0
                 isFromHTTPDNS:isFromHTTPDNS
                       success:^(NSHTTPURLResponse *httpResponse, NSData *data) {
                           succeed();
                       }
                       failure:^(NSHTTPURLResponse *httpResponse, NSData *error_data, NSError *error) {
                           
                           
                           
                           if (isThroughHTTPDNS && [self isIPFromHTTPDNSValid]) {
                               self.IPExpireTime = nil;
                           }
                           
                           
                           
                           
                           if (error.code == NSURLErrorCannotFindHost &&
                               [hostString isEqualToString:[GrowingNetworkConfig.sharedInstance growingApiHost]])
                           {
                            #pragma clang diagnostic push
                            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                               dispatch_async(dispatch_get_current_queue(), ^ {
                            #pragma clang diagnostic pop
                                   [self tryUploadEvents:data
                                        isThroughHTTPDNS: YES
                                             toURLString:urlString
                                          diagnoseEnable:diagnoseEnable
                                                  withAI:ai
                                                  andSTM:stm
                                            outsizeBlock:outsizeBlock
                                                 succeed:succeed
                                                    fail:fail];
                               });
                               
                           }
                           else
                           {
                               fail(error);
                           }
                       }];
        
    }
}



- (BOOL) asyncRequestIPFromHTTPDNSForHost: (NSString *)host completionHandler: (void (^)(BOOL))completionHandler
{
    static BOOL isRequestingIPFromHTTPDNS = NO;
    static BOOL isRequestSuccessfully = NO;
    
    if (isRequestingIPFromHTTPDNS) {
        return NO;
    }
    
    isRequestingIPFromHTTPDNS = YES;
    
    NSString *urlString = [@"https://203.107.1.1/144428/d?host=" stringByAppendingString:host];
        
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:urlString]];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:self.modelOperationQueue];
    
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        isRequestSuccessfully = error == nil;
        
        if (isRequestSuccessfully) {
            NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                           options: NSJSONReadingMutableLeaves
                                                                             error:nil];
            NSArray *IPs = jsonDictionary[@"ips"] ;
            
            self.IPFromHTTPDNS = IPs.firstObject;
            
            self.IPExpireTime = [NSDate dateWithTimeIntervalSinceNow: TTL_24_HOUR_IN_SECONDS];
        }
        
        completionHandler(isRequestSuccessfully);
        isRequestingIPFromHTTPDNS = NO;
    }];
    [task resume];
    return YES;
}


@end
