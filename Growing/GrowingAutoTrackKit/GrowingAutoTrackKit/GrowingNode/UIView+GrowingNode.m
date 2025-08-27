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


#import "UIView+GrowingNode.h"
#import "UIWindow+Growing.h"
#import "UIView+GrowingHelper.h"
#import "UIApplication+GrowingNode.h"
#import "FoDefineProperty.h"
#import "UITapGestureRecognizer+GrowingHook.h"
#import "UIImage+GrowingHelper.h"
#import "FoWeakObjectShell.h"

@interface GrowingMaskView : UIImageView
@end

@implementation GrowingMaskView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView * hit = [super hitTest:point withEvent:event];
    return (hit == self) ? nil : hit;
}


@end

FoPropertyDefine(UIView, GrowingMaskView*, growingHighlightView, setGrowingHighlightView)

@implementation UIView(Growing_xPath)

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
    return [fullScreenImage growingHelper_getSubImage:[self growingNodeFrame]];
}

- (UIImage*)growingNodeScreenShotWithScale:(CGFloat)maxScale
{
    return [self growingHelper_screenshot:maxScale];
}

- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs outPaths:(NSMutableArray *)paths filterChildNode:(id<GrowingNode>)aNode
{
    
}

- (void)growingNodeOutChilds:(NSMutableArray *)childs
                    outPaths:(NSMutableArray *)paths
             filterChildNode:(id<GrowingNode>)aNode
{
    UIWindow * curWindow = [self growingNodeWindow];
    
    NSArray *subviewArr = self.subviews;

    NSUInteger i = 0;
    for (UIView * v in subviewArr)
    {
        if ([v.nextResponder isKindOfClass:[UIViewController class]])
        {
            UIViewController *vc = (id)v.nextResponder;
            
            BOOL containsVC = NO;
            for (FoWeakObjectShell *obj in [curWindow growingHook_curViewControllers]) {
                if (obj.obj == vc) {
                    containsVC = YES;
                    break;
                }
            }
            
            if (!containsVC)
            {
                
                GrowingAddChildNode(vc,
                                    (NSStringFromClass(vc.class), i));
                i++;
            }
            else
            {
                
                GrowingAddChildNode(vc,
                                    (@"invisiablePath"));
            }
            
        }
        else
        {
            GrowingAddChildNode(v,
                                (NSStringFromClass(v.class), i));
            i++;
        }
    }
}

- (void)growingNodeHighLight:(BOOL)highLight
             withBorderColor:(UIColor *)borderColor
          andBackgroundColor:(UIColor *)backgroundColor

{
    if (highLight)
    {
        GrowingMaskView *maskView =  nil;
        if (!self.growingHighlightView)
        {
            maskView = [[GrowingMaskView alloc] initWithFrame:self.bounds];
            maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            maskView.contentMode = UIViewContentModeScaleToFill;
            maskView.growingAttributesDonotTrack = YES;
            [self addSubview:maskView];
            self.growingHighlightView = maskView;
        }
        else
        {
            maskView = self.growingHighlightView;
        }
        
        if ([backgroundColor isKindOfClass:[UIImage class]])
        {
            
            maskView.image = (UIImage*)backgroundColor;
            maskView.layer.borderWidth = 0;
            maskView.layer.borderColor = nil;
            maskView.backgroundColor = nil;
            maskView.layer.cornerRadius = 0;
        }
        else
        {
            maskView.image = nil;
            maskView.layer.borderWidth = 1;
            maskView.layer.borderColor = borderColor.CGColor;
            maskView.backgroundColor = backgroundColor;
            maskView.layer.cornerRadius = MIN(10, MIN(self.bounds.size.width,self.bounds.size.height) / 4);
        }
    }
    else
    {
        GrowingMaskView *maskView = self.growingHighlightView;
        if (maskView)
        {
            [maskView removeFromSuperview];
            self.growingHighlightView = nil;
        }
    }
}

- (CGRect)growingNodeFrame
{
    UIWindow *mainWindow = [[UIApplication sharedApplication] growingMainWindow];
    UIWindow *parentWindow = self.window;
    
    CGRect frame = [self convertRect:self.bounds toView:parentWindow];
    if (mainWindow == parentWindow)
    {
        return frame;
    }
    else
    {
        return [parentWindow convertRect:frame toWindow:mainWindow];
    }
}

