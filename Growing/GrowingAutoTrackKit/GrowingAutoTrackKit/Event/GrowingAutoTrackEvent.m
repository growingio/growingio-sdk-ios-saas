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


#import "GrowingAutoTrackEvent.h"
#import "GrowingInstance.h"
#import "GrowingEventManager.h"
#import "NSDictionary+GrowingHelper.h"
#import "NSString+GrowingHelper.h"
#import "UIViewController+GrowingNode.h"
#import "UIViewController+Growing.h"
#import "GrowingCustomField+AutoTrackKit.h"
#import "GrowingDispatchManager.h"
#import "GrowingJavascriptCore.h"
#import "GrowingEventNodeManager.h"
#import "UIWindow+Growing.h"
#import "UIApplication+GrowingNode.h"
#import "GrowingCocoaLumberjack.h"

@interface GrowingNodeManagerEnumerateContext(addEvent)<GrowingAddEventContext>

@end


@implementation GrowingNodeManagerEnumerateContext(addEvent)

- (NSArray<id<GrowingNode>>* _Nullable)contextNodes
{
    return self.allNodes;
}

- (id<GrowingNode>)keyNode
{
    return self.startNode;
}

@end



@implementation GrowingPageEvent

- (instancetype)initWithTimestamp:(NSNumber *)tm
{
    self = [super initWithTimestamp:tm];
    if (self)
    {
        [self assignRadioType];
    }
    return self;
}

- (instancetype)initWithController:(UIViewController *)aPage
{
    self = [self initWithTimestamp:nil]; 
    if (self)
    {
        NSString * pageGroup = [aPage growingAttributesPageGroup];
        if (pageGroup.length > 0)
        {
            self.dataDict[@"pg"] = pageGroup;
        }
        
        NSDictionary * avar = [[GrowingCustomField shareInstance] growingAttributesAvar];
        if (avar.count > 0)
        {
            self.dataDict[@"var"] = avar;
        }
        
        
        NSString *title = [aPage GROW_pageTitle];
        if (title.length)
        {
            self.dataDict[@"tl"] = title;
        }
        
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation != UIInterfaceOrientationUnknown)
        {
            self.dataDict[@"o"] = UIInterfaceOrientationIsPortrait(orientation) ? @"portrait" : @"landscape";
        }
        
        [self.dataDict addEntriesFromDictionary:[aPage growingNodeDataDict]];
        
        self.dataDict[@"tm"] = self.dataDict[@"ptm"]; 
    }
    return self;
}

+ (instancetype)mutableCopyPageEvent:(GrowingPageEvent *)event
{
    GrowingPageEvent *pageEvent = [[GrowingPageEvent alloc] initWithUUID:event.uuid data:event.dataDict];
    pageEvent.isResend = event.isResend;
    return pageEvent;
}



- (instancetype)initWithLastPageDataDict:(NSMutableDictionary *)dataDict
{
    self = [self initWithTimestamp:nil]; 
    if (self)
    {
        NSDictionary * avar = [[GrowingCustomField shareInstance] growingAttributesAvar];
        if (avar.count > 0)
        {
            self.dataDict[@"var"] = avar;
        }
        
        
        self.dataDict[@"tl"] = dataDict[@"tl"];
        
        
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation != UIInterfaceOrientationUnknown)
        {
            self.dataDict[@"o"] = UIInterfaceOrientationIsPortrait(orientation) ? @"portrait" : @"landscape";
        }
        
        self.dataDict[@"p"] = dataDict[@"p"];
        self.dataDict[@"ptm"] = dataDict[@"ptm"];
        self.dataDict[@"pg"] = dataDict[@"pg"];
        self.dataDict[@"tm"] = dataDict[@"ptm"]; 
        self.dataDict[@"rp"] = dataDict[@"rp"];
    }
    return self;
}

