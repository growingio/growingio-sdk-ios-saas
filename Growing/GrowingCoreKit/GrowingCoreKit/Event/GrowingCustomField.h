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

@interface GrowingCustomField : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, copy) NSString * cs1; 

@property (nonatomic, retain) NSDictionary<NSString *, NSObject *> * growingVistorVar;

- (void)sendEvarEvent:(NSDictionary<NSString *, NSObject *> *)evar;
- (void)sendPeopleEvent:(NSDictionary<NSString *, NSObject *> *)peopleVar;
- (void)sendCustomTrackEventWithName:(NSString *)eventName andNumber:(NSNumber *)number andVariable:(NSDictionary<NSString *, NSObject *> *)variable;
- (void)sendVisitorEvent:(NSDictionary<NSString *, NSObject *> *)variable;
- (BOOL)isOnlyCoreKit;
- (void)sendGIOFakePageEvent;

@end
