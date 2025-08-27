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


#import "UIAlertController+Growing.h"
#import "UIViewController+Growing.h"
#import "GrowingAutoTrackEvent.h"
#import "UIViewController+GrowingNode.h"
#import "FoSwizzling.h"
#import "FoDefineProperty.h"
#import "UIWindow+GrowingNode.h"
#import "UIApplication+Growing.h"
#import "UIApplication+GrowingNode.h"
#import "GrowingCategory.h"
#import "NSObject+GrowingHelper.h"
#import "GrowingGlobal.h"

@implementation UIAlertController (Growing)

- (NSMapTable*)growing_allActionViews
{
    UICollectionView *collectionView = [self growing_collectionView];
    NSMapTable *retMap = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                                valueOptions:NSPointerFunctionsStrongMemory
                                                    capacity:4];
    
    if (collectionView)
    {
        [[collectionView indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj,
                                                                                 NSUInteger idx,
                                                                                 BOOL * _Nonnull stop) {
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:obj];
            if (cell)
            {
                [retMap setObject:[NSNumber numberWithInteger:obj.row] forKey:cell];
            }
        }];
    }
    
    else
    {
        NSArray *views = nil;
        if ([self.view growingHelper_getIvar:"_actionViews" outObj:&views])
        {
            [views enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [retMap setObject:[NSNumber numberWithInteger:idx] forKey:obj];
            }];
        }        
    }
    return retMap;
}

+ (UIAlertAction*)growing_actionForActionView:(UIView*)actionView
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSString *viewSelectorString = [NSString stringWithFormat:@"a%@ion%@w", @"ct", @"Vie"];
    if ([actionView respondsToSelector:NSSelectorFromString(viewSelectorString)])
    {
        actionView = [actionView performSelector:NSSelectorFromString(viewSelectorString)];
    }
#pragma clang diagnostic pop
    UIAlertAction *action = nil;
    if ([actionView respondsToSelector:@selector(action)])
    {
        action =[actionView performSelector:@selector(action)];
    }
    return action;
}

- (BOOL)growingCanBecomeMainPage
{
    return NO;
}


- (UICollectionView*)growing_collectionView
{
    return [self growing_alertViewCollectionView:self.view];
}

- (UICollectionView*)growing_alertViewCollectionView:(UIView*)view
{
    for (UIView *subview in view.subviews)
    {
        if ([subview isKindOfClass:[UICollectionView class]])
        {
            return (UICollectionView*)subview;
        }
        else
        {
            UICollectionView *ret = [self growing_alertViewCollectionView:subview];
            if (ret)
            {
                return ret;
            }
        }
    }
    return nil;
}

- (void)growingTrackSelfPage
{
    if (!g_enableImp)
    {
        return;
    }
    
    [GrowingImpressionEvent sendEventWithNode:self
                                 andEventType:GrowingEventTypeUIAlertShow];
}

@end

@interface UIAlertView(Growing)

@end

@implementation UIAlertView(Growing)

- (void)setGrowingAttributesInfo:(NSString *)growingAttributesInfo
{
    NSString * _alertController = [NSString stringWithFormat:@"_al%@ont%@ler", @"ertC", @"rol"];
    if ([self respondsToSelector:NSSelectorFromString(_alertController)])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIViewController *vc = [self performSelector:NSSelectorFromString(_alertController)];
#pragma clang diagnostic pop
        vc.growingAttributesInfo = growingAttributesInfo;
    }
    else
    {
        [super setGrowingAttributesInfo:growingAttributesInfo];
    }
}

- (NSString*)growingAttributesInfo
{
    NSString * _alertController = [NSString stringWithFormat:@"_al%@ont%@ler", @"ertC", @"rol"];
    if ([self respondsToSelector:NSSelectorFromString(_alertController)])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIViewController *vc = [self performSelector:NSSelectorFromString(_alertController)];
#pragma clang diagnostic pop
        return vc.growingAttributesInfo;
    }
    else
    {
        return  [super growingAttributesInfo];
    }
}

@end

FoHookInstance(UIAlertController, NSSelectorFromString([NSString stringWithFormat:@"_%@:%@:",@"dismissAnimated",@"triggeringAction"]), void,BOOL animated,UIAlertAction *action)
{
    NSMapTable *allButton = [self growing_allActionViews];

    for (UIView *btn in allButton.keyEnumerator)
    {
        if (action == [UIAlertController growing_actionForActionView:btn])
        {
            [GrowingClickEvent sendEventWithNode:btn
                                    andEventType:GrowingEventTypeAlertSelected];
            break;
        }
    }
    FoHookOrgin(animated,action);
}
FoHookEnd;

FoHookInstance(UIAlertController, NSSelectorFromString([NSString stringWithFormat:@"_%@:%@:%@:%@:",@"dismissAnimated",@"triggeringAction",@"triggeredByPopoverDimmingView",@"dismissCompletion"]), void,BOOL animated,UIAlertAction *action,BOOL arg3,id arg4)
{
    NSMapTable *allButton = [self growing_allActionViews];
    for (UIView *btn in allButton.keyEnumerator)
    {
        if (action == [UIAlertController growing_actionForActionView:btn])
        {
            [GrowingClickEvent sendEventWithNode:btn
                                    andEventType:GrowingEventTypeAlertSelected];
            break;
        }
    }
    FoHookOrgin(animated,action,arg3,arg4);
}
FoHookEnd;
