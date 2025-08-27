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
#import "GrowingEvent.h"



@interface GrowingEvarEvent : GrowingCustomRootEvent

+ (void)sendEvarEvent:(NSDictionary<NSString *, NSObject *> * _Nonnull)evar;

@end

@interface GrowingCustomTrackEvent : GrowingCustomRootEvent

- (instancetype _Nullable )initWithEventName:(NSString *_Nullable)eventName withNumber:(NSNumber *_Nullable)number withVariable:(NSDictionary<NSString *, NSObject *> *_Nullable)variable;

+ (void)sendEventWithName:(NSString * _Nonnull)eventName
                andNumber:(NSNumber * _Nullable)number
              andVariable:(NSDictionary<NSString *, NSObject *> * _Nonnull)variable;

@end

@interface GrowingPeopleVarEvent : GrowingCustomRootEvent

+ (void)sendEventWithVariable:(NSDictionary<NSString *, NSObject *> * _Nonnull)variable;

@end



@interface GrowingVisitorEvent : GrowingCustomRootEvent

- (instancetype _Nullable )initWithVisitorVariable:(NSDictionary<NSString *, NSObject *> *_Nullable)variable;

+ (void)sendVisitorEvent:(NSDictionary<NSString *, NSObject *> * _Nonnull)variable;

@end
