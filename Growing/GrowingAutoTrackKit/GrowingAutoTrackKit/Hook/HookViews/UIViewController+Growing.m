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


#import "UIViewController+Growing.h"
#import "FoSwizzling.h"
#import "GrowingEventManager.h"
#import "GrowingInstance.h"
#import <objc/runtime.h>
#import "FoWeakObjectShell.h"
#import "UIWindow+Growing.h"
#import "UIView+Growing.h"
#import "UIView+GrowingNode.h"
#import "FoObjectSELObserver.h"
#import "FoDefineProperty.h"
#import "UIView+GrowingHelper.h"
#import "GrowingAutoTrackEvent.h"
#import "UIApplication+GrowingNode.h"
#import "UIViewController+GrowingNode.h"
#import "GrowingAspect.h"
#import "GrowingJavascriptCore.h"
#import "GrowingEventBus.h"
#import "GrowingEBVCLifeEvent.h"
#import "GrowingGlobal.h"

@interface UIViewController(Growing_private)
- (void)GROW_setViewControllerState:(GrowingAppearState)newState;
- (BOOL)haveAllChildViewControllersSetGrowUIViewControllerShouldTrackAsPage;
- (BOOL)isBigEnoughForAPage;
@end

FoPropertyDefine(UIViewController, NSNumber*, growingHook_isTracked, setGrowingHook_isTracked);
FoPropertyDefine(UIViewController, NSNumber*, growingHook_hasDidAppear, setGrowingHook_hasDidAppear)

FoSwizzleTempletVoid(@selector(viewWillAppear:),
                     void,vcWillAppear,BOOL)

FoSwizzleTempletVoid(@selector(viewWillDisappear:),
                     void,vcWillDisappear,BOOL)

FoSwizzleTempletVoid(@selector(viewDidAppear:),
                     void,vcDidAppear,BOOL)

FoSwizzleTempletVoid(@selector(viewDidDisappear:),
                     void,vcDidDisappear,BOOL)


static char growUIViewControllerShouldTrackAsPageKey;
static void setGrowUIViewControllerShouldTrackAsPage(UIViewController * self, BOOL shouldTrackAsPage)
{
    objc_setAssociatedObject(self,
                             &growUIViewControllerShouldTrackAsPageKey,
                             @(shouldTrackAsPage),
                             OBJC_ASSOCIATION_RETAIN);
}

static BOOL hasSetGrowUIViewControllerShouldTrackAsPage(UIViewController * self)
{
    NSNumber * flag = objc_getAssociatedObject(self, &growUIViewControllerShouldTrackAsPageKey);
    return flag != nil;
}

static BOOL growUIViewControllerShouldTrackAsPage(UIViewController * self)
{
    NSNumber * flag = objc_getAssociatedObject(self, &growUIViewControllerShouldTrackAsPageKey);
    return flag == nil || [flag boolValue];
}


static BOOL haveAllChildViewControllersSetGrowUIViewControllerShouldTrackAsPage(UIViewController* parent)
{
    NSArray *allChildren = [parent childViewControllers];
    if (allChildren.count) {
        
        
        if (![parent isKindOfClass:[UINavigationController class]] && ![parent isKindOfClass:[UITabBarController class]]) {
            NSUInteger usedCount = 0;
            NSUInteger shouldTrackCount = 0;
            for (UIViewController *childVC in allChildren) {
                
                if ([childVC isViewLoaded] && childVC.view.superview) {
                    usedCount++;
                }
                
                if (haveAllChildViewControllersSetGrowUIViewControllerShouldTrackAsPage(childVC) && hasSetGrowUIViewControllerShouldTrackAsPage(childVC)) {
                    shouldTrackCount++;
                }
            }
            
            if ([parent isKindOfClass:NSClassFromString(@"RCCDrawerController")]) {
                return YES;
            }
            
            
            if (usedCount == shouldTrackCount) {
                return YES;
            }
        } else {
            
            for (UIViewController *childVC in allChildren) {
                if (haveAllChildViewControllersSetGrowUIViewControllerShouldTrackAsPage(childVC) && hasSetGrowUIViewControllerShouldTrackAsPage(childVC)) {
                    return YES;
                }
            }
        }
        
        return NO;
    } else {
        return YES;
    }
}