- (instancetype)initWithJavascriptCore:(GrowingJavascriptCore *)javascriptCore
                       andPageDataDict:(NSDictionary *)pageDataDict
{
    self = [self initWithTimestamp:nil];
    if (self)
    {
        
        
        UIViewController * aPage = javascriptCore.hostViewController;
        
        NSString *title = [aPage GROW_pageTitle];
        if (title.length)
        {
            self.dataDict[@"tl"] = title;
        }
        
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation != UIInterfaceOrientationUnknown)
        {
            self.dataDict[@"o"] = UIInterfaceOrientationIsPortrait(orientation) ? @"portrait" : @"landscape";
        }
        
        
        [self.dataDict addEntriesFromDictionary:[aPage growingNodeDataDict]];
        
        NSDictionary * avar = [[GrowingCustomField shareInstance] growingAttributesAvar];
        if (avar.count > 0)
        {
            self.dataDict[@"var"] = avar;
        }
        
        
        
        self.dataDict[@"d"] = [GrowingJavascriptCore jointField:self.dataDict[@"d"] withField:pageDataDict[@"d"]];
        
        self.dataDict[@"tl"] = [GrowingJavascriptCore jointField:self.dataDict[@"tl"] withField:pageDataDict[@"v"]];
        
        self.dataDict[@"rp"] = [GrowingJavascriptCore jointField:self.dataDict[@"p"] withField:pageDataDict[@"rp"]];
        
        self.dataDict[@"p"] = [GrowingJavascriptCore jointField:self.dataDict[@"p"] withField:pageDataDict[@"p"]];
        
        self.dataDict[@"tm"] = pageDataDict[@"tm"];
        self.dataDict[@"ptm"] = pageDataDict[@"tm"];
        
        if (pageDataDict[@"q"] != nil)
        {
            self.dataDict[@"q"] = pageDataDict[@"q"];
        }
    }
    return self;
}

+ (void)resendPageEventForCS1Change {
    [self resendPageEvent];
}

+ (void)resendPageEvent
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingPageEvent *lastPageEvent = [GrowingEventManager shareInstance].lastPageEvent;
    if (lastPageEvent) {
        [GrowingDispatchManager dispatchInMainThread:^{
            NSMutableDictionary *eventDataDict = [lastPageEvent.dataDict mutableCopy];
            GrowingPageEvent *pageEvent = [[self alloc] initWithLastPageDataDict:eventDataDict];
            pageEvent.isResend = YES;
            [GrowingEventManager shareInstance].lastPageEvent = [GrowingPageEvent mutableCopyPageEvent:pageEvent];
            
            [pageEvent sendWithTriggerNode:nil thisNode:nil triggerEventType:GrowingEventTypePageResendPage context:nil];
        }];
    }
}

+ (void)sendEventWithController:(UIViewController *)controller
{
    [self sendEventWithController:controller reSend:NO];
}

+ (void)resendEventWithController:(UIViewController *)controller
{
    [self sendEventWithController:controller reSend:YES];
}

+ (void)sendEventWithController:(UIViewController *)controller reSend:(BOOL)reSend
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingEventType eventType = reSend ? GrowingEventTypePageResendPage : GrowingEventTypePageNewPage;
    
    GrowingPageEvent *lastPageEvent = [GrowingEventManager shareInstance].lastPageEvent;
    if (NO == [GrowingEvent nodeShouldTriggered:controller
                                       withType:eventType
                                      withChild:NO])
    {
        return;
    }
    if (!reSend)
    {
        if (!controller.GROW_pvarCacheTimestamp) {
            
            controller.GROW_lastShowTimestamp = GROWGetTimestamp();
        }
    }
    
    if (reSend && lastPageEvent == nil)
    {
        
        return;
    }
    
    GrowingPageEvent *event = [[self alloc] initWithController:controller];
    
    event.isResend = NO;
    if (reSend)
    {
        
        if (   [event.dataDict[@"p"] isKindOfClass:[NSString class]]
            && [lastPageEvent.dataDict[@"p"] isKindOfClass:[NSString class]]
            && [event.dataDict[@"p"] isEqualToString:lastPageEvent.dataDict[@"p"]])
        {
            
            event.dataDict[@"rp"] = lastPageEvent.dataDict[@"rp"];
            event.dataDict[@"tm"] = lastPageEvent.dataDict[@"tm"];
            event.dataDict[@"ptm"] = lastPageEvent.dataDict[@"ptm"];
            event.isResend = YES;
        }
        else
        {
            
            return;
        }
    }
    else
    {
        
        event.dataDict[@"rp"] = lastPageEvent.dataDict[@"p"];
    }
    [GrowingEventManager shareInstance].lastPageEvent = [GrowingPageEvent mutableCopyPageEvent:event];
    
    [event sendWithTriggerNode:controller
                      thisNode:controller
              triggerEventType:eventType
                       context:nil];

    if(controller.growingAttributesPvar &&controller.growingAttributesPvar.count>0)
    {
       [controller sendPvarEvent];
    }
}

