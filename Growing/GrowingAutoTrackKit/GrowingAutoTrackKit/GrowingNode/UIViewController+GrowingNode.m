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


#import "UIViewController+GrowingNode.h"
#import "UIWindow+Growing.h"
#import "UIView+GrowingHelper.h"
#import "UIViewController+Growing.h"
#import "UIImage+GrowingHelper.h"
#import "GrowingAutoTrackEvent.h"
#import "GrowingManualTrackEvent.h"
#import "FoDefineProperty.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingMobileDebugger.h"
#import "UIView+GrowingNode.h"
#import "GrowingGlobal.h"
#import "FoWeakObjectShell.h"

@implementation UIViewController(Growing_xPath)

- (id)growingNodeAttribute:(NSString *)attrbute forChild:(id<GrowingNode>)node
{
    return nil;
}

- (id)growingNodeAttribute:(NSString *)attrbute
{
    return nil;
}

- (UIImage*)growingNodeScreenShot:(UIImage *)fullScreenImage
{
    return [fullScreenImage growingHelper_getSubImage:[self.view growingNodeFrame]];
}

- (UIImage*)growingNodeScreenShotWithScale:(CGFloat)maxScale
{
    return [self.view growingHelper_screenshot:maxScale];
}

- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs outPaths:(NSMutableArray *)paths filterChildNode:(id<GrowingNode>)aNode
{
    if (![self isViewLoaded] || !self.view.window)
    {
        return;
    }
    NSArray *vcs = [self.view.window growingHook_curViewControllers];
    
    __block NSInteger index = NSNotFound;
    [vcs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (((FoWeakObjectShell *)obj).obj == self) {
            index = idx;
            *stop = YES;
        }
    }];
    
    if (vcs.count && index >= 0 && index < vcs.count - 1)
    {
        FoWeakObjectShell *obj = vcs[index + 1];
        id<GrowingNode> node = obj.obj;
        GrowingAddChildNode(node,
                            (NSStringFromClass([node class])));
    }
}


- (void)growingNodeOutChilds:(NSMutableArray *)childs outPaths:(NSMutableArray *)paths filterChildNode:(id<GrowingNode>)aNode
{
    if (![self isViewLoaded] || !self.view.window)
    {
        return;
    }
    
    
    
    
    
    
    if (self.parentViewController
        && ![self.parentViewController isKindOfClass:[UINavigationController class]]
        && ![self.parentViewController isKindOfClass:[UITabBarController class]]) {
        UIResponder *curNode = self.nextResponder;
        while (curNode) {
            if (curNode == self.view.window) {
                break;
            }
            if (!curNode.isProxy && [curNode isKindOfClass:[UIView class]]) {
                if (((UIView *)curNode).isHidden || ((UIView *)curNode).alpha < 0.001) {
                    return;
                }
            }
            curNode = curNode.nextResponder;
        }
    }
    
    GrowingAddChildNode(self.view,
                        (NSStringFromClass(self.view.class)));
}

- (void)growingNodeHighLight:(BOOL)highLight
             withBorderColor:(UIColor *)borderColor
          andBackgroundColor:(UIColor *)backgroundColor
{
    
}

- (CGRect)growingNodeFrame
{
    return CGRectZero;
}



- (id<GrowingNode>)growingNodeParent
{
    if (![self isViewLoaded])
    {
        return nil;
    }

    return self.view.superview;

}

- (BOOL)growingAppearStateCanTrack
{
    GrowingAppearState curState = self.growingHook_appearState;
    if (curState == GrowingAppearStateDidShow)
    {
        return YES;
    }
    
    if ([self growingHook_isCustomAddVC])
    {
        return YES;
    }
    return NO;
}

#define DonotrackCheck(theCode) if (theCode) { return YES;}

- (BOOL)growingNodeDonotTrack
{
    DonotrackCheck (![self isViewLoaded])
    DonotrackCheck (!self.view.window)
    DonotrackCheck (self.view.window.growingNodeIsBadNode)
    DonotrackCheck (self.growingNodeIsBadNode)
    DonotrackCheck (![self growingAppearStateCanTrack])
    return NO;
}


