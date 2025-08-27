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


#import "UIView+Growing.h"
#import "FoSwizzling.h"

#import <objc/runtime.h>
#import "UIViewController+Growing.h"

#import "UIWindow+Growing.h"
#import "UIView+GrowingNode.h"
#import "UIView+GrowingHelper.h"
#import "GrowingAutoTrackEvent.h"
#import "GrowingIMPTrack.h"
#import "GrowingGlobal.h"

FoHookInstance(UIView, @selector(didMoveToSuperview),void)
{
    FoHookOrgin();
    if (self.superview && self.window)
    {
        [[GrowingIMPTrack shareInstance] addNode:self inSubView:YES];

        if (!g_enableImp)
        {
            return;
        }
        
        if(self.growingAttributesDonotTrackImp)
        {
            return;
        }
        [GrowingImpressionEvent sendEventWithNode:self
                                     andEventType:GrowingEventTypeUIAddSubView];
    }
}
FoHookEnd

FoHookInstance(UIView, @selector(setAlpha:),
               void, CGFloat alpha)
{
    BOOL hasHidden = self.alpha < 0.01;
    FoHookOrgin(alpha);
    
    if (self.nextResponder
        && !self.nextResponder.isProxy
        && [self.nextResponder isKindOfClass:[UIViewController class]]) {
        [self.window growingHook_setNeedUpdateCurViewControllers];
    }
    
    if (!g_enableImp)
    {
        return;
    }
    
    if (hasHidden && self.alpha > 0.01 && self.superview && self.window)
    {
        if(self.growingAttributesDonotTrackImp)
        {
            return;
        }
        
        [GrowingImpressionEvent sendEventWithNode:self andEventType:GrowingEventTypeUISetAlpha];
    }
}
FoHookEnd

FoHookInstance(UIView, @selector(setHidden:),
               void,BOOL hidden)
{
    BOOL hasHidden = self.isHidden;
    FoHookOrgin(hidden);
    
    if (self.nextResponder
        && !self.nextResponder.isProxy
        && [self.nextResponder isKindOfClass:[UIViewController class]]) {
        [self.window growingHook_setNeedUpdateCurViewControllers];
    }
    
    if (!g_enableImp)
    {
        return;
    }
    
    if (hasHidden && !self.isHidden && self.superview && self.window)
    {
        if(self.growingAttributesDonotTrackImp)
        {
            return;
        }
        [GrowingImpressionEvent sendEventWithNode:self andEventType:GrowingEventTypeUISetHidden];
    }
}
FoHookEnd