+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingEventType eventType = GrowingEventTypePageNewH5Page;
    if (NO == [GrowingEvent nodeShouldTriggered:javascriptCore.webView
                                       withType:eventType
                                      withChild:NO])
    {
        return;
    }
    
    GrowingPageEvent *event = [[self alloc] initWithJavascriptCore:javascriptCore
                                                   andPageDataDict:pageDataDict];
    
    [event sendWithTriggerNode:javascriptCore.webView
                      thisNode:javascriptCore.webView
              triggerEventType:eventType
                       context:nil];
}

- (NSString*)eventTypeKey
{
    return @"page";
}

static NSString *pageName = nil;
+ (void)sendPage:(NSString *)page
{
    if (page.length == 0) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayPageSend:) object:pageName];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayOnPageShow:) object:pageName];
    [self performSelector:@selector(delayOnPageShow:) withObject:page afterDelay:0.150];
    pageName = page;
}

static int pageCheckNum = 0;

+ (void)delayOnPageShow:(NSString *)page
{
    if ([GrowingEventManager shareInstance].lastPageEvent && [[GrowingEventManager shareInstance].lastPageEvent.dataDict[@"p"] isEqualToString:page]) {
        return;
    }
    
    UIViewController * curVC = [[UIApplication sharedApplication].growingMainWindow growingHook_curViewController];
    
    if (!curVC) {
        pageCheckNum = 0;
        [self performSelector:@selector(delayPageSend:) withObject:page afterDelay:0.200];
    } else {
        [self pageSend:page curVC:curVC];
    }
}

+ (void)delayPageSend:(NSString *)page
{
    if (pageCheckNum > 2) {
        return;
    }
    
    UIViewController * curVC = [[UIApplication sharedApplication].growingMainWindow growingHook_curViewController];
    
    if (!curVC) {
        pageCheckNum++;
        [self performSelector:@selector(delayPageSend:) withObject:page afterDelay:0.200];
    } else {
        [self pageSend:page curVC:curVC];
    }
}

+ (void)pageSend:(NSString *)page curVC:(UIViewController *)curVC
{
    if ([GrowingEventManager shareInstance].lastPageEvent && [[GrowingEventManager shareInstance].lastPageEvent.dataDict[@"p"] isEqualToString:page]) {
        return;
    }
    
    curVC.growingAttributesPageName = page;
    [GrowingPageEvent sendEventWithController:curVC];
    
    if (g_enableImp)
    {
        [GrowingImpressionEvent sendEventWithNode:[GrowingRootNode rootNode]
                                     andEventType:GrowingEventTypeUIPageShow];
    }

}


@end


@implementation GrowingImpressionEvent

+ (BOOL)hasExtraFields
{
    return NO; 
}

