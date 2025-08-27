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


#import "MASG3Constraint.h"
#import "MASG3Utilities.h"

typedef NS_OPTIONS(NSInteger, MASG3Attribute) {
    MASG3AttributeLeft = 1 << NSLayoutAttributeLeft,
    MASG3AttributeRight = 1 << NSLayoutAttributeRight,
    MASG3AttributeTop = 1 << NSLayoutAttributeTop,
    MASG3AttributeBottom = 1 << NSLayoutAttributeBottom,
    MASG3AttributeLeading = 1 << NSLayoutAttributeLeading,
    MASG3AttributeTrailing = 1 << NSLayoutAttributeTrailing,
    MASG3AttributeWidth = 1 << NSLayoutAttributeWidth,
    MASG3AttributeHeight = 1 << NSLayoutAttributeHeight,
    MASG3AttributeCenterX = 1 << NSLayoutAttributeCenterX,
    MASG3AttributeCenterY = 1 << NSLayoutAttributeCenterY,
    MASG3AttributeBaseline = 1 << NSLayoutAttributeBaseline,
    
#if TARGET_OS_IPHONE
    
    MASG3AttributeLeftMargin = 1 << NSLayoutAttributeLeftMargin,
    MASG3AttributeRightMargin = 1 << NSLayoutAttributeRightMargin,
    MASG3AttributeTopMargin = 1 << NSLayoutAttributeTopMargin,
    MASG3AttributeBottomMargin = 1 << NSLayoutAttributeBottomMargin,
    MASG3AttributeLeadingMargin = 1 << NSLayoutAttributeLeadingMargin,
    MASG3AttributeTrailingMargin = 1 << NSLayoutAttributeTrailingMargin,
    MASG3AttributeCenterXWithinMargins = 1 << NSLayoutAttributeCenterXWithinMargins,
    MASG3AttributeCenterYWithinMargins = 1 << NSLayoutAttributeCenterYWithinMargins,

#endif
    
};


@interface MASG3ConstraintMaker : NSObject


@property (nonatomic, strong, readonly) MASG3Constraint *left;
@property (nonatomic, strong, readonly) MASG3Constraint *top;
@property (nonatomic, strong, readonly) MASG3Constraint *right;
@property (nonatomic, strong, readonly) MASG3Constraint *bottom;
@property (nonatomic, strong, readonly) MASG3Constraint *leading;
@property (nonatomic, strong, readonly) MASG3Constraint *trailing;
@property (nonatomic, strong, readonly) MASG3Constraint *width;
@property (nonatomic, strong, readonly) MASG3Constraint *height;
@property (nonatomic, strong, readonly) MASG3Constraint *centerX;
@property (nonatomic, strong, readonly) MASG3Constraint *centerY;
@property (nonatomic, strong, readonly) MASG3Constraint *baseline;

#if TARGET_OS_IPHONE

@property (nonatomic, strong, readonly) MASG3Constraint *leftMargin;
@property (nonatomic, strong, readonly) MASG3Constraint *rightMargin;
@property (nonatomic, strong, readonly) MASG3Constraint *topMargin;
@property (nonatomic, strong, readonly) MASG3Constraint *bottomMargin;
@property (nonatomic, strong, readonly) MASG3Constraint *leadingMargin;
@property (nonatomic, strong, readonly) MASG3Constraint *trailingMargin;
@property (nonatomic, strong, readonly) MASG3Constraint *centerXWithinMargins;
@property (nonatomic, strong, readonly) MASG3Constraint *centerYWithinMargins;

#endif


@property (nonatomic, strong, readonly) MASG3Constraint *(^attributes)(MASG3Attribute attrs);


@property (nonatomic, strong, readonly) MASG3Constraint *edges;


@property (nonatomic, strong, readonly) MASG3Constraint *size;


@property (nonatomic, strong, readonly) MASG3Constraint *center;


@property (nonatomic, assign) BOOL updateExisting;


@property (nonatomic, assign) BOOL removeExisting;


- (id)initWithView:(MASG3_VIEW *)view;


- (NSArray *)install;

- (MASG3Constraint * (^)(dispatch_block_t))group;

@end
