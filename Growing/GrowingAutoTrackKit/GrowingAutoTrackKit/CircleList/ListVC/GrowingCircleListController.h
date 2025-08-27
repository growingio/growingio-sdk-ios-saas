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


#import <UIKit/UIKit.h>
#import "GrowingEventListItem.h"
#import "GrowingCircleListBaseViewController.h"

@interface GrowingCircleListController : GrowingCircleListBaseViewController

- (instancetype)initWithItems:(NSArray<GrowingEventListItem*>*)items;

@property (nonatomic, copy) void(^onCloseClick)(void);


+ (void)showEventType:(GrowingEventType)eventType;
+ (void)hideEventType:(GrowingEventType)eventType;
+ (BOOL)isEventShow:(GrowingEventType)eventType;

@end