+ (BOOL)checkNode:(id<GrowingNode>)aNode
{
    if ([aNode respondsToSelector:@selector(growingNodeEligibleEventCategory)])
    {
        GrowingElementEventCategory c = [aNode growingNodeEligibleEventCategory];
        if (!(c & GrowingElementEventCategoryImpression))
        {
            return NO;
        }
    }
    return [aNode growingNodeContent] || [aNode growingNodeUserInteraction] || [aNode growingNodeAsyncNativeHandler] != nil;
}

+ (void)_sendEventsWithManager:(GrowingNodeManager*)manager
                   triggerNode:(id<GrowingNode>)triggerNode
                     eventType:(GrowingEventType)eventType
                      pageData:(NSDictionary*)pageData
                    withChilds:(BOOL)withChilds
{
    NSNumber *tm = GROWGetTimestamp();
    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode,
                                           GrowingNodeManagerEnumerateContext *context) {
        
        @autoreleasepool {
            if(!withChilds)
            {
                [context stop];
            }
            
            if ([self checkNode:aNode])
            {
                id<GrowingNodeAsyncNativeHandler> asyncNativeHandler = [aNode growingNodeAsyncNativeHandler];
                if (asyncNativeHandler != nil)
                {
                    [asyncNativeHandler impressAllChildren];
                    return;
                }
                GrowingEvent *event =
                [[self alloc] initWithTimestamp:tm
                                       pageData:pageData
                                           view:aNode
                                       keyIndex:[context nodeKeyIndex]
                                          xpath:[context xpath]];
                
                if (event)
                {
                    [event sendWithTriggerNode:triggerNode
                                      thisNode:aNode
                              triggerEventType:eventType
                                       context:context];
                }
            }
        }
    }];
}

+ (void)_sendEventsUnsafeWithNode:(id<GrowingNode>)node
                        eventType:(GrowingEventType)eventType
                       withChilds:(BOOL)withChilds
{
    if (withChilds == NO && ![self checkNode:node])
    {
        return ;
    }
    
    GrowingNodeManager *manager =
    [[GrowingEventNodeManager alloc] initWithNode:node
                                        eventType:eventType];
    
    GrowingRootNode *rootNode = [manager nodeAtFirst];
    NSDictionary *pageData = [rootNode growingNodeDataDict];
    if (pageData.count != 0) {
        
        
        NSDictionary *lastPageData = [GrowingEventManager shareInstance].lastPageEvent.dataDict;
        if (lastPageData.count) {
            pageData = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:
                        lastPageData[@"p"], @"p",
                        lastPageData[@"ptm"], @"ptm",
                        lastPageData[@"pg"], @"pg", nil];
        }
    }
    
    if (!manager || rootNode != [GrowingRootNode rootNode])
    {
        return ;
    }
    
    [self _sendEventsWithManager:manager
                     triggerNode:node
                       eventType:eventType
                        pageData:pageData
                      withChilds:withChilds];
}

+ (void)_sendEventsWithJavascriptCore:(GrowingJavascriptCore * _Nonnull)javascriptCore
                             andNodes:(NSArray<GrowingDullNode *> * _Nonnull)nodes
                            eventType:(GrowingEventType)eventType
                      andPageDataDict:(NSDictionary* _Nonnull)pageData
{
    if (NO == [GrowingEvent nodeShouldTriggered:javascriptCore.webView
                                       withType:eventType
                                      withChild:YES])
    {
        return;
    }
    
    
    NSDictionary * nativePageData = [javascriptCore.hostViewController growingNodeDataDict];
    NSString * webViewPage = pageData[@"p"];
    NSString * webViewDomain = pageData[@"d"];
    NSString * webViewTime = pageData[@"tm"];
    NSString * webViewPageTime = pageData[@"ptm"];
    NSString * webViewQuery = pageData[@"q"];
    for (GrowingDullNode * node in nodes)
    {
        
        GrowingImpressionEvent * impEvent = [[self alloc] initWithTimestamp:nil
                                                                   pageData:nativePageData
                                                                       view:node
                                                                   keyIndex:node.growingNodeKeyIndex
                                                                      xpath:node.growingNodeXPath];
        
        impEvent.dataDict[@"d"] = [GrowingJavascriptCore jointField:impEvent.dataDict[@"d"] withField:webViewDomain];
        
        impEvent.dataDict[@"p"] = [GrowingJavascriptCore jointField:impEvent.dataDict[@"p"] withField:webViewPage];
        
        [impEvent.dataDict removeObjectForKey:@"n"];
        
        if (node.growingNodeHyperlink != nil)
        {
            impEvent.dataDict[@"h"] = node.growingNodeHyperlink;
        }
        
        impEvent.dataDict[@"tm"] = webViewTime;
        impEvent.dataDict[@"ptm"] = webViewPageTime;
        
        if (webViewQuery != nil)
        {
            impEvent.dataDict[@"q"] = webViewQuery;
        }
        NSString * info = [impEvent growingNodeGetAttrInfo:node];
        if (info.length > 0)
        {
            impEvent.dataDict[@"obj"] = info;
        }
        
        [impEvent sendWithTriggerNode:javascriptCore.webView
                             thisNode:node
                     triggerEventType:eventType
                              context:nil];
    }
}

