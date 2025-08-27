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
#import "GrowingWindow.h"
#import "GrowingNode.h"
#import "GROMagnifierView.h"

@interface GrowingLocalCircleWindow : GrowingWindowView

+ (void)startCircle;
+ (void)stopCircle;
+ (BOOL)hasStartCircle;

+ (void)circlePage;
+ (void)circleH5Pages:(NSArray<NSDictionary *> *)pageDictArray;


+ (void)increaseHiddenCount;
+ (void)decreaseHiddenCount;

@end
