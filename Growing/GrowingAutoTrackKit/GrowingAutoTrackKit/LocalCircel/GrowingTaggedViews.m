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


#import "GrowingTaggedViews.h"
#import "GrowingLocalCircleModel.h"
#import "UIApplication+GrowingNode.h"
#import "UIWindow+Growing.h"
#import "UIViewController+GrowingNode.h"
#import "GrowingEventManager.h"
#import "GrowingUIConfig.h"
#import "GrowingJavascriptCore.h"
#import "GrowingDeviceInfo.h"
#import "GrowingLoginModel.h"
#import "GrowingNodeManager.h"
#import "GrowingAutoTrackEvent.h"
@interface GrowingTaggedViews () <GrowingEventManagerObserver>

@property (nonatomic, retain) NSHashTable<id<GrowingNode>> * highlightedTaggedNodes;
@property (nonatomic, retain) NSHashTable<id<GrowingNodeAsyncNativeHandler>> * asyncNativeHandlers;
@property (nonatomic, retain) NSArray<GrowingTagItem *> * currentPageTagItems;
@property (nonatomic, retain) NSArray<GrowingTagItem *> * currentPageHtml5TagItems;

@end

@implementation GrowingTaggedViews

static id shareInstance = nil;
+ (GrowingTaggedViews*)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}

- (void)setNeedShow
{
    if ([self isDisplaying])
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:shareInstance selector:@selector(reset) object:nil];
        [self performSelector:@selector(reset) withObject:nil afterDelay:0.1];
    }
}

- (void)removeNodeHighlight:(id<GrowingNode>)node
{
    [node growingNodeHighLight:NO withBorderColor:nil andBackgroundColor:nil];
    [self.highlightedTaggedNodes removeObject:node];
}

- (void)removeAsyncNativeHandler:(id<GrowingNodeAsyncNativeHandler>)asyncNativeHandler
{
    [asyncNativeHandler setCircledTags:@[] onFinish:nil];
    [asyncNativeHandler setShouldDisplayTaggedViews:NO];
    [self.asyncNativeHandlers removeObject:asyncNativeHandler];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _shouldDisplayTaggedViews = NO;
        _isPaused = NO;
        _highlightedTaggedNodes = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:5];
        _asyncNativeHandlers = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:5];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didlogout)
                                                     name:GrowingDidLogout
                                                   object:[GrowingLoginModel sdkInstance]];
    }
    return self;
}

- (void)didlogout
{
    self.shouldDisplayTaggedViews = NO;
}

- (BOOL)isDisplaying
{
    return _shouldDisplayTaggedViews && !_isPaused;
}

- (void)setShouldDisplayTaggedViews:(BOOL)flag
{
    if (_shouldDisplayTaggedViews && !flag)
    {
        [[GrowingEventManager shareInstance] removeObserver:self];
    }
    else if (!_shouldDisplayTaggedViews && flag)
    {
        [[GrowingEventManager shareInstance] addObserver:self];
    }

    _shouldDisplayTaggedViews = flag;
    [self reset];
}

- (void)setIsPaused:(BOOL)paused
{
    BOOL wasDisplaying = [self isDisplaying];
    _isPaused = paused;
    BOOL nowDisplaying = [self isDisplaying];
    if (!wasDisplaying && nowDisplaying)
    {
        [self show];
    }
    else if (wasDisplaying && !nowDisplaying)
    {
        [self hide];
    }
}

