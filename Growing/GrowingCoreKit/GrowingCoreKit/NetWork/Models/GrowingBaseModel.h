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


#import <Foundation/Foundation.h>

#import "GrowingNetworkConfig.h"

typedef void ( ^GROWNetworkSuccessBlock ) ( NSHTTPURLResponse *httpResponse , NSData *data);
typedef void ( ^GROWNetworkFailureBlock ) ( NSHTTPURLResponse *httpResponse , NSData *data, NSError *error );

typedef NS_ENUM(NSUInteger,GrowingModelType)
{
    GrowingModelTypeEvent,
    GrowingModelTypeSDKCircle,
    GrowingModelTypeOptions,
    GrowingModelTypeCount,
};

@interface GrowingBaseModel : NSObject

+ (instancetype)sdkInstance;
+ (instancetype)eventInstance;
+ (instancetype)shareInstanceWithType:(GrowingModelType)type;

@property (nonatomic, readonly) GrowingModelType modelType;

- (void)authorityVerification:(NSMutableURLRequest *)request;


- (BOOL)authorityErrorHandle:(void(^)(BOOL flag))finishBlock;

- (NSOperationQueue*)modelOperationQueue;

- (void)startTaskWithURL:(NSString *)url
              httpMethod:(NSString*)httpMethod
              parameters:(id)parameters 
                 success:(GROWNetworkSuccessBlock)success
                 failure:(GROWNetworkFailureBlock)failure;

- (void)startTaskWithURL:(NSString *)url
              httpMethod:(NSString*)httpMethod
              parameters:(id)parameters 
        timeoutInSeconds:(NSUInteger)timeout
                 success:(GROWNetworkSuccessBlock)success
                 failure:(GROWNetworkFailureBlock)failure;

- (void)startTaskWithURL:(NSString *)url
              httpMethod:(NSString*)httpMethod
              parameters:(id)parameters 
            outsizeBlock:(void (^)(unsigned long long))outsizeBlock
           configRequest:(void(^)(NSMutableURLRequest* request))configRequest
          isSendingEvent:(BOOL)isSendingEvent
                     STM:(unsigned long long int)STM
        timeoutInSeconds:(NSUInteger)timeout
           isFromHTTPDNS:(BOOL)isFromHTTPDNS
                 success:(GROWNetworkSuccessBlock)success
                 failure:(GROWNetworkFailureBlock)failure;

@end
