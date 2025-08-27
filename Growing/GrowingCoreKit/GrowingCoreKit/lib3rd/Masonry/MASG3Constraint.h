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


@interface MASG3Constraint : NSObject




- (MASG3Constraint * (^)(MASG3EdgeInsets insets))insets;


- (MASG3Constraint * (^)(CGSize offset))sizeOffset;


- (MASG3Constraint * (^)(CGPoint offset))centerOffset;


- (MASG3Constraint * (^)(CGFloat offset))offset;


- (MASG3Constraint * (^)(NSValue *value))valueOffset;


- (MASG3Constraint * (^)(CGFloat multiplier))multipliedBy;


- (MASG3Constraint * (^)(CGFloat divider))dividedBy;


- (MASG3Constraint * (^)(MASG3LayoutPriority priority))priority;


- (MASG3Constraint * (^)(void))priorityLow;


- (MASG3Constraint * (^)(void))priorityMedium;


- (MASG3Constraint * (^)(void))priorityHigh;


- (MASG3Constraint * (^)(id attr))equalTo;


- (MASG3Constraint * (^)(id attr))greaterThanOrEqualTo;


- (MASG3Constraint * (^)(id attr))lessThanOrEqualTo;


- (MASG3Constraint *)with;


- (MASG3Constraint *)and;


- (MASG3Constraint *)left;
- (MASG3Constraint *)top;
- (MASG3Constraint *)right;
- (MASG3Constraint *)bottom;
- (MASG3Constraint *)leading;
- (MASG3Constraint *)trailing;
- (MASG3Constraint *)width;
- (MASG3Constraint *)height;
- (MASG3Constraint *)centerX;
- (MASG3Constraint *)centerY;
- (MASG3Constraint *)baseline;

#if TARGET_OS_IPHONE

- (MASG3Constraint *)leftMargin;
- (MASG3Constraint *)rightMargin;
- (MASG3Constraint *)topMargin;
- (MASG3Constraint *)bottomMargin;
- (MASG3Constraint *)leadingMargin;
- (MASG3Constraint *)trailingMargin;
- (MASG3Constraint *)centerXWithinMargins;
- (MASG3Constraint *)centerYWithinMargins;

#endif



- (MASG3Constraint * (^)(id key))key;





- (void)setInsets:(MASG3EdgeInsets)insets;


- (void)setSizeOffset:(CGSize)sizeOffset;


- (void)setCenterOffset:(CGPoint)centerOffset;


- (void)setOffset:(CGFloat)offset;




#if TARGET_OS_MAC && !TARGET_OS_IPHONE

@property (nonatomic, copy, readonly) MASG3Constraint *animator;
#endif


- (void)activate;


- (void)deactivate;


- (void)install;


- (void)uninstall;

@end



#define masG3_equalTo(...)                 equalTo(MASG3BoxValue((__VA_ARGS__)))
#define masG3_greaterThanOrEqualTo(...)    greaterThanOrEqualTo(MASG3BoxValue((__VA_ARGS__)))
#define masG3_lessThanOrEqualTo(...)       lessThanOrEqualTo(MASG3BoxValue((__VA_ARGS__)))

#define masG3_offset(...)                  valueOffset(MASG3BoxValue((__VA_ARGS__)))


#ifdef MASG3_SHORTHAND_GLOBALS

#define equalTo(...)                     masG3_equalTo(__VA_ARGS__)
#define greaterThanOrEqualTo(...)        masG3_greaterThanOrEqualTo(__VA_ARGS__)
#define lessThanOrEqualTo(...)           masG3_lessThanOrEqualTo(__VA_ARGS__)

#define offset(...)                      masG3_offset(__VA_ARGS__)

#endif


@interface MASG3Constraint (AutoboxingSupport)


- (MASG3Constraint * (^)(id attr))masG3_equalTo;
- (MASG3Constraint * (^)(id attr))masG3_greaterThanOrEqualTo;
- (MASG3Constraint * (^)(id attr))masG3_lessThanOrEqualTo;


- (MASG3Constraint * (^)(id offset))masG3_offset;

@end
