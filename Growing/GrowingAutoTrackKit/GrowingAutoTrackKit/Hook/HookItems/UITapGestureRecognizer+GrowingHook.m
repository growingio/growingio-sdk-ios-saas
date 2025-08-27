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


#import "UITapGestureRecognizer+GrowingHook.h"
#import "FoSwizzling.h"
#import "GrowingAutoTrackEvent.h"
@interface GrowingUIGestureRecognizerObserver : NSObject

@end

@implementation GrowingUIGestureRecognizerObserver

+ (instancetype)shareInstance
{
    static id o = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        o = [[self alloc] init];
    });
    return o;
}

- (void)handleGest:(UIGestureRecognizer*)gest
{
    SEL sel = [self getSelByGest:gest];
    if (sel)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [((NSObject*)self) performSelector:sel withObject:gest];
#pragma clang diagnostic pop
    }
}

- (SEL)getSelByGest:(UIGestureRecognizer*)gest
{
    if (gest.class == [UITapGestureRecognizer class])
    {
        NSInteger tapCount = ((UITapGestureRecognizer*)gest).numberOfTapsRequired;
        if (tapCount == 1)
        {
            return @selector(clickEvent:);
        }
        else if (tapCount == 2)
        {
            return @selector(doubleClickEvent:);
        }
    }






    return nil;
}

- (void)clickEvent:(UIGestureRecognizer*)gest
{
    [GrowingTapEvent sendEventWithNode:gest.view
                          andEventType:GrowingEventTypeTapGest];
}

- (void)doubleClickEvent:(UIGestureRecognizer*)gest
{
    [GrowingDoubleClickEvent sendEventWithNode:gest.view andEventType:GrowingEventTypeDoubleTapGest];
}

- (void)longPressEvent:(UIGestureRecognizer*)gest
{
    if (gest.state == UIGestureRecognizerStateBegan)
    {
        [GrowingLongPressEvent sendEventWithNode:gest.view andEventType:GrowingEventTypeLongPressGest];
    }
}

@end


FoHookInstance(UITapGestureRecognizer, @selector(initWithTarget:action:), id,id target,SEL action)
{
    UITapGestureRecognizer *gest = FoHookOrgin([GrowingUIGestureRecognizerObserver shareInstance],
                                               @selector(handleGest:));
    [gest addTarget:target action:action];
    return gest;
}
FoHookEnd

FoHookInstance(UITapGestureRecognizer, @selector(initWithCoder:), id, NSCoder *coder)
{
    UITapGestureRecognizer *gest = FoHookOrgin(coder);
    [gest addTarget:[GrowingUIGestureRecognizerObserver shareInstance]
             action:@selector(handleGest:)];
    return gest;
}
FoHookEnd

@implementation UITapGestureRecognizer (GrowingHook)

+ (BOOL)growingGestureRecognizerCanHandleView:(UIView *)view
{
    for (UIGestureRecognizer *gest in view.gestureRecognizers)
    {
        if ([[GrowingUIGestureRecognizerObserver shareInstance] getSelByGest:gest])
        {
            return YES;
        }
    }
    return NO;
}

@end
