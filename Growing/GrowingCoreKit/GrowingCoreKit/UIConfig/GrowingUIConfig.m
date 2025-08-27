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


#import "GrowingUIConfig.h"




static UIColor* growingColorWithARGB(unsigned int argb)
{
    CGFloat red = (argb>>16)&0xFF;
    CGFloat green = (argb>>8)&0xFF;
    CGFloat blue = argb&0xFF;
    CGFloat alpha = 255;
    
    if (argb > (unsigned int)0xFFFFFF)
    {
        alpha = (argb>>24)&0xFF;
    }
    return C_R_G_B_A(red, green, blue, alpha / 255.0f);
}

#define C_RGB(color) growingColorWithARGB(color)

@implementation GrowingUIConfig

+ (UIColor*)colorWithHex:(unsigned int)colorHex
{
    return C_RGB(colorHex);
}

+ (UIColor*)circleColor
{
    return C_R_G_B_A(0xFF, 0x48, 0x24, 0.9);
}

+ (UIColor*)circleLightColor
{
    return C_R_G_B_A(0xFF, 0x48, 0x24, 0.3);
}

+ (UIColor*)circlingItemBackgroundColor
{
    return C_R_G_B_A(0xFF, 0x48, 0x24, 0.3);
}

+ (UIColor*)circlErrorItemBorderColor
{
    return [self circlingItemBorderColor];
}

#define ERRORIMAGESIZE 10

static UIImage* createErrorImage()
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(ERRORIMAGESIZE,ERRORIMAGESIZE), NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, ERRORIMAGESIZE, ERRORIMAGESIZE);
    CGContextSetLineWidth(context, 1.0f);
    
    CGContextSetStrokeColorWithColor(context, [GrowingUIConfig circlingItemBorderColor].CGColor);
    CGContextStrokePath(context);
    
    CGContextSetFillColorWithColor(context, [GrowingUIConfig circlingItemBackgroundColor].CGColor);
    CGContextFillRect(context, CGRectMake(0,0,ERRORIMAGESIZE,ERRORIMAGESIZE));
    
    
    return UIGraphicsGetImageFromCurrentImageContext();
}

+ (UIColor*)circlErrorItemBackgroundColor
{
    static UIColor *color = nil;
    if (!color)
    {
        color = [UIColor colorWithPatternImage:createErrorImage()];
    }
    return color;
}

+ (UIColor*)circlingItemBorderColor
{
    return C_R_G_B_A(0xFF, 0x48, 0x24, 0.9);
}

+ (UIColor*)circledItemBackgroundColor
{
    return C_R_G_B_A(0xFF, 0xDD, 0x24, 0.3);
}

+ (UIColor*)circledItemBorderColor
{
    return C_R_G_B_A(0xFF, 0xDD, 0x24, 0.9);
}

+ (UIColor*)mainColor
{
    return C_RGB(0x19AC9E);
}

+ (UIColor*)blueColor
{
    return C_R_G_B(18, 143, 252);
}

+ (UIColor*)redColor
{
    return C_R_G_B(250, 103, 73);
}

+ (UIColor*)placeHolderColor
{
    return C_R_G_B(153, 153, 153);
}

+ (UIColor*)highLightColor
{
    return [self mainColor];
}

+ (UIColor*)textColor
{
    return C_R_G_B(0x33,0x33,0x33);
}

+ (UIColor*)textColorDisabled
{
    return C_R_G_B(0x99, 0x99, 0x99);
}

+ (UIColor*)sublineColor
{
    return C_R_G_B(0xB9, 0xB9, 0xB9);
}

+ (UIColor*)grayBgColor
{
    return C_R_G_B(0xF1, 0xF6, 0xFC);
}

+ (UIColor*)secondTitleColor
{
    return C_R_G_B(102,102,102);
}

+ (UIColor*)titleColor
{
    return [UIColor whiteColor];
}

+ (UIColor*)titleColorDisabled
{
    return C_R_G_B(51,51,51);
}

+ (NSUInteger)textBigFontSize
{
    return 20;
}

+ (NSUInteger)textSmallFontSize
{
    return 17;
}

+ (NSUInteger)textTinyFontSize
{
    return 11;
}

+ (UIColor*)textBigFontColor
{
    return C_R_G_B(0x80, 0x80, 0x80);
}

+ (UIColor*)textSmallFontColor
{
    return C_R_G_B(0xA5, 0xA5, 0xA5);
}

+ (UIColor*)textTinyFontColor
{
    return C_R_G_B(0xA5, 0xA5, 0xA5);
}

+ (UIColor*)radioOnColor
{
    return C_R_G_B(0x00, 0xA2, 0x97);
}

+ (UIColor*)radioOffColor
{
    return C_R_G_B(0xD5, 0xD5, 0xD5);
}

+ (UIColor*)separatorLineColor
{
    return C_R_G_B(0xD8, 0xDB, 0xE1);
}

+ (UIColor*)eventListTextColor
{
    return C_R_G_B(120, 136, 151);
}

+ (UIColor*)eventListBgColor
{
    return C_R_G_B(236,236,236);
}

+ (UIColor*)circleListMainColor
{
    return C_R_G_B(154, 211, 250);
}

+ (UIColor*)colorWithEventType:(GrowingEventType)eventType
{
    GrowingEventType type = GrowingTypeGetMainType(eventType);
    int colors[] = {   0x7EBFDD,
        0xF88977,
        0x69D5CA,
        0xFABE7C,
        0xBDD67D,
        0x9EA6DB};
    return [GrowingUIConfig colorWithHex:colors[type]];
}

@end


@implementation UIColor(growingBlendColor)

- (UIColor*)colorWithAlpha:(CGFloat)alpha backgroundColor:(UIColor *)bgColor
{
    CGFloat R1,G1,B1,Alpha1,R2,G2,B2,Alpha2,R,G,B;
    [self    getRed:&R1 green:&G1 blue:&B1 alpha:&Alpha1];
    [bgColor getRed:&R2 green:&G2 blue:&B2 alpha:&Alpha2];
    Alpha1 = alpha;
    
    R = R1 * Alpha1 + R2 * Alpha2 * (1-Alpha1) ;
    G = G1 * Alpha1 + G2 * Alpha2 * (1-Alpha1) ;
    B = B1 * Alpha1 + B2 * Alpha2 * (1-Alpha1) ;
    
    return [UIColor colorWithRed:R green:G blue:B alpha:1];
}

@end
