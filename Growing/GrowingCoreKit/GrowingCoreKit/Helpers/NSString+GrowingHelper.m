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


#import "NSString+GrowingHelper.h"
#import "NSData+GrowingHelper.h"
#import "NSDictionary+GrowingHelper.h"
#import <CommonCrypto/CommonDigest.h>
#import "GrowingDeviceInfo.h"
#import "GrowingCocoaLumberjack.h"

static NSString *const growingSpecialCharactersString = @"_!@#$%^&*()-=+|\[]{},.<>/?";

@implementation NSString (GrowingHelper)


+ (void)load
{
}

- (NSString*)growingHelper_safeSubStringWithLength:(NSInteger)length
{
    if (self.length <= length)
    {
        return self;
    }
    
    NSRange range;
    for(int i = 0 ; i < self.length ; i += range.length)
    {
        range = [self rangeOfComposedCharacterSequenceAtIndex:i];
        if (range.location + range.length > length)
        {
            return [self substringToIndex:range.location];
        }
    }
    return self;
}

- (NSData*)growingHelper_uft8Data
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

- (id)growingHelper_jsonObject
{
    return [[self growingHelper_uft8Data] growingHelper_jsonObject];
}

- (NSDictionary *)growingHelper_dictionaryObject
{
    id dict = [self growingHelper_jsonObject];
    if ([dict isKindOfClass:[NSDictionary class]])
    {
        return dict;
    }
    else
    {
        return nil;
    }
}

+ (instancetype)growingHelper_stringWithVisiableNumber:(long long)number
                                           formatBlock:(growingVisiableNumberStringBlock)block
{
    return block(number);
}

+ (NSArray<NSString*>*)growingHelper_stringWithVisiableNumbers:(NSArray<NSNumber *> *)numbers
                                              formatBlockMaker:(growingVisiableNumberStringBlock (^)(long long))makerblock
{
    if (!numbers.count)
    {
        return nil;
    }
    
    NSArray<NSNumber*> *orderNumbers = [numbers sortedArrayUsingComparator:^NSComparisonResult(NSNumber* obj1, NSNumber* obj2) {
        if (obj1.longLongValue < obj2.longLongValue)
        {
            return NSOrderedAscending;
        }
        else if (obj1.longLongValue > obj2.longLongValue)
        {
            return NSOrderedDescending;
        }
        else
        {
            return NSOrderedSame;
        }
    }];

    growingVisiableNumberStringBlock block = makerblock(orderNumbers.lastObject.longLongValue);
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (NSNumber *n in numbers)
    {
        NSString *str = [self growingHelper_stringWithVisiableNumber:n.longLongValue
                                                         formatBlock:block];
        [arr addObject:str];
    }
    return arr;
}

- (UIImage *)growingHelper_imageWithEdge:(UIEdgeInsets)edge
{
    
    UIFont *font = [UIFont systemFontOfSize:14.0];
    CGSize fontSize = [self sizeWithFont:font];
    CGSize size  = fontSize;
    size.width += edge.left + edge.right;
    size.height += edge.top + edge.bottom;

    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);


    
    
    

    
    [self drawInRect:CGRectMake(edge.left, edge.top, fontSize.width, fontSize.height) withFont:font];

    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

-(NSString *)growingHelper_stringWithXmlConformed
{
    NSMutableString * xml = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < self.length; i++)
    {
        unichar c = [self characterAtIndex:i];
        switch (c)
        {
            case (unichar)'&':
            {
                [xml appendString:@"&amp;"];
            }
                break;
            case (unichar)'<':
            {
                [xml appendString:@"&lt;"];
            }
                break;
            case (unichar)'>':
            {
                [xml appendString:@"&gt;"];
            }
                break;
            case (unichar)'\"':
            {
                [xml appendString:@"&quot;"];
            }
                break;
            case (unichar)'\'':
            {
                [xml appendString:@"&apos;"];
            }
                break;
            default:
            {
                [xml appendString:[NSString stringWithCharacters:&c length:1]];
            }
                break;
        }
    }
    return xml;
}

- (NSString*)growingHelper_stringWithUrlDecode
{
    NSString * s = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return [s stringByRemovingPercentEncoding];
}

