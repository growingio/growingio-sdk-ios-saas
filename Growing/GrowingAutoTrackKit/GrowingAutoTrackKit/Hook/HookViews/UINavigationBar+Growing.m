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


#import "UINavigationBar+Growing.h"
#import "FoSwizzling.h"
#import "GrowingNodeManager.h"
#import "FoDefineProperty.h"
#import "GrowingAutoTrackEvent.h"

FoPropertyDefine(UINavigationBar, NSNumber*, growing_isTouchingBackBtn, setGrowing_isTouchingBackBtn)

FoHookInstance(UINavigationBar, @selector(popNavigationItemAnimated:),
               UINavigationItem *, BOOL animated)
{
    
    if (self.growing_isTouchingBackBtn)
    {
        [GrowingClickEvent sendEventWithNode:self.growing_backButtonView
                                andEventType:GrowingEventTypeButtonClick];
    }
    
    
    
    BOOL donottrack = [self growingNodeIsBadNode];
    self.growingNodeIsBadNode = YES;
    UINavigationItem * ret = FoHookOrgin(animated);
    self.growingNodeIsBadNode = donottrack;
    return ret;
}
FoHookEnd

FoHookInstance(UINavigationBar , NSSelectorFromString([NSString stringWithFormat:@"_%@For%@At%@:",@"pop",@"Touch",@"Point"]),
               void,CGPoint point)
{
    self.growing_isTouchingBackBtn = @YES;
    FoHookOrgin(point);
    self.growing_isTouchingBackBtn =nil;
}
FoHookEnd


@implementation UINavigationBar(Growing)

- (UIView*)growing_backButtonView
{
    if (!self.backItem)
    {
        return nil;
    }
    NSString *selName = [[NSString alloc] initWithFormat:@"back%@View",@"Button"];
    SEL sel = NSSelectorFromString(selName);
    id backView = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self.backItem respondsToSelector:sel])
    {
        backView = [self.backItem performSelector:sel];
    }
#pragma clang diagnostic pop
    return backView;
}

@end