+ (void)_sendEventsWithNode:(id<GrowingNode>)node
                  eventType:(GrowingEventType)eventType
                 withChilds:(BOOL)withChilds
{
    if ([NSThread isMainThread])
    {
        [self _sendEventsUnsafeWithNode:node
                              eventType:eventType
                             withChilds:withChilds];
    }
    else
    {
        __weak id<GrowingNode> weakNode = node;
        dispatch_async(dispatch_get_main_queue(), ^ {
            id<GrowingNode> strongNode = weakNode;
            if (!strongNode)
            {
                return;
            }
            
            
            
            @try {
                [self _sendEventsUnsafeWithNode:node
                                      eventType:eventType
                                     withChilds:withChilds];
            } @catch (NSException *exception) {
                GIOLogError(@"[gio] imp exception : %@", exception);
            } @finally {
                
            }
        });
    }
}

+ (void)sendEventsWithJavascriptCore:(GrowingJavascriptCore * _Nonnull)javascriptCore
                            andNodes:(NSArray<GrowingDullNode *> * _Nonnull)nodes
                           eventType:(GrowingEventType)eventType
                     andPageDataDict:(NSDictionary * _Nonnull)pageData
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    if ([NSThread isMainThread])
    {
        [self _sendEventsWithJavascriptCore:javascriptCore andNodes:nodes eventType:eventType andPageDataDict:pageData];
    }
    else
    {
        __weak GrowingJavascriptCore * weakCore = javascriptCore;
        dispatch_sync(dispatch_get_main_queue(), ^ {
            GrowingJavascriptCore * strongCore = weakCore;
            if (strongCore)
            {
                [self _sendEventsWithJavascriptCore:javascriptCore andNodes:nodes eventType:eventType andPageDataDict:pageData];
            }
        });
    }
}

- (NSString*)eventTypeKey
{
    return @"imp";
}

- (NSString*)growingNodeGetAttrInfo:(id<GrowingNode>)node
{
    NSString *info = nil;
    while (node && info.length == 0)
    {
        if ([node respondsToSelector:@selector(growingAttributesInfo)])
        {
            info = [node performSelector:@selector(growingAttributesInfo)];
        }
        node = [node growingNodeAttachedInfoNode];
    }
    return info;
}