static NSMutableArray *delayedVCs = nil;
static void delayViewDidAppearRoutineIfNotAllChildrenDidAppear(UIViewController * originInstance)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delayedVCs = [[NSMutableArray alloc] init];
    });
    if (!hasSetGrowUIViewControllerShouldTrackAsPage(originInstance))
    {
        setGrowUIViewControllerShouldTrackAsPage(originInstance, [originInstance isBigEnoughForAPage]);
        for (NSInteger i = 0; i < delayedVCs.count; i++) {
            UIViewController *vc = delayedVCs[i];
            if ([vc haveAllChildViewControllersSetGrowUIViewControllerShouldTrackAsPage]) {
                [delayedVCs removeObjectAtIndex:i];
                i--;
                [vc GROW_setViewControllerState:GrowingAppearStateDidShow];
                if (delayedVCs.count == 0) {
                    break;
                }
            }
        }
    }
    if ([originInstance haveAllChildViewControllersSetGrowUIViewControllerShouldTrackAsPage]) {
        
        if (originInstance.parentViewController && [delayedVCs containsObject:originInstance.parentViewController]) {
            [delayedVCs addObject:originInstance];
        } else {
            [originInstance GROW_setViewControllerState:GrowingAppearStateDidShow];
        }
    }
    else
    {
        [delayedVCs addObject:originInstance];
    }
}

static void removeSelfFromDelayedVCsIfNeeded(UIViewController * willDisApplearVC)
{
    if ([delayedVCs containsObject:willDisApplearVC]) {
        [delayedVCs removeObject:willDisApplearVC];
    }
}

static char growUIViewControllerHookInitObjectKey;
static void growUIViewControllerHookInitObject(UIViewController* self)
{
    if (objc_getAssociatedObject(self, &growUIViewControllerHookInitObjectKey))
    {
        return;
    }
    else
    {
        objc_setAssociatedObject(self,
                                 &growUIViewControllerHookInitObjectKey,
                                 @YES,
                                 OBJC_ASSOCIATION_RETAIN);
    }
    
    
    
    
    
    
    NSString *specialClassName = [@"UIInput" stringByAppendingString:@"WindowController"];
    if ([NSStringFromClass([self class]) isEqualToString:specialClassName]) {
        return;
    }
    
    
    GrowingAspectBefore(self, vcWillAppear, void, @selector(viewWillAppear:) , (BOOL)animated, {
        [originInstance GROW_setViewControllerState:GrowingAppearStateWillShow];
        GrowingEBVCLifeEvent *lifeEvent = [[GrowingEBVCLifeEvent alloc] initWithLifeType:GrowingVCLifeWillAppear];
        [GrowingEventBus send:lifeEvent];
    });
    
    
    GrowingAspectBefore(self, vcWillDisappear, void, @selector(viewWillDisappear:),(BOOL)animated, {
        removeSelfFromDelayedVCsIfNeeded(originInstance);
        [originInstance GROW_setViewControllerState:GrowingAppearStateWillHide];
        
        GrowingEBVCLifeEvent *lifeEvent = [[GrowingEBVCLifeEvent alloc] initWithLifeType:GrowingVCLifeWillDisappear];
        [GrowingEventBus send:lifeEvent];
    });
    
    GrowingAspectBefore(self, vcDidAppear, void , @selector(viewDidAppear:) , (BOOL)animated, {
        delayViewDidAppearRoutineIfNotAllChildrenDidAppear(originInstance);
        
        GrowingEBVCLifeEvent *lifeEvent = [[GrowingEBVCLifeEvent alloc] initWithLifeType:GrowingVCLifeDidAppear];
        [GrowingEventBus send:lifeEvent];
    });

    
    GrowingAspectBefore(self, vcDidDisappear, void , @selector(viewDidDisappear:) , (BOOL)animated , {
        [originInstance GROW_setViewControllerState:GrowingAppearStateDidHide];
        
        GrowingEBVCLifeEvent *lifeEvent = [[GrowingEBVCLifeEvent alloc] initWithLifeType:GrowingVCLifeDidDisappear];
        [GrowingEventBus send:lifeEvent];
    });
}


