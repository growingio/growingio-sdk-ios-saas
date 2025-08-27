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


#import "GrowingEventListMenu.h"
#import "GrowingEventManager.h"
#import "GrowingUIConfig.h"
#import "UIApplication+GrowingHelper.h"
#import "UIWindow+GrowingHelper.h"
#import "UIView+GrowingHelper.h"
#import "GrowingUIConfig.h"
#import "GrowingEventListCell.h"

#import "GrowingEventListItem.h"
#import "GrowingCircleListController.h"

#import "GrowingLocalCircleModel.h"
#import "UIImage+GrowingHelper.h"
#import "GrowingNavigationController.h"
#import "GrowingLoginMenu.h"
#import "GrowingLocalCircleWindow.h"
#import "GrowingImageCache.h"
#import "GrowingDeviceInfo.h"
#import "GrowingEventListMenuPopView.h"
#import "GrowingReplayViewController.h"
#import "GrowingInstance.h"
#import "GrowingEventListAction.h"

@interface GrowingEventListMenu()<GrowingEventManagerObserver>

@property (nonatomic, retain) GrowingImageCache *imageCache;
@property (nonatomic, retain) NSMutableArray<GrowingEventListItem*> *allEventItems;

@property (nonatomic, retain) UIViewController *viewController;
@property (nonatomic, retain) GrowingEventListMenuPopView *popView;
@property (nonatomic, assign) BOOL showTable;

@end

@implementation GrowingEventListMenu

static BOOL _isReplay = NO;
+ (void)setIsReplay:(BOOL)isReplay
{
    _isReplay = isReplay;
}

+ (BOOL)isReplay
{
    return _isReplay;
}

static GrowingEventListMenu *shareInstance = nil;
static void(^onStopBlock)() = nil;
+ (void)clearAllEvent
{
    [[shareInstance allEventItems] removeAllObjects];
}

+ (BOOL)isStart
{
    return shareInstance != nil;
}

+ (void)startTrack
{
    if (shareInstance)
    {
        return;
    }
    
    shareInstance = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [GrowingLoginMenu showIfNeededSucceed:^{
        [[GrowingLocalCircleModel sdkInstance] requestAllTagItemsSucceed:nil fail:nil];
        [shareInstance setHidden:NO];
    } fail:^{
        [self stopTrack];
    }];
    
}

+ (void)hide
{
    if (shareInstance)
    {
        shareInstance.showTable = NO;
    }
}

+ (void)stopTrack
{
    if (shareInstance)
    {
        [shareInstance setHidden:YES];
        shareInstance = nil;
    }
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self)
    {
        return nil;
    }
    else
    {
        return view;
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [[GrowingEventManager shareInstance] addObserver:self];
        NSString *cachePath = [[GrowingDeviceInfo currentDeviceInfo].storePath stringByAppendingPathComponent:@"circleImageCache"];
        self.imageCache = [[GrowingImageCache alloc] initWithDirPath:cachePath];
        self.allEventItems = [[NSMutableArray alloc] initWithCapacity:300];
        self.growingViewLevel = 1;
        self.showTable = NO;
        self.popView = [[GrowingEventListMenuPopView alloc] initWithFrame:self.bounds];
        self.popView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        @weakify(self);
        [self.popView setOnClick:^{
            @strongify(self);
            self.showTable = !self.showTable;
        }];
        [self addSubview:self.popView];
    }
    return self;
}

- (void)setShowTable:(BOOL)showTable
{
    if (_showTable != showTable)
    {
        if (showTable)
        {
            [GrowingLocalCircleWindow increaseHiddenCount];
        }
        else
        {
            [GrowingLocalCircleWindow decreaseHiddenCount];
        }
    }
    
    _showTable = showTable;
    if (showTable)
    {
        if (self.viewController)
        {
            return;
        }
        
        UIViewController *vc = nil;
        
        @weakify(self);
        id closeBlock = ^{
            @strongify(self);
            self.showTable = NO;
        };
        
        if (_isReplay)
        {
            GrowingReplayViewController *circleVC = [[GrowingReplayViewController alloc] initWithItems:[self.allEventItems copy]];
            circleVC.onCloseClick = closeBlock;
            vc = circleVC;
        }
        else
        {
           GrowingCircleListController *circleVC = [[GrowingCircleListController alloc] initWithItems:[self.allEventItems copy]];
            circleVC.onCloseClick = closeBlock;
            vc = circleVC;
        }
        
        GrowingNavigationController *nav = [[GrowingNavigationController alloc] initWithRootViewController:vc];
    
        self.viewController = nav;
        nav.view.frame = self.bounds;
        nav.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:nav.view];
    }
    else
    {
        if (!self.viewController)
        {
            return;
        }
        [self.viewController.view removeFromSuperview];
        self.viewController = nil;
    }
}

- (void)growingEventManagerWillAddEvent:(GrowingEvent *)event
                               thisNode:(id<GrowingNode> _Nullable)thisNode
                            triggerNode:(id<GrowingNode>)triggerNode
                            withContext:(id<GrowingAddEventContext>)context
{
    if ([NSThread isMainThread])
    {
        [self _growingEventManagerWillAddEvent:event thisNode:thisNode triggerNode:triggerNode withContext:context];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _growingEventManagerWillAddEvent:event thisNode:thisNode triggerNode:triggerNode withContext:context];
        });
    }
}

- (GrowingEventListItem*)addItemIntoAllEventsItems:(NSString*)title type:(GrowingEventType)type
{
    GrowingEventListItem *item = [[GrowingEventListItem alloc] init];
    item.timeInterval = [[NSDate date] timeIntervalSince1970];
    item.title = title;
    item.eventType = type;
    [self.allEventItems insertObject:item atIndex:0];
    return item;
}

