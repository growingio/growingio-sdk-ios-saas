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


#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

    #import <UIKit/UIKit.h>
    #define MASG3_VIEW UIView
    #define MASG3_VIEW_CONTROLLER UIViewController
    #define MASG3EdgeInsets UIEdgeInsets

    typedef UILayoutPriority MASG3LayoutPriority;
    static const MASG3LayoutPriority MASG3LayoutPriorityRequired = UILayoutPriorityRequired;
    static const MASG3LayoutPriority MASG3LayoutPriorityDefaultHigh = UILayoutPriorityDefaultHigh;
    static const MASG3LayoutPriority MASG3LayoutPriorityDefaultMedium = 500;
    static const MASG3LayoutPriority MASG3LayoutPriorityDefaultLow = UILayoutPriorityDefaultLow;
    static const MASG3LayoutPriority MASG3LayoutPriorityFittingSizeLevel = UILayoutPriorityFittingSizeLevel;

#elif TARGET_OS_MAC

    #import <AppKit/AppKit.h>
    #define MASG3_VIEW NSView
    #define MASG3EdgeInsets NSEdgeInsets

    typedef NSLayoutPriority MASG3LayoutPriority;
    static const MASG3LayoutPriority MASG3LayoutPriorityRequired = NSLayoutPriorityRequired;
    static const MASG3LayoutPriority MASG3LayoutPriorityDefaultHigh = NSLayoutPriorityDefaultHigh;
    static const MASG3LayoutPriority MASG3LayoutPriorityDragThatCanResizeWindow = NSLayoutPriorityDragThatCanResizeWindow;
    static const MASG3LayoutPriority MASG3LayoutPriorityDefaultMedium = 501;
    static const MASG3LayoutPriority MASG3LayoutPriorityWindowSizeStayPut = NSLayoutPriorityWindowSizeStayPut;
    static const MASG3LayoutPriority MASG3LayoutPriorityDragThatCannotResizeWindow = NSLayoutPriorityDragThatCannotResizeWindow;
    static const MASG3LayoutPriority MASG3LayoutPriorityDefaultLow = NSLayoutPriorityDefaultLow;
    static const MASG3LayoutPriority MASG3LayoutPriorityFittingSizeCompression = NSLayoutPriorityFittingSizeCompression;

#endif


#define MASG3AttachKeys(...)                                                    \
    NSDictionary *keyPairs = NSDictionaryOfVariableBindings(__VA_ARGS__);     \
    for (id key in keyPairs.allKeys) {                                        \
        id obj = keyPairs[key];                                               \
        NSAssert([obj respondsToSelector:@selector(setMasG3_key:)],             \
                 @"Cannot attach masG3_key to %@", obj);                        \
        [obj setMasG3_key:key];                                                 \
    }


#define MASG3_NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define MASG3_NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (MASG3_NSUINT_BIT - howmuch)))


static inline id _MASG3BoxValue(const char *type, ...) {
    va_list v;
    va_start(v, type);
    id obj = nil;
    if (strcmp(type, @encode(id)) == 0) {
        id actual = va_arg(v, id);
        obj = actual;
    } else if (strcmp(type, @encode(CGPoint)) == 0) {
        CGPoint actual = (CGPoint)va_arg(v, CGPoint);
        obj = [NSValue value:&actual withObjCType:type];
    } else if (strcmp(type, @encode(CGSize)) == 0) {
        CGSize actual = (CGSize)va_arg(v, CGSize);
        obj = [NSValue value:&actual withObjCType:type];
    } else if (strcmp(type, @encode(MASG3EdgeInsets)) == 0) {
        MASG3EdgeInsets actual = (MASG3EdgeInsets)va_arg(v, MASG3EdgeInsets);
        obj = [NSValue value:&actual withObjCType:type];
    } else if (strcmp(type, @encode(double)) == 0) {
        double actual = (double)va_arg(v, double);
        obj = [NSNumber numberWithDouble:actual];
    } else if (strcmp(type, @encode(float)) == 0) {
        float actual = (float)va_arg(v, double);
        obj = [NSNumber numberWithFloat:actual];
    } else if (strcmp(type, @encode(int)) == 0) {
        int actual = (int)va_arg(v, int);
        obj = [NSNumber numberWithInt:actual];
    } else if (strcmp(type, @encode(long)) == 0) {
        long actual = (long)va_arg(v, long);
        obj = [NSNumber numberWithLong:actual];
    } else if (strcmp(type, @encode(long long)) == 0) {
        long long actual = (long long)va_arg(v, long long);
        obj = [NSNumber numberWithLongLong:actual];
    } else if (strcmp(type, @encode(short)) == 0) {
        short actual = (short)va_arg(v, int);
        obj = [NSNumber numberWithShort:actual];
    } else if (strcmp(type, @encode(char)) == 0) {
        char actual = (char)va_arg(v, int);
        obj = [NSNumber numberWithChar:actual];
    } else if (strcmp(type, @encode(bool)) == 0) {
        bool actual = (bool)va_arg(v, int);
        obj = [NSNumber numberWithBool:actual];
    } else if (strcmp(type, @encode(unsigned char)) == 0) {
        unsigned char actual = (unsigned char)va_arg(v, unsigned int);
        obj = [NSNumber numberWithUnsignedChar:actual];
    } else if (strcmp(type, @encode(unsigned int)) == 0) {
        unsigned int actual = (unsigned int)va_arg(v, unsigned int);
        obj = [NSNumber numberWithUnsignedInt:actual];
    } else if (strcmp(type, @encode(unsigned long)) == 0) {
        unsigned long actual = (unsigned long)va_arg(v, unsigned long);
        obj = [NSNumber numberWithUnsignedLong:actual];
    } else if (strcmp(type, @encode(unsigned long long)) == 0) {
        unsigned long long actual = (unsigned long long)va_arg(v, unsigned long long);
        obj = [NSNumber numberWithUnsignedLongLong:actual];
    } else if (strcmp(type, @encode(unsigned short)) == 0) {
        unsigned short actual = (unsigned short)va_arg(v, unsigned int);
        obj = [NSNumber numberWithUnsignedShort:actual];
    }
    va_end(v);
    return obj;
}

#define MASG3BoxValue(value) _MASG3BoxValue(@encode(__typeof__((value))), (value))
