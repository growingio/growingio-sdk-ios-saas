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


@interface MASG3_VIEW (MASG3Additions)


@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_left;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_top;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_right;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_bottom;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_leading;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_trailing;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_width;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_height;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_centerX;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_centerY;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_baseline;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *(^masG3_attribute)(NSLayoutAttribute attr);

#if TARGET_OS_IPHONE

@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_leftMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_rightMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_topMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_bottomMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_leadingMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_trailingMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_centerXWithinMargins;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *masG3_centerYWithinMargins;

#endif


@property (nonatomic, strong) id masG3_key;


- (instancetype)masG3_closestCommonSuperview:(MASG3_VIEW *)view;


- (NSArray *)masG3_makeConstraints:(void(^)(MASG3ConstraintMaker *make))block;


- (NSArray *)masG3_updateConstraints:(void(^)(MASG3ConstraintMaker *make))block;


- (NSArray *)masG3_remakeConstraints:(void(^)(MASG3ConstraintMaker *make))block;

@end