- (_Nullable instancetype)initWithTimestamp:(NSNumber * _Nullable )tm
                                   pageData:(NSDictionary * _Nonnull)pageData
                                       view:(id<GrowingNode> _Nonnull )view
                                   keyIndex:(NSInteger)keyIndex
                                      xpath:(NSString* _Nullable )path
{
    self = [self initWithTimestamp:tm];
    if (self)
    {
        [self.dataDict addEntriesFromDictionary:pageData];
        NSString *v = [view growingNodeContent];
        if (!v)
        {
            v = @"";
        } else if([v isKindOfClass:NSString.class])
        {
            
        } else if ([v isKindOfClass:NSDictionary.class])
        {
            v = [[(NSDictionary *)v allValues] componentsJoinedByString:@""];
        } else if ([v isKindOfClass:NSArray.class])
        {
            v = [(NSArray *)v componentsJoinedByString:@""];
        } else {
            v = v.description;
        }
        v = [v growingHelper_safeSubStringWithLength:100];
        
        if (![self isKindOfClass:[GrowingClickEvent class]]) {
            v = v.growingHelper_encryptString;
        }
        self.dataDict[@"v"] = v;
        self.dataDict[@"n"] = NSStringFromClass(view.class);
        if (keyIndex >= 0)
        {
            self.dataDict[@"idx"] = [NSString stringWithFormat:@"%d",(int)keyIndex];
        }
        self.dataDict[@"x"] = path;
        NSString * info = [self growingNodeGetAttrInfo:view];
        if (info.length > 0)
        {
            self.dataDict[@"obj"] = info;
        }
        
    }
    return self;
}

+ (void)sendEventWithNode:(id<GrowingNode>)node andEventType:(GrowingEventType)eventType
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    if (NO == [GrowingEvent nodeShouldTriggered:node
                                       withType:eventType
                                      withChild:NO])
    {
        return;
    }
    
    [self _sendEventsWithNode:node
                    eventType:eventType
                   withChilds:YES];
}

@end

@implementation GrowingTextChangeEvent



+ (void)sendEventWithNode:(id<GrowingNode>)node andEventType:(GrowingEventType)eventType
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    if (NO == [GrowingEvent nodeShouldTriggered:node
                                       withType:eventType
                                      withChild:NO])
    {
        return;
    }
    
    if ([GrowingEventManager hasSharedInstance] &&
        [[GrowingEventManager shareInstance] preDetermineShouldNotTrackImp]) {
        return;
    }
    
    [self _sendEventsWithNode:node
                    eventType:eventType
                   withChilds:NO];
}

@end

@implementation GrowingTextEditContentChangeEvent



+ (void)sendEventWithNode:(id<GrowingNode>)node andEventType:(GrowingEventType)eventType
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    if (NO == [GrowingEvent nodeShouldTriggered:node
                                       withType:eventType
                                      withChild:NO])
    {
        return;
    }
    
    [self _sendEventsWithNode:node
                    eventType:eventType
                   withChilds:NO];
}


+ (BOOL)checkNode:(id<GrowingNode>)aNode
{
    if ([aNode respondsToSelector:@selector(growingNodeEligibleEventCategory)])
    {
        GrowingElementEventCategory c = [aNode growingNodeEligibleEventCategory];
        if (!(c & GrowingElementEventCategoryContentChange))
        {
            return NO;
        }
    }
    return YES;
}

- (NSString*)eventTypeKey
{
    return @"chng";
}

@end

@implementation GrowingClickEvent

- (_Nullable instancetype)initWithTimestamp:(NSNumber * _Nullable )tm
                                   pageData:(NSDictionary * _Nonnull)pageData
                                       view:(id<GrowingNode> _Nonnull )view
                                   keyIndex:(NSInteger)keyIndex
                                      xpath:(NSString* _Nullable )path
{
    self = [super initWithTimestamp:tm pageData:pageData view:view keyIndex:keyIndex xpath:path];
    if (self) {
        NSString *v = [self.dataDict objectForKey:@"v"];
        if (v.growingHelper_isLegal) {
            v = @"";
        } else {
            v = v.growingHelper_encryptString;
        }
        [self.dataDict setValue:v forKey:@"v"];
        
        
        [self.dataDict removeObjectForKey:@"n"];
    }
    return self;
}

+ (BOOL)hasExtraFields
{
    return YES; 
}

