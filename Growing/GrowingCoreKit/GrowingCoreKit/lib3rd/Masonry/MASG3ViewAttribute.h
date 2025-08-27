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


#import "MASG3Utilities.h"


@interface MASG3ViewAttribute : NSObject


@property (nonatomic, weak, readonly) MASG3_VIEW *view;


@property (nonatomic, weak, readonly) id item;


@property (nonatomic, assign, readonly) NSLayoutAttribute layoutAttribute;


- (id)initWithView:(MASG3_VIEW *)view layoutAttribute:(NSLayoutAttribute)layoutAttribute;


- (id)initWithView:(MASG3_VIEW *)view item:(id)item layoutAttribute:(NSLayoutAttribute)layoutAttribute;


- (BOOL)isSizeAttribute;

@end
