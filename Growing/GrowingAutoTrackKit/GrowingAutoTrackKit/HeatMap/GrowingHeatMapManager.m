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


#import "GrowingHeatMapManager.h"
#import "GrowingEventManager.h"
#import "GrowingHeatMapModel.h"
#import "UIApplication+GrowingNode.h"
#import "UIImage+GrowingHelper.h"
#import "UIWindow+Growing.h"
#import "GrowingNode.h"
#import "UIWindow+GrowingNode.h"
#import "UIViewController+GrowingNode.h"
#import "GrowingJavascriptCore.h"
#import "GrowingInstance.h"
#import "GrowingDeviceInfo.h"
#import "GrowingLoginModel.h"
#import "GrowingWindow.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingLocalCircleModel.h"

@interface GrowingHeatMapManager()<GrowingEventManagerObserver>

@property (nonatomic, retain) NSHashTable *maskedViews;
@property (nonatomic, copy) NSString *pageName;
@property (nonatomic, retain) NSArray *items;

@end

@implementation GrowingHeatMapManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.maskedViews = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:10];
    }
    return self;
}

+ (instancetype)shareInstance
{
    static GrowingHeatMapManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[GrowingHeatMapManager alloc] init];
    });
    return manager;
}

static BOOL isStart;
static NSTimer *timer;
+ (BOOL)isStart
{
    return isStart;
}

+ (void)start
{
    if (isStart)
    {
        return;
    }
    isStart = YES;
    
    [[GrowingEventManager shareInstance] addObserver:[self shareInstance]];
    
    NSDictionary *dict =
    [[[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController] growingNodeDataDict];
    
    [[self shareInstance] updateViewsByPageName:dict[@"p"]];
    [[self shareInstance] startH5HeatMap];
    timer = [NSTimer timerWithTimeInterval:1 target:[self shareInstance] selector:@selector(rebindHeatMap) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

+ (void)stop
{
    if (!isStart)
    {
        return;
    }
    
    [[GrowingEventManager shareInstance] removeObserver:[self shareInstance]];
    [[self shareInstance] clean];
    
    isStart = NO;
    [timer invalidate];
    timer = nil;
}

- (void)clean
{
    [self updateViewsByPageName:nil];
    [self stopH5HeatMap];
}
             
- (void)rebindHeatMap
{
    GrowingNodeManager *manager = [[GrowingNodeManager alloc] initWithNodeAndParent:[GrowingRootNode rootNode]
                                                                         checkBlock:nil];
    
    [self tryBindItem:self.items manager:manager withChild:YES];
}

- (void)showTip:(NSString*)tip
{
    UILabel *label = [[UILabel alloc] init];
    label.text = tip;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    label.textColor = [UIColor whiteColor];
    label.clipsToBounds = YES;
    label.layer.cornerRadius = 4;
    label.font = [UIFont systemFontOfSize:12];
    CGSize size = [label sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    size.width += 6;
    size.height += 6;

    GrowingWindowView *tipView = [[GrowingWindowView alloc] initWithFrame:CGRectMake(0,
                                                                                     0,
                                                                                     size.width + 6,
                                                                                     size.height + 6)];
    label.frame = tipView.bounds;
    [tipView addSubview:label];
    
    
    tipView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2,
                                 [UIScreen mainScreen].bounds.size.height / 5 * 4);
    tipView.hidden = NO;
    
    tipView.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5
                         animations:^{
                             label.alpha = 0;
                         } completion:^(BOOL finished) {
                             tipView.hidden = YES;
                         }];
    });
    
}

- (void)updateViewsByPageName:(NSString*)pageName
{
    self.items = nil;
    self.pageName = pageName;
    if (!pageName.length)
    {
        return;
    }
    @weakify(self);
    [[GrowingHeatMapModel sdkInstance] requestDataByPageName:pageName
                                                     succeed:^(NSArray<GrowingHeatMapModelItem *> *items) {
                                                         @strongify(self);
                                                         if ([self.pageName isEqualToString:pageName])
                                                         {
                                                             self.items = items;
                                                             if (items.count == 0)
                                                             {
                                                                 [self showTip:@"本页暂无热图数据"];
                                                             }
                                                         }
                                                         
                                                     } fail:^(NSString *error) {
                                                         @strongify(self);
                                                         if ([self.pageName isEqualToString:pageName])
                                                         {
                                                             self.items = nil;
                                                             
                                                             NSString *mess = nil;
                                                             if (error.length)
                                                             {
                                                                 mess = [NSString stringWithFormat:@"热图错误:%@",error];
                                                             }
                                                             else
                                                             {
                                                                 mess = @"热图错误";
                                                             }
                                                             [self showTip:mess];
                                                         }
                                                     }];
}