FoHookInstance(UIViewController, @selector(initWithNibName:bundle:),
               UIViewController*,NSString *nibName,NSBundle *bundle)
{
    self = FoHookOrgin(nibName,bundle);
    if (self)
    {
        growUIViewControllerHookInitObject(self);
    }
    return self;
}
FoHookEnd

FoHookInstance(UIViewController, @selector(initWithCoder:),
               UIViewController*,NSCoder *coder)
{
    self = FoHookOrgin(coder);
    if (self)
    {
        growUIViewControllerHookInitObject(self);
    }
    return self;
}
FoHookEnd

@implementation UIViewController (Growing)

- (BOOL)growingCanBecomeMainPage
{
    return growUIViewControllerShouldTrackAsPage(self);
}


#pragma mark pageName
- (NSString*)GROW_pageName
{
    NSString * pageName = nil;
    NSString * growingAttributesPageName = [self growingAttributesPageName];
    if (growingAttributesPageName.length > 0)
    {
        pageName = growingAttributesPageName;
    }
    else
    {
        pageName = NSStringFromClass(self.class);
    }
    return pageName;
}

- (NSString*)GROW_pageTitle
{
    NSString * currentPageName = self.title;
    if (!currentPageName.length)
    {
        currentPageName = self.navigationItem.title;
    }
    if (!currentPageName.length)
    {
        currentPageName = self.tabBarItem.title;
    }
    return currentPageName;
}





FoPropertyImplementation(NSNumber*, GROW_appearStateV, setGROW_appearStateV)
FoPropertyImplementation(NSNumber*, GROW_createTimestamp, setGROW_createTimestamp)
FoPropertyImplementation(NSNumber*, GROW_lastShowTimestamp, setGROW_lastShowTimestamp)
FoPropertyImplementation(NSNumber*, GROW_lastHideTimestamp, setGROW_lastHideTimestamp)
FoPropertyImplementation(NSNumber*, GROW_pvarCacheTimestamp, setGROW_pvarCacheTimestamp)

#pragma mark - GROW_appearState

- (GrowingAppearState)growingHook_appearState
{
    return self.GROW_appearStateV.integerValue;
}

- (void)setGrowingHook_appearState:(GrowingAppearState)state
{
    GrowingAppearState oldState = self.growingHook_appearState;
    self.GROW_appearStateV = [NSNumber numberWithInteger:state];
    [self GROW_viewControllerStateDidChangeFrom:oldState toState:state];
}

#pragma mark - GROW_isShow

