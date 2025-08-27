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


#import "UIControl+Growing.h"
#import "FoSwizzling.h"
#import "GrowingNodeManager.h"
#import "GrowingEventManager.h"
#import "UIView+GrowingNode.h"
#import "FoDefineProperty.h"
#import "GrowingAutoTrackEvent.h"

FoPropertyDefine(UIControl, NSNumber* , growingHookCanClick, setGrowingHookCanClick)
FoPropertyDefine(UIControl, NSHashTable*, growingAllTargets, setGrowingAllTargets)

@implementation GrowingUIControlObserver

+ (instancetype)shareInstance
{
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}

- (BOOL)_growingButton:(UIControl *)button hasTargetForEvent:(UIControlEvents)event
{
    
    NSHashTable *allTarget = nil;
    @autoreleasepool {
        allTarget = button.growingAllTargets;
    }
    
    for (id target in allTarget)
    {
        
        if ([button actionsForTarget:target forControlEvent:event].count)
        {
            if (target != [GrowingUIControlObserver shareInstance])
            {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)hasTouchUpInsideAction:(UIControl*)btn
{
    if ([self _growingButton:btn hasTargetForEvent:UIControlEventTouchUpInside])
    {
        return YES;
    }
    else if ([btn isKindOfClass:[UIButton class]] || btn.class == [UIControl class])
    {
        return [self _growingButton:btn hasTargetForEvent:UIControlEventPrimaryActionTriggered];
    }
    else
    {
        return NO;
    }
}

- (void)growingHookTouchUpInside:(UIControl*)btn
{
    if ([self hasTouchUpInsideAction:btn])
    {
        [GrowingClickEvent sendEventWithNode:btn andEventType:GrowingEventTypeButtonClick];
    }
}

- (void)growingHookTouchDown:(UIControl*)btn
{
    if ([self _growingButton:btn hasTargetForEvent:UIControlEventTouchDown])
    {
        if ([self hasTouchUpInsideAction:btn])
        {
            [GrowingTouchDownEvent sendEventWithNode:btn andEventType:GrowingEventTypeButtonTouchDown];
        }
        else
        {
            [GrowingClickEvent sendEventWithNode:btn andEventType:GrowingEventTypeButtonClick];
        }
    }
}

@end

static void updateUIControlCanClick(UIControl *self)
{
    BOOL hasOtherObj = [[GrowingUIControlObserver shareInstance] hasTouchUpInsideAction:self]
        || [[GrowingUIControlObserver shareInstance] _growingButton:self hasTargetForEvent:UIControlEventTouchDown];
    
    if (hasOtherObj)
    {
        self.growingHookCanClick = @YES;
    }
    else
    {
        self.growingHookCanClick = nil;
    }
}

FoHookInstanceWithName(_growingHookAddTarget,
                       UIControl,@selector(addTarget:action:forControlEvents:),
                       void, id target, SEL sel , UIControlEvents event)
{
    FoHookOrgin(target,sel,event);
    [self.growingAllTargets addObject:target];
    updateUIControlCanClick(self);
}
FoHookEnd

FoHookInstanceWithName(_growingHookRemoveTarget,
                       UIControl, @selector(removeTarget:action:forControlEvents:),
                       void,id target,SEL sel,UIControlEvents event)
{
    FoHookOrgin(target,sel,event);
    
    updateUIControlCanClick(self);
}
FoHookEnd


static void setupUIControlObserver(UIControl *self)
{
    self.growingAllTargets = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory |
                              NSPointerFunctionsObjectPointerPersonality
                                                         capacity:2];
    
    old_growingHookAddTarget(self,
                             @selector(addTarget:action:forControlEvents:),
                             [GrowingUIControlObserver shareInstance],
                             @selector(growingHookTouchDown:),
                             UIControlEventTouchDown);
    
    
    
    
    if ([[UIDevice currentDevice].systemVersion doubleValue] >= 11.0
        && ([NSStringFromClass([self class]) hasSuffix:@"UIButtonBarButton"]))
    {
        old_growingHookAddTarget(self,
                                 @selector(addTarget:action:forControlEvents:),
                                 [GrowingUIControlObserver shareInstance],
                                 @selector(growingHookTouchUpInside:),
                                 UIControlEventPrimaryActionTriggered);
    }
    else
    {
        old_growingHookAddTarget(self,
                                 @selector(addTarget:action:forControlEvents:),
                                 [GrowingUIControlObserver shareInstance],
                                 @selector(growingHookTouchUpInside:),
                                 UIControlEventTouchUpInside);
    }
}

FoHookInstance(UIControl, @selector(initWithFrame:),
               id, CGRect frame)
{
    id ret = FoHookOrgin(frame);
    setupUIControlObserver(self);
    return ret;
}
FoHookEnd

FoHookInstance(UIControl, @selector(initWithCoder:),
               id, NSCoder *coder)
{
    id ret = FoHookOrgin(coder);
    setupUIControlObserver(self);
    return ret;
}
FoHookEnd




@implementation UIControl(GrowingHook)

- (BOOL)growingHook_canClick
{
    return self.growingHookCanClick.boolValue;
}

@end
