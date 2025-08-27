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
#import "MASG3ConstraintMaker.h"
#import "MASG3ViewAttribute.h"

typedef NS_ENUM(NSUInteger, MASG3AxisType) {
    MASG3AxisTypeHorizontal,
    MASG3AxisTypeVertical
};

@interface NSArray (MASG3Additions)


- (NSArray *)masG3_makeConstraints:(void (^)(MASG3ConstraintMaker *make))block;


- (NSArray *)masG3_updateConstraints:(void (^)(MASG3ConstraintMaker *make))block;


- (NSArray *)masG3_remakeConstraints:(void (^)(MASG3ConstraintMaker *make))block;


- (void)masG3_distributeViewsAlongAxis:(MASG3AxisType)axisType withFixedSpacing:(CGFloat)fixedSpacing leadSpacing:(CGFloat)leadSpacing tailSpacing:(CGFloat)tailSpacing;


- (void)masG3_distributeViewsAlongAxis:(MASG3AxisType)axisType withFixedItemLength:(CGFloat)fixedItemLength leadSpacing:(CGFloat)leadSpacing tailSpacing:(CGFloat)tailSpacing;

@end