- (id<GrowingNode>)growingNodeParent
{
    if ([self.nextResponder isKindOfClass:[UIViewController class]])
    {
        return (id)self.nextResponder;
    }
    else
    {
        
        return (id)self.superview;
    }
}

- (BOOL)growingViewNodeIsInvisiable
{
    return (self.hidden
            || self.alpha < 0.001
            || !self.superview 
            || self.growingNodeIsBadNode
            || !self.window);
}

- (BOOL)growingImpNodeIsVisible
{
    if (self.window && !self.hidden && self.alpha >= 0.001 && self.superview) {
        BOOL isInScreen;
        CGRect rect = [self growingNodeFrame];
        CGRect intersectionRect = CGRectIntersection([UIScreen mainScreen].bounds, rect);
        if (CGRectIsEmpty(intersectionRect) || CGRectIsNull(intersectionRect)) {
            isInScreen = NO;
        } else {
            if (self.growingImpScale == 0.0) {
                isInScreen = YES;
            } else {
                
                
                
                
                if (ceilf(intersectionRect.size.width * intersectionRect.size.height) >= self.bounds.size.width * self.bounds.size.height * self.growingImpScale) {
                    isInScreen = YES;
                } else {
                    isInScreen = NO;
                }
            }
        }
        
        if (!isInScreen) {
            return NO;
        } else {
            UIResponder *curNode = self.nextResponder;
            while (curNode) {
                if (!curNode.isProxy && [curNode isKindOfClass:[UIView class]]) {
                    if ( ((UIView *)curNode).hidden == YES || ((UIView *)curNode).alpha < 0.001 ) {
                        return NO;
                    }
                }
                curNode = curNode.nextResponder;
            }
            return YES;
        }
    } else {
        return NO;
    }
    
}




- (BOOL)growingNodeDonotTrack
{
    return [self growingViewNodeIsInvisiable]
            || self.growingAttributesDonotTrack;
}

- (BOOL)growingNodeDonotTrackImp
{
    return self.growingAttributesDonotTrackImp;
}

- (BOOL)growingNodeDonotCircle
{
    return [self growingViewNodeIsInvisiable];
}


- (NSString*)growingNodeName
{
    return NSStringFromClass(self.class);
}

- (NSString*)growingViewContent
{
    
    NSString *className = NSStringFromClass(self.class);
    NSString *prefixString = @"UIPicke";
    NSString *suffixString = @"rTableView";
    if ([className hasPrefix:prefixString] && [className hasSuffix:suffixString] && className.length == (prefixString.length + suffixString.length)) {
        return nil;
    } else {
        
        
        NSString *accessibilityLabel = nil;
        @try {
            accessibilityLabel = self.accessibilityLabel;
        } @catch (NSException *exception) {
            accessibilityLabel = nil;
        } @finally {
            
        }
        return accessibilityLabel;
    }
}

- (NSString*)growingNodeContent
{
    NSString *attrContent = self.growingAttributesValue;
    if ([attrContent isKindOfClass:[NSString class]]
        && attrContent.length)
    {
        return attrContent;
    }
    
    NSString *viewContent = self.growingViewContent;
    if ([viewContent isKindOfClass:[NSString class]]
        && viewContent.length)
    {
        return viewContent;
    }
    
    return nil;
}

- (BOOL)growingNodeUserInteraction
{
    return self.userInteractionEnabled
           && ([self growingViewUserInteraction]
               || [UITapGestureRecognizer growingGestureRecognizerCanHandleView:self]);
}

- (BOOL)growingViewUserInteraction
{
    return NO;
}

- (NSDictionary*)growingNodeDataDict
{
    return nil;
}

- (UIWindow*)growingNodeWindow
{
    return self.window;
}

- (id<GrowingNode>)growingNodeAttachedInfoNode
{
    return [self growingNodeParent];
}

- (id<GrowingNodeAsyncNativeHandler>)growingNodeAsyncNativeHandler
{
    return nil;
}

#pragma mark GrowingAttributes