static char GROW_isShow_Key;
- (void)setGROW_isShow:(BOOL)isShow
{
    NSNumber *n = nil;
    if (isShow)
    {
        n = [NSNumber numberWithBool:YES];
    }
    objc_setAssociatedObject(self,
                             &GROW_isShow_Key,
                             n,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    
    if (isShow)
    {
        if (!self.growingHook_isTracked
            && self.isViewLoaded
            && self.view.window
            && !self.view.window.growingNodeIsBadNode)
        {
            self.growingHook_isTracked = @YES;
            [GrowingEventManager shareInstance].inVCLifeCycleSendPageState = YES;
            [self growingTrackSelfPage];
            [GrowingEventManager shareInstance].inVCLifeCycleSendPageState = NO;
        }
    }
    else
    {
        if (self.growingHook_isTracked)
        {
            self.growingHook_isTracked = nil;
        }
    }
}

- (BOOL)GROW_isShow
{
    NSNumber *number = objc_getAssociatedObject(self, &GROW_isShow_Key);
    if (number)
    {
        return number.boolValue;
    }
    else
    {
        return NO;
    }
}

- (void)GROW_viewControllerStateDidChangeFrom:(GrowingAppearState)oldState
                                      toState:(GrowingAppearState)newState
{
    if (!self.growingCanBecomeMainPage)
    {
        
        [self.view.window growingHook_removeVisiableController:self];
        return;
    }
    
    if (newState == GrowingAppearStateDidShow)
    {
        [self.view.window growingHook_addVisiableController:self];
    }
    if (oldState == GrowingAppearStateDidShow)
    {
        [self.view.window growingHook_removeVisiableController:self];
    }
    
}

- (void)GROW_outOfLifetimeShow
{
    self.GROW_lastShowTimestamp = GROWGetTimestamp();
    [self growingTrackSelfPage];
}

- (BOOL)growingHook_isCustomAddVC
{
    return !self.growingHook_hasDidAppear.boolValue
            && self.parentViewController == nil
            && [UIApplication sharedApplication].keyWindow.rootViewController != self;
}

- (void)growingTrackSelfPage
{
    if (![self isViewLoaded] || self.view.window == nil)
    {
        return;
    }
    if ([self.view.window growingHook_curViewController] != self)
    {
        if (g_enableImp && !growUIViewControllerShouldTrackAsPage(self))
        {
            [GrowingImpressionEvent sendEventWithNode:self.view andEventType:GrowingEventTypeUIPageShow];
        }
        return;
    }
    
    if ([[self view] window] == [[UIApplication sharedApplication] growingMainWindow])
    {
        
        [GrowingPageEvent sendEventWithController:self];
        
        if (g_enableImp) {
            [GrowingImpressionEvent sendEventWithNode:[GrowingRootNode rootNode]
                                         andEventType:GrowingEventTypeUIPageShow];
        }
    }
    else
    {
        if (g_enableImp) {
            [GrowingImpressionEvent sendEventWithNode:self.view.window andEventType:GrowingEventTypeUIPageShow];
        }
    }
}

- (void)growingTrackSelfResendPage
{
    
    
    
    
    
    if ([self growingCanResendPage])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self growingCanResendPage])
            {
                [GrowingPageEvent resendEventWithController:self];
                [GrowingJavascriptCore allWebViewExecuteJavascriptMethod:@"_vds_hybrid.resendPage" andParameters:@[@"false"]];
            }
        });
    }
}

- (void)growingTrackSelfSendNewPage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self growingCanResendPage])
        {
            self.GROW_lastShowTimestamp = GROWGetTimestamp();
            [self growingTrackSelfPage];
        }
    });
}

- (void)growingTrackSelfPageOnPSChange
{
    if ([self growingCanResendPage])
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(growingTrackSelfResendPage) object:nil];
            [self performSelector:@selector(growingTrackSelfResendPage) withObject:nil afterDelay:0];
        });
        
    }
}

- (BOOL)growingCanResendPage
{
    return self.growingHook_isTracked
           && self.isViewLoaded
           && self.view.window
           && !self.view.window.growingNodeIsBadNode;
}

- (void)setSubPageName:(NSString *)subPageName
{
    self.growingAttributesSubPageName = subPageName;
}

@end

@implementation UIViewController(Growing_private)