- (BOOL)growingNodeDonotTrackImp
{
    return NO;
}
- (BOOL)growingNodeDonotCircle
{
    return NO;
}

- (BOOL)growingNodeUserInteraction
{
    return NO;
}

- (NSString*)growingNodeName
{
    return @"页面";
}

- (NSString*)growingNodeContent
{
    return self.accessibilityLabel;
}

- (NSDictionary*)growingNodeDataDict
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"p"] = (self.GROW_pageName ?: nil);
    dict[@"ptm"] = (self.GROW_lastShowTimestamp ?: nil);
    dict[@"pg"] = (self.growingAttributesPageGroup ?: nil);
    
    return dict;
}

- (UIWindow*)growingNodeWindow
{
    return self.view.window;
}

- (id<GrowingNode>)growingNodeAttachedInfoNode
{
    return nil;
}

- (id<GrowingNodeAsyncNativeHandler>)growingNodeAsyncNativeHandler
{
    return nil;
}

@end

@implementation UIViewController(GrowingAttributes)

FoSafeStringPropertyImplementation(growingAttributesPageName, setGrowingAttributesPageName)
FoSafeStringPropertyImplementation(growingAttributesInfo, setGrowingAttributesInfo)


static char __theClass__growingAttributesPageGroup_key;
- (void)setGrowingAttributesSubPageName:(NSString *)value
{
    if ([value isKindOfClass:[NSNumber class]])
    {
        value = [(NSNumber *)value stringValue];
    }
    if (![value isKindOfClass:[NSString class]])
    {
        value = nil;
    }
    
    
    [self growingPGWillChangeFrom:self.growingAttributesPageGroup to:value];
    
    objc_setAssociatedObject(self,
                             &__theClass__growingAttributesPageGroup_key,
                             value,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)growingAttributesPageGroup
{
    return objc_getAssociatedObject(self,&__theClass__growingAttributesPageGroup_key);
}

- (void)growingPGWillChangeFrom:(NSString*)oldPG to:(NSString *)newPG
{
    if (newPG.length != 0)
    {
        if (oldPG.length == 0)
        {
            [self growingTrackSelfResendPage];
        }
        else
        {
            if (![oldPG isEqualToString:newPG])
            {
                [self growingTrackSelfSendNewPage];
            }
        }
    }
}

- (void)mergeGrowingAttributesPvar:(NSDictionary<NSString *, NSObject *> *)growingAttributesPvar
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:growingAttributesPvar];
    if (dict.count > 100 || dict.count == 0) {
        NSLog(parameterValueErrorLog);
        return ;
    }
    
    if (growingAttributesPvar.count != 0 ) {
        [[GrowingMobileDebugger shareDebugger] cacheValue:growingAttributesPvar ofType:NSStringFromClass([self class])];
    }
    
    BOOL somethingWasChange = [self.growingAttributesMutablePvar mergeGrowingAttributesVar:growingAttributesPvar];
    if (somethingWasChange)
    {
        [self sendPvarEvent];
    }
}

- (void)removeGrowingAttributesPvar:(NSString *)key
{
    [self.growingAttributesMutablePvar removeGrowingAttributesVar:key];
}

- (NSMutableDictionary<NSString *, NSObject *> *)growingAttributesMutablePvar
{
    static char __theClass__growingAttributesPvar_key;
    NSMutableDictionary<NSString *, NSObject *> * pvar = objc_getAssociatedObject(self,&__theClass__growingAttributesPvar_key);
    if (pvar == nil)
    {
        pvar = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self,
                                 &__theClass__growingAttributesPvar_key,
                                 pvar,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return pvar;
}

- (NSDictionary<NSString *, NSObject *> *)growingAttributesPvar
{
    return [[self growingAttributesMutablePvar] copy];
}

- (void)sendPvarEvent
{
    [NSObject cancelPreviousPerformRequestsWithTarget:[GrowingPvarEvent class]
                                             selector:@selector(sendPvarEvent:)
                                               object:self];
    [[GrowingPvarEvent class] performSelector:@selector(sendPvarEvent:)
                                   withObject:self
                                   afterDelay:0];
}

@end
