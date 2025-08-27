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


#import "UIWindow+Growing.h"
#import <objc/runtime.h>
#import "GrowingInstance.h"
#import "UIView+Growing.h"
#import "FoSwizzling.h"
#import "FoDefineProperty.h"
#import "FoObjectSELObserver.h"
#import "UIViewController+Growing.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "GrowingNodeManager.h"
#import "FoWeakObjectShell.h"
#import "GrowingAspect.h"













@interface GrowingKeyboardWindowObserver : NSObject

@end

@implementation GrowingKeyboardWindowObserver

+ (void)startObserver
{
    [self shareInstance];
}

+ (instancetype)shareInstance
{
    static id obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowDidShow:)
                                                     name:UIWindowDidBecomeVisibleNotification
                                                   object:nil];
    }
    return self;
}

- (BOOL)checkWindowPassable:(UIWindow*)window
{
    CGPoint point = window.bounds.origin;
    CGSize size = window.bounds.size;
    size.width -= 2;
    size.height -= 2;
    
    BOOL hitAble =
    [window hitTest:point withEvent:nil]
    && [window hitTest:CGPointMake(point.x + size.width, point.y) withEvent:nil]
    && [window hitTest:CGPointMake(point.x, point.y + size.height) withEvent:nil]
    && [window hitTest:CGPointMake(point.x + size.width, point.y + size.height) withEvent:nil];
    
    return !hitAble;
}

- (void)windowDidShow:(NSNotification*)noti
{
    UIWindow *window = noti.object;
    if ([self checkWindowPassable:window])
    {
        window.growingNodeIsBadNode = YES;
    }
}

@end


static __attribute__((constructor)) void GrowingKeyboardWindowObserverAutoRun()
{
    [GrowingKeyboardWindowObserver startObserver];
}

@implementation UIWindow (Growing)

FoPropertyImplementation(UIViewController*, growingHook_setRootViewController, setGrowingHook_setRootViewController)
FoPropertyImplementation(NSNumber*, growingHook_setNeedUpdateVisiableVC, setGrowingHook_setNeedUpdateVisiableVC)
FoPropertyImplementation(NSArray*, growingHook_curViewControllersVar, setGrowingHook_curViewControllersVar)


- (NSNumber *)GROW_timestamp {
    static char __GROWUIWindowTimestampKey;
    
    NSNumber *t = objc_getAssociatedObject(self, &__GROWUIWindowTimestampKey);
    if (!t) {
        t = GROWGetTimestamp();
        objc_setAssociatedObject(self,
                                 &__GROWUIWindowTimestampKey,
                                 t,
                                 OBJC_ASSOCIATION_RETAIN);
    }
    return t;
}

- (NSMutableArray<FoWeakObjectShell*>*)growingHook_didAppearVCShells
{
    static char growingHook_didAppearVCs_key;
    NSMutableArray *arr = objc_getAssociatedObject(self, &growingHook_didAppearVCs_key);
    if (!arr)
    {
        arr = [[NSMutableArray alloc] initWithCapacity:5];
        objc_setAssociatedObject(self, &growingHook_didAppearVCs_key, arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return arr;
}

- (void)growingHook_addVisiableController:(UIViewController *)aVC
{
    FoWeakObjectShell *weakObj = [[FoWeakObjectShell alloc] init];
    weakObj.obj = aVC;
    [[self growingHook_didAppearVCShells] addObject:weakObj];
    
    [self growingHook_setNeedUpdateCurViewControllers];
}

- (void)growingHook_removeVisiableController:(UIViewController *)aVC
{    
    NSMutableArray<FoWeakObjectShell*> *arr = [self growingHook_didAppearVCShells];
    for (NSUInteger i = 0 ; i < arr.count ; i ++)
    {
        if (arr[i].obj == aVC)
        {
            [arr removeObjectAtIndex:i];
            break;
        }
    }
    
    [self growingHook_setNeedUpdateCurViewControllers];
    
    
    NSString *aString = NSStringFromClass([aVC class]);
    if ([aString isEqualToString:@"UIApplicationRotationFollowingController"]
        ||([aString rangeOfString:@"_UIAlertShimPres"].location != NSNotFound)
        ||[aString isEqualToString:@"UIAlertController"]){
        return;
    }
    
    NSMutableArray *vcArray = [[NSMutableArray alloc] initWithArray:self.growingHook_curViewControllersVar];
    for (NSUInteger i = 0; i < vcArray.count; i++)
    {
        FoWeakObjectShell *obj = vcArray[i];
        if(obj.obj == aVC)
        {
            [vcArray removeObjectAtIndex:i];
            break;
        }
    }
    
    [self setGrowingHook_curViewControllersVar:vcArray];
}

- (void)growingHook_setNeedUpdateCurViewControllers
{
    self.growingHook_setNeedUpdateVisiableVC = @YES;
}

- (NSArray<FoWeakObjectShell *> *)growingHook_curViewControllers
{
    [self growingHook_updateVisiableVC];
    return self.growingHook_curViewControllersVar;
}

- (UIViewController*)growingHook_curViewController
{
    FoWeakObjectShell *obj = self.growingHook_curViewControllers.lastObject;
    return obj.obj;
}

- (BOOL)_growingHook_isVisiableVC:(UIViewController*)vc
{
    return [vc isViewLoaded] && vc.view.alpha > 0.01 && !vc.view.hidden;
}

- (void)growingHook_updateVisiableVC
{
    if (!self.growingHook_setNeedUpdateVisiableVC.boolValue)
    {
        return;
    }
    self.growingHook_setNeedUpdateVisiableVC = nil;
    
    NSMutableArray *allVCs = [[NSMutableArray alloc] init];
    [[self growingHook_didAppearVCShells] enumerateObjectsUsingBlock:^(FoWeakObjectShell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIViewController *vc = obj.obj;
        if (vc && [vc growingCanBecomeMainPage])
        {
            [allVCs addObject:obj];
        }
    }];
    
    UIViewController *curVC = nil;
    for (NSInteger i = allVCs.count - 1 ; i >=0 ; i --)
    {
        FoWeakObjectShell *obj = allVCs[i];
        UIViewController *vc = obj.obj;
        if (vc.growingHook_appearState == GrowingAppearStateDidShow
            && [self _growingHook_isVisiableVC:vc])
        {
            curVC = vc;
            
            if ([curVC.view.superview isKindOfClass:[UIScrollView class]])
            {
                [self growingHook_setNeedUpdateCurViewControllers];
                UIScrollView *scroll = (UIScrollView *)curVC.view.superview ;
                if (curVC.view.frame.origin.x != scroll.contentOffset.x)
                {
                    continue ;
                }
            }
            
            NSArray *allChild = vc.childViewControllers;
            for (NSInteger j = 0 ; j < allChild.count ; j ++)
            {
                UIViewController *childVC = allChild[j];
                if (![self _growingHook_isVisiableVC:childVC])
                {
                    continue;
                }
                if (![childVC growingCanBecomeMainPage])
                {
                    continue;
                }
                if (childVC.growingHook_appearState != GrowingAppearStateDidHide)
                {
                    curVC = nil;
                    break;
                }
            }
        }
        if (curVC)
        {
            break;
        }
    }
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    UIView *curView = curVC.view;
    while (curView)
    {
        if ([curView.nextResponder isKindOfClass:[UIViewController class]])
        {
            FoWeakObjectShell *obj = [[FoWeakObjectShell alloc] init];
            obj.obj = curView.nextResponder;
            [arr insertObject:obj atIndex:0];
        }
        curView = curView.superview;
    }
    [self setGrowingHook_curViewControllersVar:arr];
}

@end
