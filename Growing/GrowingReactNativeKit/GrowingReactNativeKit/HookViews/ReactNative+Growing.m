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


#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "ReactNative+Growing.h"
#import "FoSwizzling.h"
#import "GrowingInstance.h"
#import "FoDefineProperty.h"
#import "ReactNative+GrowingNode.h"
#import "UIView+GrowingNode.h"
#import "GrowingEventManager.h"
#import "metamacros.h"
#import "UIApplication+GrowingNode.h"
#import "UIWindow+Growing.h"
#import "GrowingGlobal.h"
#import "GrowingAutoTrackEvent.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingMobileDebugger.h"
#import "GrowingReactNativeEvent.h"
#import "GrowingDispatchManager.h"

#define KEY_CLICKABLE @"clickable"
#define KEY_PARAMETERS @"parameters"



static NSMutableDictionary *pagePageVariableDict = nil;

static NSMutableDictionary *unsendPagePageVariableDict = nil;

#pragma mark GrowingIO React Native Environment

@implementation GrowingReactNativeEnvironment


static NSString * currentPageName = nil;
static NSString * currentWillFocusPageId = nil;
static NSString * currentDidFocusPageId = nil;
static BOOL isTransitioning = NO;

+ (NSString *)currentPageName
{
    return currentPageName;
}

+ (void)setCurrentPageName:(NSString *)pageName
{
    currentPageName = pageName;
}

+ (NSString *)currentWillFocusPageId
{
    return currentWillFocusPageId;
}

+ (void)setCurrentWillFocusPageId:(NSString *)pageId
{
    currentWillFocusPageId = pageId;
}

+ (NSString *)currentDidFocusPageId
{
    return currentDidFocusPageId;
}

+ (void)setCurrentDidFocusPageId:(NSString *)pageId
{
     currentDidFocusPageId = pageId;
}

+ (BOOL)isTransitioning
{
    return isTransitioning;
}

+ (void)setIsTransitioning:(BOOL)isTrans
{
    isTransitioning = isTrans;
}
@end


static NSMutableDictionary<NSNumber *, NSDictionary *> * toBeCreatedTags = nil; 
static NSMapTable<NSNumber *, UIView *> * allReactNativeViews = nil; 



#pragma mark UIView attached flag: growingRnClickable

@implementation UIView (ReactNative_Growing)

FoPropertyImplementation(NSNumber *, growingRnIsClickable, growingRnSetClickable)
FoPropertyImplementation(NSString *, growingRnPageId, growingRnSetPageId)
FoPropertyImplementation(NSDictionary *, growingRnParameters, growingRnSetParameters)

@end


#pragma mark React Native hook points and init

void growingInitReactNativeJSContext(NSObject  * self)
{
    [GrowingDispatchManager dispatchInMainThread:^{
        if (toBeCreatedTags == nil)
        {
            toBeCreatedTags = [[NSMutableDictionary alloc] init];
        }
        if (allReactNativeViews == nil)
        {
            allReactNativeViews = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                                            valueOptions:NSPointerFunctionsWeakMemory
                                                                capacity:100 ];
        }
    }];
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstancePlus("RCTCxxBridge", NSObject *, @selector(executeSourceCode:sync:),
                   void, NSData * script, BOOL sync)
#pragma clang diagnostic pop
{
    
    growingInitReactNativeJSContext(self); 
    
    FoHookOrgin(script, sync);
}
FoHookEnd


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstancePlus("RNGestureHandler", NSObject *, @selector(handleGesture:), void, UIGestureRecognizer *recognizer)
#pragma clang diagnostic pop
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            GrowingReactNativeEnvironment.isTransitioning = NO;
            break;
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateChanged:
        default:
            GrowingReactNativeEnvironment.isTransitioning = YES;
            
    }
    FoHookOrgin(recognizer);

}
FoHookEnd

