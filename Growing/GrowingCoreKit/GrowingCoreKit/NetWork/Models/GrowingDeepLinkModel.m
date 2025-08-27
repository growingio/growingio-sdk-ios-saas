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


#import "GrowingDeepLinkModel.h"
#import "GrowingInstance.h"
#import "GrowingDeviceInfo.h"

static NSString *const temporaryHost = @"https://t.growingio.com";

@implementation GrowingDeepLinkModel

- (void)getParamByHashId:(NSString *)hashId
                   query:(NSString *)query
                      ua:(NSString *)ua
                  manual:(BOOL)manual
                 succeed:(GROWNetworkSuccessBlock)succeedBlock
                    fail:(GROWNetworkFailureBlock)failBlock
{
    [self startTaskWithURL:[NSString stringWithFormat:@"%@/app/at6/%@/ios/%@/%@/%@%@", temporaryHost, manual ? @"inapp" : @"defer", [GrowingInstance sharedInstance].accountID, [GrowingDeviceInfo currentDeviceInfo].bundleID, hashId, query.length ? [NSString stringWithFormat:@"?%@", query] : @""]
                httpMethod:@"GET"
                parameters:nil
              outsizeBlock:nil
             configRequest:^(NSMutableURLRequest *request) {
        
        [request setValue:ua forHTTPHeaderField:@"User-Agent"];
    }
            isSendingEvent:NO
                       STM:0
          timeoutInSeconds:15
             isFromHTTPDNS:NO
                   success:succeedBlock
                   failure:failBlock];
}

@end