- (NSArray<GrowingTagItem *> *)getCurrentPageTagItems
{
    if (self.currentPageTagItems == nil)
    {
        UIViewController * currentVC = [[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController];
        NSString * currentPageName = [currentVC growingNodeDataDict][@"p"];
        NSString * currentDomain = [GrowingDeviceInfo currentDeviceInfo].bundleID;

        NSArray<GrowingTagItem *> * allTagItems = [[GrowingLocalCircleModel sdkInstance] cacheTagItems];
        NSMutableArray<GrowingTagItem *> * currentPageTagItems = [[NSMutableArray alloc] initWithCapacity:allTagItems.count];
        for (GrowingTagItem * item in allTagItems)
        {
            if (item.domain.length > 0 && ![item.domain isEqualToString:currentDomain])
            {
                
                continue;
            }
            if (item.page.length > 0 && ![item.page isEqualToString:currentPageName])
            {
                
                continue;
            }
            [currentPageTagItems addObject:item];
        }
        self.currentPageTagItems = currentPageTagItems;
    }
    return self.currentPageTagItems;
}

- (NSArray<GrowingTagItem *> *)getCurrentPageHtml5TagItems
{
    if (self.currentPageHtml5TagItems == nil)
    {
        UIViewController * currentVC = [[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController];
        NSString * currentPageName = [currentVC growingNodeDataDict][@"p"];
        NSString * currentDomain = [GrowingDeviceInfo currentDeviceInfo].bundleID;

        NSArray<GrowingTagItem *> * allTagItems = [[GrowingLocalCircleModel sdkInstance] cacheTagItems];
        NSMutableArray<GrowingTagItem *> * currentPageHtml5TagItems = [[NSMutableArray alloc] initWithCapacity:allTagItems.count];
        for (GrowingTagItem * item in allTagItems)
        {
            NSMutableString * fieldA = [[NSMutableString alloc] init];
            NSMutableString * fieldB = [[NSMutableString alloc] init];
            if (item.isPageTag)
            {
                continue;
            }
            if ([GrowingJavascriptCore parseJointField:item.xpath toFieldA:nil toFieldB:fieldB])
            {
                GrowingElement * originElement = item.originElement;
                GrowingElement * originHtml5Element = [[GrowingElement alloc] init];
                if (originElement != nil)
                {
                    originHtml5Element.page = @"";
                    originHtml5Element.content = @"";
                    originHtml5Element.xpath = @"";
                    originHtml5Element.index = [GrowingNodeItemComponent indexNotDefine];
                    originHtml5Element.domain = nil;
                    originHtml5Element.query = nil;
                    originHtml5Element.href = nil;
                    if (originElement.domain.length > 0 && [GrowingJavascriptCore parseJointField:originElement.domain toFieldA:fieldA toFieldB:fieldB])
                    {
                        if (fieldA.length > 0 && ![fieldA isEqualToString:currentDomain])
                        {
                            
                            continue;
                        }
                        originHtml5Element.domain = [fieldB copy];
                    }
                    if (originElement.page.length > 0 && [GrowingJavascriptCore parseJointField:originElement.page toFieldA:nil toFieldB:fieldB])
                    {
                        originHtml5Element.page = [fieldB copy];
                    }
                    originHtml5Element.content = originElement.content;
                    if (originElement.xpath.length > 0 && [GrowingJavascriptCore parseJointField:originElement.xpath toFieldA:fieldA toFieldB:fieldB])
                    {
                        originHtml5Element.xpath = [fieldB copy];
                    }
                    if ([fieldA rangeOfString:@"[-]"].location == NSNotFound)
                    {
                        
                        
                        originHtml5Element.index = originElement.index;
                    }
                    originHtml5Element.query = originElement.query;
                    originHtml5Element.href = originElement.href;
                }
                GrowingTagItem * html5TagItem = [[GrowingTagItem alloc] initWithName:item.name andTagId:item.tagId andIsPageTag:item.isPageTag andOriginElement:originHtml5Element];
                html5TagItem.xpath = nil;
                html5TagItem.page = nil;
                html5TagItem.content = nil;
                html5TagItem.index = [GrowingNodeItemComponent indexNotDefine];
                html5TagItem.domain = nil;
                html5TagItem.query = nil;
                html5TagItem.href = nil;
                if (item.domain.length > 0 && [GrowingJavascriptCore parseJointField:item.domain toFieldA:fieldA toFieldB:fieldB])
                {
                    if (fieldA.length > 0 && ![fieldA isEqualToString:currentDomain])
                    {
                        
                        continue;
                    }
                    html5TagItem.domain = [fieldB copy];
                }
                if (item.page.length > 0 && [GrowingJavascriptCore parseJointField:item.page toFieldA:fieldA toFieldB:fieldB])
                {
                    if (fieldA.length > 0 && ![fieldA isEqualToString:currentPageName])
                    {
                        
                        continue;
                    }
                    html5TagItem.page = [fieldB copy];
                }
                html5TagItem.content = item.content;
                if (item.xpath.length > 0 && [GrowingJavascriptCore parseJointField:item.xpath toFieldA:fieldA toFieldB:fieldB])
                {
                    html5TagItem.xpath = [fieldB copy];
                }
                if ([fieldA rangeOfString:@"[-]"].location == NSNotFound)
                {
                    
                    
                    html5TagItem.index = item.index;
                }
                html5TagItem.query = item.query;
                html5TagItem.href = item.href;
                [currentPageHtml5TagItems addObject:html5TagItem];
            }
        }
        self.currentPageHtml5TagItems = currentPageHtml5TagItems;
    }
    return self.currentPageHtml5TagItems;
}

- (BOOL)checkTaggedNodeWithXPath:(NSString *)xPath
                     andKeyIndex:(NSInteger)keyIndex
                      andContent:(NSString *)content
       withinCurrentPageTagItems:(NSArray<GrowingTagItem *> *)currentPageTagItems
{
    __block NSString * plainXPath = nil;
    void (^updatePlainXPath)(NSString * x) = ^void(NSString * x) {
        plainXPath = x;
    };
    for (GrowingTagItem * item in currentPageTagItems)
    {
        if (item.index == [GrowingNodeItemComponent indexNotDefine] || item.index == keyIndex)
        {
            if (item.content.length == 0 || [item.content isEqualToString:content])
            {
                if ([GrowingNodeManager isElementXPath:xPath orElementPlainXPath:plainXPath matchToTagXPath:item.xpath updatePlainXPathBlock:updatePlainXPath])
                {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)reset
{
    [self hide];
    [self.highlightedTaggedNodes removeAllObjects];
    [self.asyncNativeHandlers removeAllObjects];
    self.currentPageTagItems = nil;
    self.currentPageHtml5TagItems = nil;

    if (!_shouldDisplayTaggedViews)
    {
        return;
    }

    NSArray<GrowingTagItem *> * currentPageTagItems = [self getCurrentPageTagItems];

    NSHashTable<id<GrowingNode>> * allHitViews = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:5];
    GrowingNodeManager * manager = [[GrowingNodeManager alloc] initWithNodeAndParent:[GrowingRootNode rootNode]
                                                                          checkBlock:nil];
    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode, GrowingNodeManagerEnumerateContext *context) {
        id<GrowingNodeAsyncNativeHandler> asyncNativeHandler = [aNode growingNodeAsyncNativeHandler];
        if (asyncNativeHandler == nil)
        {
            if ([aNode growingNodeContent].length > 0 || [aNode growingNodeUserInteraction])
            {
                if ([self checkTaggedNodeWithXPath:[context xpath] andKeyIndex:[context nodeKeyIndex] andContent:[aNode growingNodeContent] withinCurrentPageTagItems:currentPageTagItems])
                {
                    [allHitViews addObject:aNode];
                }
            }
        }
        else
        {
            if (![self.asyncNativeHandlers containsObject:asyncNativeHandler])
            {
                [self.asyncNativeHandlers addObject:asyncNativeHandler];
                [asyncNativeHandler setCircledTags:[self getCurrentPageHtml5TagItems] onFinish:nil];
            }
        }
    }];

    self.highlightedTaggedNodes = allHitViews;
    if ([self isDisplaying])
    {
        [self show];
    }
}

- (void)show
{
    for (id<GrowingNodeAsyncNativeHandler> asyncNativeHandler in self.asyncNativeHandlers)
    {
        [asyncNativeHandler setShouldDisplayTaggedViews:YES];
    }
    
    for (id<GrowingNode> node in self.highlightedTaggedNodes)
    {
        [node growingNodeHighLight:YES
                   withBorderColor:[GrowingUIConfig circledItemBorderColor]
                andBackgroundColor:[GrowingUIConfig circledItemBackgroundColor]];
    }
}

- (void)hide
{
    for (id<GrowingNodeAsyncNativeHandler> asyncNativeHandler in self.asyncNativeHandlers)
    {
        [asyncNativeHandler setShouldDisplayTaggedViews:NO];
    }
    
    for (id<GrowingNode> node in self.highlightedTaggedNodes)
    {
        [node growingNodeHighLight:NO withBorderColor:nil andBackgroundColor:nil];
    }
}

- (void)growingEventManagerWillAddEvent:(GrowingEvent* _Nullable)event
                               thisNode:(id<GrowingNode> _Nullable)thisNode
                            triggerNode:(id<GrowingNode> _Nullable)triggerNode
                            withContext:(id<GrowingAddEventContext> _Nullable)context
{
    
    BOOL isResend = NO;
    if ([event isKindOfClass:[GrowingPageEvent class]]) {
        isResend = ((GrowingPageEvent *)event).isResend;
    }
    
    if ([event.dataDict[@"t"] isEqualToString:@"page"] && [thisNode growingNodeAsyncNativeHandler] == nil && isResend == NO)
    {
        [self hide];
        [self.highlightedTaggedNodes removeAllObjects];
        [self.asyncNativeHandlers removeAllObjects];
        self.currentPageTagItems = nil;
        self.currentPageHtml5TagItems = nil;
        return;
    }

    if ([event.dataDict[@"t"] isEqualToString:@"imp"] && thisNode != nil)
    {
        id<GrowingNodeAsyncNativeHandler> asyncNativeHandler = [thisNode growingNodeAsyncNativeHandler];
        if (asyncNativeHandler != nil)
        {
            if (![self.asyncNativeHandlers containsObject:asyncNativeHandler])
            {
                __weak id<GrowingNodeAsyncNativeHandler> weakAsyncNativeHandler = asyncNativeHandler;
                [self.asyncNativeHandlers addObject:asyncNativeHandler];
                [asyncNativeHandler setCircledTags:[self getCurrentPageHtml5TagItems]
                                          onFinish:^{
                                              [weakAsyncNativeHandler setShouldDisplayTaggedViews:YES];
                                          }];
            }
        }
        else
        {
            if ([self checkTaggedNodeWithXPath:event.dataDict[@"x"]
                                   andKeyIndex:[event.dataDict[@"idx"] integerValue]
                                    andContent:[thisNode growingNodeContent]
                     withinCurrentPageTagItems:[self getCurrentPageTagItems]])
            {
                [thisNode growingNodeHighLight:YES
                               withBorderColor:[GrowingUIConfig circledItemBorderColor]
                            andBackgroundColor:[GrowingUIConfig circledItemBackgroundColor]];
                if ([thisNode isKindOfClass:[GrowingDullNode class]])
                {
                    [self.highlightedTaggedNodes addObject:triggerNode];
                }
                else
                {
                    [self.highlightedTaggedNodes addObject:thisNode];
                }
            }
        }
    }
}

@end
