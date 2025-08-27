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


#import "UIImage+GrowingHelper.h"
#import "NSData+GrowingHelper.h"

@implementation UIImage (GrowingHelper)

- (NSData*)growingHelper_JPEG:(CGFloat)compress
{
    return UIImageJPEGRepresentation(self, compress);
}

- (NSData*)growingHelper_PNG
{
    return UIImagePNGRepresentation(self);
}

- (NSString*)growingHelper_Base64JPEG:(CGFloat)compress
{
    return [[self growingHelper_JPEG:compress] growingHelper_base64String];
}

- (NSString*)growingHelper_Base64PNG
{
    return [[self growingHelper_PNG] growingHelper_base64String];
}

- (UIImage*)growingHelper_getSubImage:(CGRect)rect
{
    rect.origin.x *= self.scale;
    rect.origin.y *= self.scale;
    rect.size.width *= self.scale;
    rect.size.height *= self.scale;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *image = [UIImage imageWithCGImage:subImageRef scale:self.scale orientation:UIImageOrientationUp];
    CGImageRelease(subImageRef);
    
    return image;
}

#define bytesPerPixel 4
#define bitsPerComponent 8
#define HEAT_MAP_NODE_IMAGE_MAX_ALPHA 200

#define kColorTemplateLength 256

+ (UIImage*)createHeatMapImageBySize:(CGSize)size brightLevel:(CGFloat)level
{
    CGFloat maxSize = MAX(size.width, size.height);
    CGSize imgSize = CGSizeMake(maxSize, maxSize);
    level = MIN(1, level);
    level = MAX(0, level);
    level = 0.4f+ level * 0.6f;
    const unsigned int * const maskTemplate = [self getMaskTemplate];
    const unsigned int * const colorTemplate = [self getColorTemplate];
    
    
    CGFloat *colors = malloc(sizeof(CGFloat) * 4 * kColorTemplateLength);
    
    for (NSInteger i = 0 ; i < kColorTemplateLength ; i++)
    {
        unsigned int alpha = (maskTemplate[i] & 0x000000FF) * level;
        unsigned int color = colorTemplate[alpha];
        unsigned int r = (color >> 24) & 0xFF ;
        unsigned int g = (color >> 16) & 0xFF;
        unsigned int b = (color >> 8)  & 0xFF;
        
        colors[i * 4 + 0] = r / 255.0f;
        colors[i * 4 + 1] = g / 255.0f;
        colors[i * 4 + 2] = b / 255.0f;
        colors[i * 4 + 3] = alpha / 255.0f;
    }
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents(space,
                                                                 colors,
                                                                 nil,
                                                                 kColorTemplateLength);
    free(colors);
    CGColorSpaceRelease(space),space=NULL;
    
    CGPoint center = CGPointMake(maxSize / 2, maxSize / 2);
    CGFloat startRadius = 0.0f;
    CGFloat endRadius = maxSize / 2;
    
    
    UIGraphicsBeginImageContextWithOptions(imgSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextDrawRadialGradient(context, gradient, center, startRadius, center, endRadius, 0);
    CGGradientRelease(gradient),gradient=NULL;
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsPopContext();
    return img;
    
}


+ (const unsigned int *)getColorTemplate
{
    static unsigned int *retColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat color[] = {
            0,0,1,1,
            0,1,0,1,
            1,1,0,1,
            1,0,0,1,};
        
        CGFloat location[] = {0.25f,0.55f,0.85f,1.0f};
        retColor = [self createTemplateArrayByColor:color location:location count:4];
    });
    return retColor;
}


+ (const unsigned int *)getMaskTemplate
{
    static unsigned int *cacheColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat color[] = {0,0,0,1,
                           0,0,0,1,
                           0,0,0,0};
        CGFloat location[] = {0.f,0.15f,1.f};
        cacheColor = [self createTemplateArrayByColor:color location:location count:3];
    });
    return cacheColor;
}


+ (unsigned int*)createTemplateArrayByColor:(CGFloat*)colors
                                   location:(CGFloat*)location
                                      count:(NSInteger)count
{
    unsigned int *rawData = malloc(kColorTemplateLength * 1 * 4);
    memset(rawData, 0, kColorTemplateLength * 1 * 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rawData,
                                                 kColorTemplateLength,
                                                 1,
                                                 bitsPerComponent,
                                                 kColorTemplateLength * 1 * 4,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast| kCGBitmapByteOrder32Little);

    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, location, count);
    CGContextDrawLinearGradient(context,
                                gradient,
                                CGPointMake(0,0),
                                CGPointMake(kColorTemplateLength,0),
                                0);
    
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    CGContextRelease(context);
    
    return rawData;
}

@end