+ (BOOL)checkNode:(id<GrowingNode>)aNode
{
    if ([aNode respondsToSelector:@selector(growingNodeEligibleEventCategory)])
    {
        GrowingElementEventCategory c = [aNode growingNodeEligibleEventCategory];
        if (!(c & GrowingElementEventCategoryClick))
        {
            return NO;
        }
    }
    return [aNode growingNodeUserInteraction];
}

+ (void)_sendEventsWithManager:(GrowingNodeManager*)manager
                   triggerNode:(id<GrowingNode>)triggerNode
                     eventType:(GrowingEventType)eventType
                      pageData:(NSDictionary *)pageData
                    withChilds:(BOOL)withChilds
{
    __block BOOL isFirst = YES;
    NSNumber *tm = GROWGetTimestamp();
    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode,
                                           GrowingNodeManagerEnumerateContext *context) {
        
        if(!withChilds)
        {
            [context stop];
        }
        
        BOOL needTrack = NO;
        BOOL userInActionNeedTrack = YES;
        if ([aNode growingNodeUserInteraction])
        {
            if (isFirst)
            {
                isFirst = NO;
                needTrack = YES;
            }
            else
            {
                userInActionNeedTrack = NO;
                [context skipThisChilds];
            }
        }
        
        if (([aNode growingNodeContent] || needTrack) && userInActionNeedTrack)
        {
            
            GrowingEvent *event =
            [[self alloc] initWithTimestamp:tm
                                   pageData:pageData
                                       view:aNode
                                   keyIndex:[context nodeKeyIndex]
                                      xpath:[context xpath]];
            if (event)
            {
                [event sendWithTriggerNode:triggerNode
                                  thisNode:aNode
                          triggerEventType:eventType
                                   context:context];
            }
        }
    }];
}

- (NSString*)eventTypeKey
{
    return @"clck";
}
@end


@implementation GrowingSubmitEvent

- (NSString*)eventTypeKey
{
    return @"sbmt";
}

@end

@implementation GrowingTapEvent
@end

@implementation GrowingDoubleClickEvent


- (NSString*)eventTypeKey
{
    return @"dbclck";
}

@end

@implementation GrowingLongPressEvent

- (NSString*)eventTypeKey
{
    return @"lngclck";
}

@end

@implementation GrowingTouchDownEvent

- (NSString*)eventTypeKey
{
    return @"tchd";
}
@end

@implementation GrowingViewHideEvent


+ (void)sendEventWithNode:(id<GrowingNode>)node andEventType:(GrowingEventType)eventType
{
    if ([NSThread isMainThread])
    {
        [GrowingEvent nodeShouldTriggered:node withType:eventType withChild:YES];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [GrowingEvent nodeShouldTriggered:node withType:eventType withChild:YES];
        });
    }
}

@end

@implementation GrowingNewCellNoTrackEvent

+ (void)sendEventWithNode:(id<GrowingNode>)node andEventType:(GrowingEventType)eventType
{
    if ([NSThread isMainThread])
    {
        [GrowingEvent nodeShouldTriggered:node withType:eventType withChild:YES];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [GrowingEvent nodeShouldTriggered:node withType:eventType withChild:YES];
        });
    }
}

@end

@implementation GrowingPvarEvent

- (NSString*)eventTypeKey
{
    return @"pvar";
}

+ (void)sendPvarEvent:(UIViewController *)viewController {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    if (viewController.growingAttributesPvar.count == 0) {
        return;
    }
    
    NSDictionary * vcDict = [viewController growingNodeDataDict];
    
    GrowingPvarEvent * event = [[GrowingPvarEvent alloc] init];
    NSMutableDictionary * dataDict = event.dataDict;
    dataDict[@"p"] = vcDict[@"p"];
    
    
    if (vcDict[@"ptm"]) {
        
        
        dataDict[@"ptm"] = vcDict[@"ptm"];
    } else {
        
        
        if (!viewController.GROW_pvarCacheTimestamp) {
            viewController.GROW_pvarCacheTimestamp = GROWGetTimestamp();
            viewController.GROW_lastShowTimestamp = viewController.GROW_pvarCacheTimestamp;
        }
        dataDict[@"ptm"] = viewController.GROW_pvarCacheTimestamp;
    }
    
    dataDict[@"var"] = viewController.growingAttributesPvar;
    [[GrowingEventManager shareInstance] addEvent:event thisNode:nil triggerNode:nil withContext:nil];
}

