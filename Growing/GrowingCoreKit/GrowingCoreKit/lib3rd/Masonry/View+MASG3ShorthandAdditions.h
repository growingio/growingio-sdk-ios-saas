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


#import "View+MASG3Additions.h"

#ifdef MASG3_SHORTHAND


@interface MASG3_VIEW (MASG3ShorthandAdditions)

@property (nonatomic, strong, readonly) MASG3ViewAttribute *left;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *top;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *right;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *bottom;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *leading;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *trailing;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *width;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *height;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *centerX;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *centerY;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *baseline;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *(^attribute)(NSLayoutAttribute attr);

#if TARGET_OS_IPHONE

@property (nonatomic, strong, readonly) MASG3ViewAttribute *leftMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *rightMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *topMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *bottomMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *leadingMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *trailingMargin;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *centerXWithinMargins;
@property (nonatomic, strong, readonly) MASG3ViewAttribute *centerYWithinMargins;

#endif

- (NSArray *)makeConstraints:(void(^)(MASG3ConstraintMaker *make))block;
- (NSArray *)updateConstraints:(void(^)(MASG3ConstraintMaker *make))block;
- (NSArray *)remakeConstraints:(void(^)(MASG3ConstraintMaker *make))block;

@end

#define MASG3_ATTR_FORWARD(attr)  \
- (MASG3ViewAttribute *)attr {    \
    return [self masG3_##attr];   \
}

@implementation MASG3_VIEW (MASG3ShorthandAdditions)

MASG3_ATTR_FORWARD(top);
MASG3_ATTR_FORWARD(left);
MASG3_ATTR_FORWARD(bottom);
MASG3_ATTR_FORWARD(right);
MASG3_ATTR_FORWARD(leading);
MASG3_ATTR_FORWARD(trailing);
MASG3_ATTR_FORWARD(width);
MASG3_ATTR_FORWARD(height);
MASG3_ATTR_FORWARD(centerX);
MASG3_ATTR_FORWARD(centerY);
MASG3_ATTR_FORWARD(baseline);

#if TARGET_OS_IPHONE

MASG3_ATTR_FORWARD(leftMargin);
MASG3_ATTR_FORWARD(rightMargin);
MASG3_ATTR_FORWARD(topMargin);
MASG3_ATTR_FORWARD(bottomMargin);
MASG3_ATTR_FORWARD(leadingMargin);
MASG3_ATTR_FORWARD(trailingMargin);
MASG3_ATTR_FORWARD(centerXWithinMargins);
MASG3_ATTR_FORWARD(centerYWithinMargins);

#endif

- (MASG3ViewAttribute *(^)(NSLayoutAttribute))attribute {
    return [self masG3_attribute];
}

- (NSArray *)makeConstraints:(void(^)(MASG3ConstraintMaker *))block {
    return [self masG3_makeConstraints:block];
}

- (NSArray *)updateConstraints:(void(^)(MASG3ConstraintMaker *))block {
    return [self masG3_updateConstraints:block];
}

- (NSArray *)remakeConstraints:(void(^)(MASG3ConstraintMaker *))block {
    return [self masG3_remakeConstraints:block];
}

@end

#endif