- (GrowingEventListItem*)lastEventItem
{
    return self.allEventItems.firstObject;
}

- (void)setGrowingEventListItem:(GrowingEventListItem*)item image:(UIImage*)image
{
    item.cacheImage = [GrowingImageCacheImage imageWithCache:self.imageCache image:image];
}

- (void)popTipWithTitle:(NSString*)title eventType:(GrowingEventType)eventType
{
    UIColor *color = [GrowingUIConfig colorWithEventType:eventType];
    color = [color colorWithAlpha:0.9 backgroundColor:[UIColor blackColor]];
    
    [self.popView popTitle:title
                 withColor:color];
}

- (void)_growingEventManagerWillAddEvent:(GrowingEvent *)event
                                thisNode:(id<GrowingNode>)thisNode
                            triggerNode:(id<GrowingNode>)triggerNode
                            withContext:(id<GrowingAddEventContext>)context
{
    GrowingEventType eventType = [event eventType];
    GrowingEventType mainEventType = GrowingTypeGetMainType(eventType);
    GrowingEventType lastMainEventType = GrowingTypeGetMainType([self lastEventItem].eventType);
    NSString *mainDesp = GrowingEventTypeGetDescription(mainEventType);
    NSString *trueDesp = GrowingEventTypeGetDescription(eventType);
    
    GrowingEventListItem *lastItem = nil;
    
    
    switch (mainEventType) {
        
        case GrowingEventTypePage:
        case GrowingEventTypeAppLifeCycle:
        {
            [self popTipWithTitle:trueDesp eventType:eventType];
            
            lastItem = [self addItemIntoAllEventsItems:trueDesp
                                                  type:eventType];
            if (mainEventType == GrowingEventTypePage)
            {
                
            }
            break;
        }

        case GrowingEventTypeUserInteraction:
        {
            
            if (lastMainEventType == mainEventType
                && [[self lastEventItem].childItems.firstObject.tm isEqual:event.dataDict[@"tm"]])
            {
                lastItem = [self lastEventItem];
            }
            else
            {
                lastItem = [self addItemIntoAllEventsItems:trueDesp type:eventType];
                [self popTipWithTitle:trueDesp eventType:eventType];
            }
            break;
        }
        
        case GrowingEventTypeNetWork:
        case GrowingEventTypeUI:
        {
            
            if (lastMainEventType == mainEventType)
            {
                lastItem = [self lastEventItem];
            }
            else
            {
                lastItem = [self addItemIntoAllEventsItems:mainDesp type:eventType];
            }
        }
        default:
            
            break;
    }
    
    
    id<GrowingEventListAction>  action =  GrowingEventListActionForEventType(mainEventType);
    UIImage *screenShot =
    _isReplay
    ? [action replay_screenShotWithTriggerNode:triggerNode
                                        thisNode:thisNode
                                            item:lastItem]
    : [action eventlist_screenShotWithTriggerNode:triggerNode
                                           thisNode:thisNode
                                               item:lastItem];
    
    if (screenShot)
    {
        [self setGrowingEventListItem:lastItem image:screenShot];
    }
    
    


    
    switch (mainEventType) {
        case GrowingEventTypePage:
        {
            [lastItem addMessageWord:event.dataDict[@"p"]];
            break;
        }
            
        case GrowingEventTypeUserInteraction:
        {





            break;
        }
            
        case GrowingEventTypeNetWork:
        {
            NSString *url = event.dataDict[@"url"];
            NSString *responseCode = event.dataDict[@"RC"];
            NSString *message = event.dataDict[@"RMS"];

            if (url.length)
            {
                if (lastItem.message.length)
                {
                    [lastItem addMessageWord:@"\n"];
                }
                
                [lastItem addMessageWord:url];
                NSString *code = responseCode.lowercaseString;
                if ((code.intValue / 100) == 2)
                {
                    [lastItem addMessageWord:@":成功"];
                }
                else
                {
                    if (code.length)
                    {
                        [lastItem addMessageWord:@":"];
                        [lastItem addMessageWord:code];
                    }
                    [lastItem addMessageWord:@"    "];
                    [lastItem addMessageWord:message];
                }
            }
        }
        case GrowingEventTypeUI:
        {
            NSMutableString *string = lastItem.message;
            if (string.length < 80)
            {
                NSString *v = event.dataDict[@"v"];
                if (v.length)
                {
                    [lastItem addMessageWord:v];
                    [lastItem addMessageWord:@","];
                }
            }
            break;
        }
            
        case GrowingEventTypeAppLifeCycle:
            
            break;
        default:
            
            break;
    }

    
    if (lastItem)
    {
        GrowingEventListChildItem *subItem = [[GrowingEventListChildItem alloc] init];
        
        GrowingElement *element = [[GrowingElement alloc] init];
        if ([event.dataDict[@"v"] length])
        {
            element.content = event.dataDict[@"v"];
        }
        if ([event.dataDict[@"p"] length])
        {
            element.page = event.dataDict[@"p"];
        }
        if ([event.dataDict[@"pg"] length])
        {
            element.pageGroup = event.dataDict[@"pg"];
        }
        if ([event.dataDict[@"x"] length])
        {
            element.xpath = event.dataDict[@"x"];
        }
        if (event.dataDict[@"idx"])
        {
            element.index = [event.dataDict[@"idx"] integerValue];
        }
        if ([event.dataDict[@"d"] length])
        {
            element.domain = event.dataDict[@"d"];
        }
    
        subItem.element = element;
        subItem.tm = event.dataDict[@"tm"];
        
        subItem.eventType = eventType;
        
        [lastItem addChildItem:subItem];
    }
}

@end