- (NSString*)growingHelper_stringByRemovingSpace
{
    NSArray * array = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [array componentsJoinedByString:@""];
}

- (NSString *)growingHelper_sha1
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];

    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }

    return output;
}

- (BOOL)growingHelper_matchWildly:(NSString *)wildPattern
{
    BOOL hasWildStar = NO;
    BOOL hasMultipleWildStar = NO;
    NSRange firstStarRange = [wildPattern rangeOfString:@"*"];
    NSUInteger endPosOfFirstStarRange = firstStarRange.location + firstStarRange.length;

    hasWildStar = (firstStarRange.location != NSNotFound);
    if (hasWildStar)
    {
        if (wildPattern.length > endPosOfFirstStarRange)
        {
            NSRange range;
            range.location = endPosOfFirstStarRange;
            range.length = wildPattern.length - range.location;
            NSRange secondStarRange = [wildPattern rangeOfString:@"*" options:NSLiteralSearch range:range];
            hasMultipleWildStar = (secondStarRange.location != NSNotFound);
        }
        else if (wildPattern.length == 1) 
        {
            return true;
        }
    }

    if (hasWildStar)
    {
        if (hasMultipleWildStar)
        {
            
            
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", wildPattern];
            return [pred evaluateWithObject:self];
        }
        else
        {
            if (firstStarRange.location == 0)
            {
                return [self hasSuffix:[wildPattern substringFromIndex:endPosOfFirstStarRange]];
            }
            else if (endPosOfFirstStarRange == wildPattern.length)
            {
                return [self hasPrefix:[wildPattern substringToIndex:firstStarRange.location]];
            }
            else
            {
                return [self hasPrefix:[wildPattern substringToIndex:firstStarRange.location]]
                    && [self hasSuffix:[wildPattern substringFromIndex:endPosOfFirstStarRange]];
            }
        }
    }
    else
    {
        return [self isEqualToString:wildPattern];
    }
}

- (BOOL)growingHelper_isLegal
{
    if (self.length != 1) {
        return NO;
    }
    
    unichar character = [self characterAtIndex:0];
    
    BOOL isNum = isdigit(character);
    BOOL isLetter = (character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z');
    BOOL isSpecialCharacter = ([growingSpecialCharactersString rangeOfString:self].location != NSNotFound);
    if (isNum || isLetter || isSpecialCharacter) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)growingHelper_isValidU
{
    if (!self.length) {
        return NO;
    }
    
    NSArray *stringArray = [self componentsSeparatedByString:@"-"];
    
    for (NSString *string in stringArray) {
        NSString *zero = [NSString stringWithFormat:@"0{%lu}", (unsigned long)string.length];
        NSPredicate *zeroPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",zero];
        if (![zeroPre evaluateWithObject:string]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)growingHelper_encryptString
{
    if ([GrowingDeviceInfo currentDeviceInfo].encryptStringBlock) {
        return [GrowingDeviceInfo currentDeviceInfo].encryptStringBlock(self);
    } else {
        return self;
    }
}


- (instancetype)initWithJsonObject_growingHelper:(id)obj
{
    if (!obj || ![NSJSONSerialization isValidJSONObject:obj])
    {
        return nil;
    }
    
    NSData *data = nil;
    @autoreleasepool {
        data = [obj growingHelper_jsonData];
    }

    self = [self initWithData:data encoding:NSUTF8StringEncoding];
    return self;
}

- (void)growingHelper_debugOutput
{
    
    
    
    
    
    
    
    
    printf("%s\n", self.UTF8String);
}


- (BOOL)isValidKey{
    if (![self isValidIdentifier]) {
        GIOLogError(parameterKeyErrorLog);
    }
    return [self isValidIdentifier];
}


- (BOOL)isValidIdentifier{
    
    
    if (self.length == 0 || self.length > 50) {
        return NO;
    }









    return YES;
}

+ (NSString *)growingHelper_join:(NSString *)first, ... {
    NSString *iter, *result = first;
    va_list strings;
    va_start(strings, first);

    while ((iter = va_arg(strings, NSString*))) {
        NSString *capitalized = iter.capitalizedString;
        result = [result stringByAppendingString:capitalized];
    }
    
    va_end(strings);

    return result;
}

@end
