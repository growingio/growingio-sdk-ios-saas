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
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>


typedef enum : NSInteger {
	GrowingNotReachable = 0,
	GrowingReachableViaWiFi,
	GrowingReachableViaWWAN,
	GrowingUnknown,
} GrowingNetworkStatus;

#pragma mark IPv6 Support



extern NSString *kGrowingReachabilityChangedNotification;


@interface GrowingReachability : NSObject


+ (instancetype)reachabilityWithHostName:(NSString *)hostName;


+ (instancetype)reachabilityWithAddress:(const struct sockaddr *)hostAddress;


+ (instancetype)reachabilityForInternetConnection;


#pragma mark reachabilityForLocalWiFi




- (BOOL)startNotifier;
- (void)stopNotifier;

- (GrowingNetworkStatus)currentReachabilityStatus;


- (BOOL)connectionRequired;

@end