#pragma mark React Native set view props
void prepareViewProps(UIView* view, NSNumber * tag) {
    NSNumber * isClickable = nil;
    NSDictionary * parameters = nil;
    if (tag != nil && toBeCreatedTags[tag] != nil)
    {
        
        NSDictionary * info = toBeCreatedTags[tag];
        isClickable = info[KEY_CLICKABLE];
        parameters = info[KEY_PARAMETERS];
        
        if (   [parameters[@"ignore"] isKindOfClass:[NSString class]]
            && [parameters[@"ignore"] isEqualToString:@"true"]) 
        {
            view.growingAttributesDonotTrack = YES;
        }
        if (parameters[@"id"] != nil && [parameters[@"id"] isKindOfClass:[NSString class]])
        {
            view.growingAttributesUniqueTag = parameters[@"id"];
        }
        if (parameters[@"content"] != nil && [parameters[@"content"] isKindOfClass:[NSString class]])
        {
            view.growingAttributesValue = parameters[@"content"];
        }
        if (parameters[@"info"] != nil && [parameters[@"info"] isKindOfClass:[NSString class]])
        {
            view.growingAttributesInfo = parameters[@"info"];
        }
        if (   [parameters[@"track"] isKindOfClass:[NSString class]]
            && [parameters[@"track"] isEqualToString:@"true"]) 
        {
            view.growingAttributesDonotTrackValue = NO;
        }
    }
    view.growingRnClickable = isClickable ?: @(NO);
    view.growingRnParameters = parameters;
}



#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstancePlus("RCTComponentData", NSObject *, @selector(createViewWithTag:rootTag:), UIView *, NSNumber * tag, NSNumber * rootTag)
#pragma clang diagnostic pop
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        loadAllReactNativeNodeMethod();
    });

    
    UIView * view = FoHookOrgin(tag, rootTag);
    

    if (view != nil)
    {
        prepareViewProps(view, tag);
        [allReactNativeViews setObject:view forKey:tag];
    }
    return view;
}
FoHookEnd



#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstancePlus("RCTComponentData", NSObject *, @selector(createViewWithTag:), UIView *, NSNumber * tag)
#pragma clang diagnostic pop
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        loadAllReactNativeNodeMethod();
    });

    
    UIView * view = FoHookOrgin(tag);
    

    if (view != nil)
    {
        prepareViewProps(view, tag);
        [allReactNativeViews setObject:view forKey:tag];
    }
    return view;
}
FoHookEnd


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstancePlus("RCTText", UIView *, @selector(setTextStorage:), void, NSTextStorage * textStorage)
#pragma clang diagnostic pop
{
    NSString * oldText = self.growingViewContent;
    FoHookOrgin(textStorage);
    NSString * newText = self.growingViewContent;

    if (newText != oldText && ![newText isEqualToString:oldText])
    {
        [GrowingTextChangeEvent sendEventWithNode:self
                                     andEventType:(oldText.length ? GrowingEventTypeUIChangeText : GrowingEventTypeUISetText)];
    }
}
FoHookEnd


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstancePlus("RCTTextView", UIView *, @selector(setTextStorage:contentFrame:descendantViews:), void, NSTextStorage * textStorage, CGRect contentFrame, NSArray *descendantViews)
#pragma clang diagnostic pop
{
    NSString * oldText = self.growingViewContent;
    FoHookOrgin(textStorage, contentFrame, descendantViews);
    NSString * newText = self.growingViewContent;
    
    if (newText != oldText && ![newText isEqualToString:oldText])
    {
        [GrowingTextChangeEvent sendEventWithNode:self
                                     andEventType:(oldText.length ? GrowingEventTypeUIChangeText : GrowingEventTypeUISetText)];
    }
}
FoHookEnd