- (void)GROW_setViewControllerState:(GrowingAppearState)newState
{
    static NSMutableArray *weakVCShells;
    if (!weakVCShells)
    {
        weakVCShells = [NSMutableArray arrayWithCapacity:5];
    }
    
    
    if (newState != GrowingAppearStateDidShow)
    {
        [self _GROW_setViewControllerState:newState];
        return;
    }
    
    if (self.view.window)
    {
        [self _GROW_setViewControllerState:newState];
        
        
        NSMutableArray *retrievedVCShells = [NSMutableArray arrayWithCapacity:5];
        for (FoWeakObjectShell *weakVCShell in weakVCShells)
        {
            UIViewController *weakVC = weakVCShell.obj;
            if (weakVC.view.window)
            {
                [retrievedVCShells addObject:weakVCShell];
            }
        }
        
        
        if (retrievedVCShells.count > 0) {
            [weakVCShells removeObjectsInArray:retrievedVCShells];
        }
        
        
        for (FoWeakObjectShell *retrievedVCShell in retrievedVCShells)
        {
            UIViewController *retrievedVC = retrievedVCShell.obj;
            if (retrievedVC.view.window)
            {
                [retrievedVC _GROW_setViewControllerState:GrowingAppearStateDidShow];
            }
        }
        
    }
    else
    {
        FoWeakObjectShell *welf = [FoWeakObjectShell weakObject:self];
        [weakVCShells addObject:welf];
    }
}

- (void)_GROW_setViewControllerState:(GrowingAppearState)newState
{
    if (newState == GrowingAppearStateDidShow) {
        [self setGrowingHook_hasDidAppear:@YES];
    }
    GrowingAppearState oldState = [self growingHook_appearState];
    if (newState == oldState)
    {
        return;
    }
    
    int index = 0;
    NSInteger s          =   1 << index++; 
    NSInteger h          =   1 << index++; 
    
    
    NSInteger didHide    = GrowingAppearStateDidHide      << index;
    NSInteger didShow    = GrowingAppearStateDidShow      << index;
    NSInteger willHide   = GrowingAppearStateWillHide     << index;
    NSInteger willShow   = GrowingAppearStateWillShow     << index;
    NSInteger cancelHide = GrowingAppearStateCancelHide   << index;
    NSInteger cancelShow = GrowingAppearStateCancelShow   << index;
    
    NSInteger actions[GrowingAppearStateCount * GrowingAppearStateCount] = {



    didHide  ,didShow|s, didHide   ,  willShow  ,  didHide   ,   didHide   ,
    didHide|h,didShow  , willHide  ,  didShow   ,  didShow   ,   didShow   ,
    didHide|h,didShow  , willHide  ,  cancelHide,  cancelHide,   cancelShow,
    didHide  ,didShow|s, cancelShow,  willShow  ,  cancelHide,  cancelShow ,
    didHide|h,didShow  , willHide  ,  willShow  ,  cancelHide,  cancelShow ,
    didHide  ,didShow|s, willShow  ,  willShow  ,  cancelHide,  cancelShow
   };
    
    
    NSInteger action = actions[oldState * GrowingAppearStateCount + newState];
    
    GrowingAppearState trueNewState = action >> index;
    self.growingHook_appearState = trueNewState;
    


    
    if (action & s)
    {
        NSNumber *tm = nil;
        if (self.GROW_pvarCacheTimestamp) {
            
            tm = self.GROW_pvarCacheTimestamp;
        } else {
            tm = GROWGetTimestamp();
        }
        
        if (!self.GROW_createTimestamp)
        {
            self.GROW_createTimestamp = tm;
        }
        
        self.GROW_lastShowTimestamp = tm;
        [self setGROW_isShow:YES];
        
        
        
        self.GROW_pvarCacheTimestamp = nil;
    }
    if (action & h)
    {
        NSNumber *tm = GROWGetTimestamp();
        self.GROW_lastHideTimestamp = tm;
        [self setGROW_isShow:NO];
    }
}

- (BOOL)haveAllChildViewControllersSetGrowUIViewControllerShouldTrackAsPage
{
    return haveAllChildViewControllersSetGrowUIViewControllerShouldTrackAsPage(self);
}


- (BOOL)isBigEnoughForAPage
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return YES;
    }
    
    static CGFloat threshold = -1;
    if (threshold < 0)
    {
        CGSize size = [UIScreen mainScreen].bounds.size;
        threshold = size.width * size.height * 0.5;
    }
    CGSize size = self.view.frame.size;
    return size.height * size.width >= threshold;
}

@end
