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


#import "ReactNative+GrowingNode.h"
#import "ReactNative+Growing.h"
#import "UIView+GrowingNode.h"
#import "GrowingNode.h"
#import "NSObject+GrowingIvarHelper.h"
#import <objc/runtime.h>
#import "FoSwizzling.h"
#import <objc/Message.h>





static BOOL _RCTView_growingNodeUserInteraction(UIView * _self, SEL _cmd)
{
    NSNumber * isClickable = _self.growingRnClickable;
    BOOL userInteraction = isClickable != nil && [isClickable boolValue];
    
    if (userInteraction && CGRectEqualToRect(_self.frame, [UIScreen mainScreen].bounds)) {
        UIResponder *responder = _self.nextResponder;
        int i = 0;
        while (responder) {
            if (![responder isKindOfClass:[UIResponder class]]) {
                break;
            }
            if (i > 5) {
                break;
            }
            if ([responder isKindOfClass:[UIViewController class]] && i==5) {
                userInteraction = NO;
                break;
            }
            responder = responder.nextResponder;
            i++;
        }
    }
    return userInteraction;
}























































static void _RCTView_growingNodeOutContainerChilds_outPaths_filterChildNode(UIView * _self, SEL _cmd, NSMutableArray * childs, NSMutableArray * paths, id<GrowingNode> aNode)
{
    typedef void (*SuperMethodFunc)(UIView *, SEL, id, id, id);
    static SuperMethodFunc superMethod = nil;
    static Class RCTViewClass = nil;
    if (RCTViewClass == nil)
    {
        RCTViewClass = NSClassFromString(@"RCTView");
        superMethod = (SuperMethodFunc)class_getMethodImplementation(UIView.class, @selector(growingNodeOutContainerChilds:outPaths:filterChildNode:));
    }
    
    superMethod(_self, _cmd, childs, paths, aNode);
    
    NSString *superClassString = NSStringFromClass(_self.superview.class);
    if (![superClassString isEqualToString:@"RCTCustomScrollView"]) {
        return;
    }
    if (![_self respondsToSelector:@selector(reactZIndexSortedSubviews)]) {
        return;
    }
    
    [_self performSelector:@selector(reactZIndexSortedSubviews)];
    
    if (![_self respondsToSelector:@selector(reactSubviews)]) {
        return;
    }
    
    NSArray *allSubViews = [_self performSelector:@selector(reactSubviews)];
    NSArray *subViews = _self.subviews;
    for (UIView *v in subViews) {
        GrowingAddChildNode(v, (NSStringFromClass(v.class), [allSubViews indexOfObject:v]));
    }
}




static NSString * _RCTText_growingViewContent(UIView * _self, SEL _cmd)
{
    NSTextStorage * textStorage = nil;
    if ([_self growingHelper_getIvar:"_textStorage" outObj:&textStorage] && textStorage)
    {
        return textStorage.string;
    }
    return nil;
}




static NSString * _RCTTextView_growingViewContent(UIView * _self, SEL _cmd)
{
    NSTextStorage * textStorage = nil;
    if ([_self growingHelper_getIvar:"_textStorage" outObj:&textStorage] && textStorage)
    {
        return textStorage.string;
    }
    return nil;
}

void loadAllReactNativeNodeMethod()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class RCTViewClass = NSClassFromString(@"RCTView");
        if (RCTViewClass != nil) {
            
            class_addMethod(RCTViewClass, @selector(growingNodeUserInteraction), (IMP)_RCTView_growingNodeUserInteraction, "B@:");
            

            
            class_addMethod(RCTViewClass, @selector(growingNodeOutContainerChilds:outPaths:filterChildNode:), (IMP)_RCTView_growingNodeOutContainerChilds_outPaths_filterChildNode, "v@:@@@");
            
        }
        
        Class RCTTextClass = NSClassFromString(@"RCTText");
        Class RCTTextViewClass = NSClassFromString(@"RCTTextView");
        if (RCTTextClass != nil) {
            
            class_addMethod(RCTTextClass, @selector(growingViewContent), (IMP)_RCTText_growingViewContent, "@@:");
        } else if (RCTTextViewClass != nil) {
            
            class_addMethod(RCTTextViewClass, @selector(growingViewContent), (IMP)_RCTTextView_growingViewContent, "@@:");
        }
    });
}

FoHookInstance(UIView, @selector(growingViewContent), NSString *)
{
    
    return nil;
}
FoHookEnd


FoHookInstance(UIView, @selector(growingNodeUserInteraction), BOOL)
{
    if ([self.nextResponder isKindOfClass:NSClassFromString(@"RCCDrawerController")]) {
        return NO;
    }
    return FoHookOrgin();
}
FoHookEnd