#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstance(UIViewController, @selector(growingTrackSelfPage), void)
#pragma clang diagnostic pop
{
    NSString *classString = NSStringFromClass([self class]);
    if ([self isViewLoaded] &&
        ([self.view isKindOfClass:NSClassFromString(@"RCTRootView")]
         || [classString hasPrefix:@"RNSScreen"]) &&
        [GrowingEventManager shareInstance].inVCLifeCycleSendPageState == YES) {
        return;
    }
    
    FoHookOrgin();
}
FoHookEnd


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookClass(GrowingImpressionEvent, @selector(sendEventWithNode:andEventType:), void, id<GrowingNode> _Nonnull node, GrowingEventType eventType)
#pragma clang diagnostic pop
{
    if (GrowingReactNativeEnvironment.isTransitioning) {
        return;
    } else {
        FoHookOrgin(node, eventType);
    }
}
FoHookEnd

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookClass(GrowingImpressionEvent, @selector(sendEventsWithJavascriptCore:andNodes:eventType:andPageDataDict:), void, GrowingJavascriptCore * _Nonnull javascriptCore, NSArray<GrowingDullNode *> * _Nonnull nodes, GrowingEventType eventType, NSDictionary * _Nonnull pageData)
#pragma clang diagnostic pop
{
    if (GrowingReactNativeEnvironment.isTransitioning) {
        return;
    } else {
        FoHookOrgin(javascriptCore, nodes, eventType, pageData);
    }
}
FoHookEnd






















#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstance(GrowingImpressionEvent, @selector(initWithTimestamp:pageData:view:keyIndex:xpath:), id, NSNumber * _Nullable tm, NSDictionary *_Nonnull pageData, id<GrowingNode> _Nonnull view, NSInteger keyIndex, NSString *_Nullable path)
#pragma clang diagnostic pop
{
    if (GrowingReactNativeEnvironment.isTransitioning) {
        return nil;
    }
    if (![self isKindOfClass:[GrowingClickEvent class]]
        && [view isKindOfClass:[UIView class]]
        && ((UIView *)view).growingRnPageId.length > 0) {
        if (![((UIView *)view).growingRnPageId isEqualToString:GrowingReactNativeEnvironment.currentDidFocusPageId]) {
            return nil;
        }
    }
    return FoHookOrgin(tm, pageData, view, keyIndex, path);
}
FoHookEnd

@implementation GrowingReactNativeTrack


+ (void)onPagePrepare:(NSString *)page
{
    if ([GrowingEventManager shareInstance].lastPageEvent && [[GrowingEventManager shareInstance].lastPageEvent.dataDict[@"p"] isEqualToString:page]) {
        return;
    }
    
    GrowingReactNativeEnvironment.currentWillFocusPageId = page;
    
    GrowingReactNativeEnvironment.isTransitioning = YES;
}

+ (void)onPageShow:(NSString *)page
{
    
    GrowingReactNativeEnvironment.isTransitioning = YES;

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(delayOnPageShow:) withObject:page afterDelay:0.150];
}

static int rnPageCheckNum = 0;

+ (void)delayOnPageShow:(NSString *)page
{
    if ([GrowingEventManager shareInstance].lastPageEvent && [[GrowingEventManager shareInstance].lastPageEvent.dataDict[@"p"] isEqualToString:page]) {
        [self transitioningEnd];
        return;
    }
    
    UIViewController * curVC = [[UIApplication sharedApplication].growingMainWindow growingHook_curViewController];
    
    if (!curVC) {
        rnPageCheckNum = 0;
        [self performSelector:@selector(delayPageSend:) withObject:page afterDelay:0.200];
    } else {
        [self
         pageSend:page curVC:curVC];
    }
}

+ (void)delayPageSend:(NSString *)page
{
    if (rnPageCheckNum > 2) {
        [self transitioningEnd];
        return;
    }
    
    UIViewController * curVC = [[UIApplication sharedApplication].growingMainWindow growingHook_curViewController];
    
    if (!curVC) {
        rnPageCheckNum++;
        [self performSelector:@selector(delayPageSend:) withObject:page afterDelay:0.200];
    } else {
        [self pageSend:page curVC:curVC];
    }
}

