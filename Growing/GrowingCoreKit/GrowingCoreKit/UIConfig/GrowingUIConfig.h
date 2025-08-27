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


#import "GrowingUIHeader.h"
#import "GrowingEvent.h"

#define C_R_G_B_A(r,g,b,a)  [UIColor colorWithRed:r / 255.0f green:g / 255.0 blue:b / 255.0 alpha:a]
#define C_R_G_B(r,g,b)      C_R_G_B_A(r,g,b,1)

@interface GrowingUIConfig : NSObject

+ (UIColor*)circleListMainColor;
+ (UIColor*)circleColor;
+ (UIColor*)circleLightColor;

+ (UIColor*)circlErrorItemBackgroundColor;
+ (UIColor*)circlErrorItemBorderColor;

+ (UIColor*)circlingItemBackgroundColor;
+ (UIColor*)circlingItemBorderColor;

+ (UIColor*)circledItemBackgroundColor;
+ (UIColor*)circledItemBorderColor;

+ (UIColor*)mainColor;
+ (UIColor*)blueColor;
+ (UIColor*)redColor;
+ (UIColor*)placeHolderColor;
+ (UIColor*)textColor;
+ (UIColor*)textColorDisabled;
+ (UIColor*)secondTitleColor;
+ (UIColor*)highLightColor;
+ (UIColor*)sublineColor;
+ (UIColor*)grayBgColor;
+ (UIColor*)titleColor;
+ (UIColor*)titleColorDisabled;
+ (NSUInteger)textBigFontSize;
+ (NSUInteger)textSmallFontSize;
+ (NSUInteger)textTinyFontSize;
+ (UIColor*)textBigFontColor;
+ (UIColor*)textSmallFontColor;
+ (UIColor*)textTinyFontColor;
+ (UIColor*)radioOnColor;
+ (UIColor*)radioOffColor;
+ (UIColor*)separatorLineColor;
+ (UIColor*)eventListTextColor;
+ (UIColor*)eventListBgColor;

+ (UIColor*)colorWithHex:(unsigned int)colorHex;

+ (UIColor*)colorWithEventType:(GrowingEventType)eventType;

@end

@interface UIColor(growingBlendColor)

- (UIColor*)colorWithAlpha:(CGFloat)alpha backgroundColor:(UIColor*)bgColor;

@end
