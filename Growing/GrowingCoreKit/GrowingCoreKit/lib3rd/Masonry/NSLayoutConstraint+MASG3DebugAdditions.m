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


#import "NSLayoutConstraint+MASG3DebugAdditions.h"
#import "MASG3Constraint.h"
#import "MASG3LayoutConstraint.h"

@implementation NSLayoutConstraint (MASG3DebugAdditions)

#pragma mark - description maps

+ (NSDictionary *)growingLayoutRelationDescriptionsByValue {
    static dispatch_once_t once;
    static NSDictionary *descriptionMap;
    dispatch_once(&once, ^{
        descriptionMap = @{
            @(NSLayoutRelationEqual)                : @"==",
            @(NSLayoutRelationGreaterThanOrEqual)   : @">=",
            @(NSLayoutRelationLessThanOrEqual)      : @"<=",
        };
    });
    return descriptionMap;
}

+ (NSDictionary *)growingLayoutAttributeDescriptionsByValue {
    static dispatch_once_t once;
    static NSDictionary *descriptionMap;
    dispatch_once(&once, ^{
        descriptionMap = @{
            @(NSLayoutAttributeTop)      : @"top",
            @(NSLayoutAttributeLeft)     : @"left",
            @(NSLayoutAttributeBottom)   : @"bottom",
            @(NSLayoutAttributeRight)    : @"right",
            @(NSLayoutAttributeLeading)  : @"leading",
            @(NSLayoutAttributeTrailing) : @"trailing",
            @(NSLayoutAttributeWidth)    : @"width",
            @(NSLayoutAttributeHeight)   : @"height",
            @(NSLayoutAttributeCenterX)  : @"centerX",
            @(NSLayoutAttributeCenterY)  : @"centerY",
            @(NSLayoutAttributeBaseline) : @"baseline",
            
#if TARGET_OS_IPHONE
            @(NSLayoutAttributeLeftMargin)           : @"leftMargin",
            @(NSLayoutAttributeRightMargin)          : @"rightMargin",
            @(NSLayoutAttributeTopMargin)            : @"topMargin",
            @(NSLayoutAttributeBottomMargin)         : @"bottomMargin",
            @(NSLayoutAttributeLeadingMargin)        : @"leadingMargin",
            @(NSLayoutAttributeTrailingMargin)       : @"trailingMargin",
            @(NSLayoutAttributeCenterXWithinMargins) : @"centerXWithinMargins",
            @(NSLayoutAttributeCenterYWithinMargins) : @"centerYWithinMargins",
#endif
            
        };
    
    });
    return descriptionMap;
}


+ (NSDictionary *)growingLayoutPriorityDescriptionsByValue {
    static dispatch_once_t once;
    static NSDictionary *descriptionMap;
    dispatch_once(&once, ^{
#if TARGET_OS_IPHONE
        descriptionMap = @{
            @(MASG3LayoutPriorityDefaultHigh)      : @"high",
            @(MASG3LayoutPriorityDefaultLow)       : @"low",
            @(MASG3LayoutPriorityDefaultMedium)    : @"medium",
            @(MASG3LayoutPriorityRequired)         : @"required",
            @(MASG3LayoutPriorityFittingSizeLevel) : @"fitting size",
        };
#elif TARGET_OS_MAC
        descriptionMap = @{
            @(MASG3LayoutPriorityDefaultHigh)                 : @"high",
            @(MASG3LayoutPriorityDragThatCanResizeWindow)     : @"drag can resize window",
            @(MASG3LayoutPriorityDefaultMedium)               : @"medium",
            @(MASG3LayoutPriorityWindowSizeStayPut)           : @"window size stay put",
            @(MASG3LayoutPriorityDragThatCannotResizeWindow)  : @"drag cannot resize window",
            @(MASG3LayoutPriorityDefaultLow)                  : @"low",
            @(MASG3LayoutPriorityFittingSizeCompression)      : @"fitting size",
            @(MASG3LayoutPriorityRequired)                    : @"required",
        };
#endif
    });
    return descriptionMap;
}

#pragma mark - description override

+ (NSString *)growingDescriptionForObject:(id)obj {
    if ([obj respondsToSelector:@selector(masG3_key)] && [obj masG3_key]) {
        return [NSString stringWithFormat:@"%@:%@", [obj class], [obj masG3_key]];
    }
    return [NSString stringWithFormat:@"%@:%p", [obj class], obj];
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"<"];

    [description appendString:[self.class growingDescriptionForObject:self]];

    [description appendFormat:@" %@", [self.class growingDescriptionForObject:self.firstItem]];
    if (self.firstAttribute != NSLayoutAttributeNotAnAttribute) {
        [description appendFormat:@".%@", [self.class.growingLayoutAttributeDescriptionsByValue objectForKey:@(self.firstAttribute)]];
    }

    [description appendFormat:@" %@", [self.class.growingLayoutRelationDescriptionsByValue objectForKey:@(self.relation)]];

    if (self.secondItem) {
        [description appendFormat:@" %@", [self.class growingDescriptionForObject:self.secondItem]];
    }
    if (self.secondAttribute != NSLayoutAttributeNotAnAttribute) {
        [description appendFormat:@".%@", [self.class.growingLayoutAttributeDescriptionsByValue objectForKey:@(self.secondAttribute)]];
    }
    
    if (self.multiplier != 1) {
        [description appendFormat:@" * %g", self.multiplier];
    }
    
    if (self.secondAttribute == NSLayoutAttributeNotAnAttribute) {
        [description appendFormat:@" %g", self.constant];
    } else {
        if (self.constant) {
            [description appendFormat:@" %@ %g", (self.constant < 0 ? @"-" : @"+"), ABS(self.constant)];
        }
    }

    if (self.priority != MASG3LayoutPriorityRequired) {
        [description appendFormat:@" ^%@", [self.class.growingLayoutPriorityDescriptionsByValue objectForKey:@(self.priority)] ?: [NSNumber numberWithDouble:self.priority]];
    }

    [description appendString:@">"];
    return description;
}

@end