+ (void)pageSend:(NSString *)page curVC:(UIViewController *)curVC
{
    GrowingReactNativeEnvironment.currentDidFocusPageId = page;
    
    [self transitioningEnd];
    
    GrowingReactNativeEnvironment.currentPageName = page;
    
    curVC.growingAttributesPageName = GrowingReactNativeEnvironment.currentPageName;
    [GrowingPageEvent sendEventWithController:curVC];
    
    for (NSString *key in unsendPagePageVariableDict) {
        if ([key isEqualToString:page]) {
            [GrowingReactNativeTrack setPageVariable:key pageLevelVariables:unsendPagePageVariableDict[key]];
            [unsendPagePageVariableDict removeObjectForKey:key];
            break;
        }
    }
    
    [GrowingImpressionEvent sendEventWithNode:[GrowingRootNode rootNode]
                                 andEventType:GrowingEventTypeUIPageShow];
}

+ (void)transitioningEnd
{
    GrowingReactNativeEnvironment.isTransitioning = NO;
}

+ (void)setPageVariable:(NSString *)page pageLevelVariables:(NSDictionary *)pageLevelVariables
{
    if (pagePageVariableDict == nil) {
        pagePageVariableDict = [[NSMutableDictionary alloc] init];
    }
    
    if (unsendPagePageVariableDict == nil) {
        unsendPagePageVariableDict = [[NSMutableDictionary alloc] init];
    }
    
    if (page.length == 0) {
        NSLog(parameterValueErrorLog);
        return;
    }
    
    if (![pageLevelVariables isKindOfClass:[NSDictionary class]]) {
        NSLog(parameterValueErrorLog);
        return;
    }
    
    if (![pageLevelVariables isValidDicVar]) {
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:pageLevelVariables];
    if (dict.count > 100 ) {
        NSLog(parameterValueErrorLog);
        return;
    }
    
    
    if (![GrowingEventManager shareInstance].lastPageEvent || ![[GrowingEventManager shareInstance].lastPageEvent.dataDict[@"p"] isEqualToString:page]) {
        unsendPagePageVariableDict[page] = pageLevelVariables;
        return;
    }
    
    
    if (dict.count != 0 ) {
        [[GrowingMobileDebugger shareDebugger] cacheValue:dict ofType:NSStringFromClass([self class])];
    }
    
    NSString *p = [GrowingEventManager shareInstance].lastPageEvent.dataDict[@"p"];
    
    NSMutableDictionary *beforePvar = pagePageVariableDict[p];
    if (beforePvar.count == 0) {
        beforePvar = [[NSMutableDictionary alloc] init];
    }
    BOOL somethingWasChange = [beforePvar mergeGrowingAttributesVar:dict];
    if (somethingWasChange)
    {
        [GrowingPvarEvent sendRnPvarEvent:beforePvar];
    }
    
    pagePageVariableDict[p] = beforePvar;
}

@end

@implementation GrowingReactNativeAutoTrack

+ (void)prepareView:(NSDictionary *)tagClickDict parameters:(NSDictionary *)parameters
{
    NSNumber *tag = tagClickDict[@"tag"];
    if (tag == nil) {
        return;
    }
    NSNumber *isClickable = tagClickDict[@"isClickable"];
    if (isClickable == nil) {
        isClickable = @NO;
    }
    
    if (parameters == nil) {
        parameters = @{};
    }
    
    [GrowingDispatchManager dispatchInMainThread:^{
        toBeCreatedTags[tag] = @{KEY_CLICKABLE:isClickable, KEY_PARAMETERS:parameters};
    }];
}

+ (void)onClick:(NSNumber *)tag
{
    [GrowingDispatchManager dispatchInMainThread:^{
        UIView * view = [allReactNativeViews objectForKey:tag];
        NSNumber * clickable = view.growingRnClickable;
        if (clickable == nil || ![clickable boolValue])
        {
            
            view.growingRnClickable = [NSNumber numberWithBool:YES];
        }
        [GrowingClickEvent sendEventWithNode:view andEventType:GrowingEventTypeButtonClick];
    }];
}

+ (void)onPagePrepare:(NSString *)page
{
    [GrowingDispatchManager dispatchInMainThread:^{
        [GrowingReactNativeTrack onPagePrepare:page];
    }];
}

+ (void)onPageShow:(NSString *)page
{
    [GrowingDispatchManager dispatchInMainThread:^{
        [GrowingReactNativeTrack onPageShow:page];
    }];
    
}

@end