+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingPvarEvent *event = [[GrowingPvarEvent alloc] init];
    NSMutableDictionary *dataDict = event.dataDict;
    
    NSDictionary *vcDict = [javascriptCore.hostViewController growingNodeDataDict];
    dataDict[@"p"] = vcDict[@"p"];
    
    
    dataDict[@"d"] = [GrowingJavascriptCore jointField:dataDict[@"d"] withField:pageDataDict[@"d"]];
    
    dataDict[@"p"] = [GrowingJavascriptCore jointField:dataDict[@"p"] withField:pageDataDict[@"p"]];
    
    dataDict[@"tm"] = pageDataDict[@"tm"];
    
    if (pageDataDict[@"var"]) {
        dataDict[@"var"] = pageDataDict[@"var"];
    }
    dataDict[@"ptm"] = pageDataDict[@"ptm"];
    [[GrowingEventManager shareInstance] addEvent:event thisNode:nil triggerNode:nil withContext:nil];
}

@end

@implementation GrowingEvarEvent (AutoTrackKit)

+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingEvarEvent *event = [[GrowingEvarEvent alloc] init];
    NSMutableDictionary *dataDict = event.dataDict;
    
    dataDict[@"d"] = [GrowingJavascriptCore jointField:dataDict[@"d"] withField:pageDataDict[@"d"]];
    
    dataDict[@"tm"] = pageDataDict[@"tm"];
    
    if (pageDataDict[@"var"]) {
        dataDict[@"var"] = pageDataDict[@"var"];
    }
    
    [[GrowingEventManager shareInstance] addEvent:event thisNode:nil triggerNode:nil withContext:nil];
}
@end

@implementation GrowingCustomTrackEvent (AutoTrackKit)

+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingCustomTrackEvent *event = [[GrowingCustomTrackEvent alloc] init];
    NSMutableDictionary *dataDict = event.dataDict;
    
    NSDictionary *vcDict = [javascriptCore.hostViewController growingNodeDataDict];
    dataDict[@"p"] = vcDict[@"p"];
    
    
    dataDict[@"d"] = [GrowingJavascriptCore jointField:dataDict[@"d"] withField:pageDataDict[@"d"]];
    
    dataDict[@"p"] = [GrowingJavascriptCore jointField:dataDict[@"p"] withField:pageDataDict[@"p"]];
    
    dataDict[@"tm"] = pageDataDict[@"tm"];
    
    dataDict[@"n"] = pageDataDict[@"n"];
    
    dataDict[@"num"] = pageDataDict[@"num"];
    
    if (pageDataDict[@"var"]) {
        dataDict[@"var"] = pageDataDict[@"var"];
    }
    if (pageDataDict[@"ptm"]) {
        dataDict[@"ptm"] = pageDataDict[@"ptm"];
    }
    
    [[GrowingEventManager shareInstance] addEvent:event thisNode:nil triggerNode:nil withContext:nil];
}
@end

@implementation GrowingPeopleVarEvent (AutoTrackKit)

+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingPeopleVarEvent *event = [[GrowingPeopleVarEvent alloc] init];
    NSMutableDictionary *dataDict = event.dataDict;
    
    dataDict[@"d"] = [GrowingJavascriptCore jointField:dataDict[@"d"] withField:pageDataDict[@"d"]];
    
    dataDict[@"tm"] = pageDataDict[@"tm"];
    
    if (pageDataDict[@"var"]) {
        dataDict[@"var"] = pageDataDict[@"var"];
    }
    
    [[GrowingEventManager shareInstance] addEvent:event thisNode:nil triggerNode:nil withContext:nil];
}

@end