- (void)setItems:(NSArray *)items
{
    _items = items;
    
    for (id<GrowingNode> node in self.maskedViews)
    {
        [node growingNodeHighLight:NO withBorderColor:nil andBackgroundColor:nil];
    }

    if (items.count == 0)
    {
        return;
    }
    
    [self rebindHeatMap];
}

- (void)tryBindItem:(NSArray*)items  manager:(GrowingNodeManager*)manager withChild:(BOOL)withChild
{
    if (!manager)
    {
        return;
    }
    
    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode, GrowingNodeManagerEnumerateContext *context) {
        
        UIImage *img = nil;
        if ([aNode growingNodeUserInteraction])
        {
            for (GrowingHeatMapModelItem *item in items)
            {
                
                
                
                NSString * decoratedTagXPath = [item.xpath hasPrefix:@"#"] ? [@"*" stringByAppendingString:item.xpath] : item.xpath;
                if ([GrowingNodeManager isElementXPath:context.xpath
                                   orElementPlainXPath:nil
                                       matchToTagXPath:decoratedTagXPath
                                 updatePlainXPathBlock:nil]
                    && (
                        item.content.length == 0
                        || [item.content isEqualToString:[aNode growingNodeContent]]
                        )
                    && (
                        item.index == nil
                        || context.nodeKeyIndex < 0
                        || item.index.integerValue == context.nodeKeyIndex
                        )
                    )
                {
                    img = [UIImage createHeatMapImageBySize:[aNode growingNodeFrame].size
                                                         brightLevel:item.brightLevel];
                    
                    break;
                }
            }
        }
        
        if (img)
        {
            [self.maskedViews addObject:aNode];
            [aNode growingNodeHighLight:YES
                        withBorderColor:[UIColor blackColor]
                     andBackgroundColor:(UIColor*)img];
        }
        else
        {
            [aNode growingNodeHighLight:NO
                        withBorderColor:nil
                     andBackgroundColor:nil];
        }
        
        
        if (!withChild)
        {
            [context stop];
        }
    }];
}



#pragma mark - observer

- (void)startH5HeatMap
{
   
    NSString *nativeInfo = [GrowingJavascriptCore nativeInfo];
    [GrowingJavascriptCore allWebViewExecuteJavascriptMethod:@"_vds_hybrid.showHeatMap"
                                               andParameters:@[nativeInfo]];
}

- (void)stopH5HeatMap
{
    [GrowingJavascriptCore allWebViewExecuteJavascriptMethod:@"_vds_hybrid.hideHeatMap"
                                               andParameters:nil];
}

- (void)growingEventManagerWillTriggerNode:(id<GrowingNode>)triggerNode
                                 eventType:(GrowingEventType)eventType
                                 withChild:(BOOL)withChild
{
    GrowingEventType mainEventType = GrowingTypeGetMainType(eventType);
    
    if (eventType == GrowingEventTypePageNewPage
        || eventType == GrowingEventTypePageResendPage)
    {
        [self updateViewsByPageName: [[triggerNode growingNodeDataDict] valueForKey:@"p"]];
    }
    
    else if (eventType == GrowingEventTypePageNewH5Page
             || eventType == GrowingEventTypePageResendH5Page)
    {
        [self startH5HeatMap];
    }
    
    else if (mainEventType == GrowingEventTypeUI)
    {
        if (eventType != GrowingEventTypeH5Element)
        {
            GrowingNodeManager *manager = [[GrowingNodeManager alloc] initWithNodeAndParent:triggerNode
                                                                                 checkBlock:nil];
            [self tryBindItem:self.items manager:manager withChild:YES];
        }
    }
    else if (mainEventType == GrowingEventTypeUIHidden)
    {
        GrowingNodeManager *manager = [[GrowingNodeManager alloc] initWithNodeAndParent:triggerNode
                                                                             checkBlock:nil];
        [self tryBindItem:nil manager:manager withChild:YES];
    }
    else
    {
        
    }
}

@end