static char UIView_GrowingAttributes_donottrack_key;
static char UIView_GrowingAttributes_donottrackimp_key;
static char UIView_GrowingAttributes_donottrackValue_key;
static char UIView_growingAttributes_value_key;
static char UIView_GrowingIMPTrack_isTracked_key;
static char UIView_GrowingIMPTrack_eventId_key;
static char UIView_GrowingIMPTrack_variable;
static char UIView_GrowingIMPTrack_number;

- (void)setGrowingAttributesDonotTrackImp:(BOOL)growingAttributesDonotTrackImp
{
    objc_setAssociatedObject(self,
                             &UIView_GrowingAttributes_donottrackimp_key,
                             growingAttributesDonotTrackImp ? @YES : nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)growingAttributesDonotTrackImp
{
    return objc_getAssociatedObject(self, &UIView_GrowingAttributes_donottrackimp_key) ? YES : NO;
}


- (void)setGrowingAttributesDonotTrack:(BOOL)growingAttributesDonotTrack
{
    objc_setAssociatedObject(self,
                             &UIView_GrowingAttributes_donottrack_key,
                             growingAttributesDonotTrack ? @YES : nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)growingAttributesDonotTrack
{
    return objc_getAssociatedObject(self, &UIView_GrowingAttributes_donottrack_key) ? YES : NO;
}

- (void)setGrowingAttributesDonotTrackValue:(BOOL)growingAttributesDonotTrackValue
{
    objc_setAssociatedObject(self, &UIView_GrowingAttributes_donottrackValue_key, [NSNumber numberWithBool:growingAttributesDonotTrackValue], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)growingAttributesDonotTrackValue
{
    return [objc_getAssociatedObject(self, &UIView_GrowingAttributes_donottrackValue_key) boolValue];
}

- (NSNumber *)growingAttributesDonotTrackValueObject
{
    return objc_getAssociatedObject(self, &UIView_GrowingAttributes_donottrackValue_key);
}

- (NSString *)growingAttributesValue {
    return objc_getAssociatedObject(self, &UIView_growingAttributes_value_key);
}

- (void)setGrowingAttributesValue:(NSString *)value {
    if ([value isKindOfClass:[NSNumber class]])
    {
        value = [(NSNumber *)value stringValue];
    }
    if (![value isKindOfClass:[NSString class]])
    {
        value = nil;
    }
    if (value.length > 50)
    {
        value = [value substringToIndex:50];
    }
    objc_setAssociatedObject(self, &UIView_growingAttributes_value_key, value, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
}

- (BOOL)growingIMPTracked
{
    return [objc_getAssociatedObject(self, &UIView_GrowingIMPTrack_isTracked_key) boolValue];
}

- (void)setGrowingIMPTracked:(BOOL)flag
{
    objc_setAssociatedObject(self, &UIView_GrowingIMPTrack_isTracked_key, [NSNumber numberWithBool:flag], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)growingIMPTrackEventId
{
    return objc_getAssociatedObject(self, &UIView_GrowingIMPTrack_eventId_key);
}

- (void)setGrowingIMPTrackEventId:(NSString *)eventId
{
    objc_setAssociatedObject(self, &UIView_GrowingIMPTrack_eventId_key, eventId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)growingIMPTrackVariable
{
    return objc_getAssociatedObject(self, &UIView_GrowingIMPTrack_variable);
}

- (void)setGrowingIMPTrackVariable:(NSDictionary *)variable
{
    objc_setAssociatedObject(self, &UIView_GrowingIMPTrack_variable, variable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)growingIMPTrackNumber
{
    return objc_getAssociatedObject(self, &UIView_GrowingIMPTrack_number);
}

- (void)setGrowingIMPTrackNumber:(NSNumber *)number
{
    objc_setAssociatedObject(self, &UIView_GrowingIMPTrack_number, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



FoSafeStringPropertyImplementation(growingAttributesInfo, setGrowingAttributesInfo)
FoSafeStringPropertyImplementation(growingAttributesUniqueTag, setGrowingAttributesUniqueTag)
FoPropertyImplementation(NSArray *, growingSDCycleBannerIds, setGrowingSDCycleBannerIds)

@end
