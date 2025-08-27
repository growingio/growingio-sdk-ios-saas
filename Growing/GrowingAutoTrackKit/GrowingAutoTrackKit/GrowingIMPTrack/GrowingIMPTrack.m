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
#import "GrowingIMPTrack.h"
#import "GrowingEBApplicationEvent.h"
#import "GrowingDispatchManager.h"
#import "UIView+GrowingNode.h"
#import "GrowingEBVCLifeEvent.h"
#import "UIApplication+GrowingNode.h"

@interface GrowingIMPTrack()

@property (nonatomic, strong) NSHashTable *sourceTable;
@property (nonatomic, strong) NSHashTable *bgSourceTable;

@end

static BOOL isInResignSate;

@implementation GrowingIMPTrack

subscribe
+ (void)applicationEvent:(GrowingEBApplicationEvent *)event
{
    switch (event.lifeType) {
        case GrowingApplicationWillResignActive:
            [[GrowingIMPTrack shareInstance] resignActive];
            break;
        case GrowingApplicationDidBecomeActive:
            [[GrowingIMPTrack shareInstance] becomeActive];
            break;
        default:
            break;
    }
}

static int isTransition = -1;

subscribe
+ (void)viewControllerLifeEvent:(GrowingEBVCLifeEvent *)event
{
    switch (event.lifeType) {
        case GrowingVCLifeWillAppear:{
            isTransition = -1;
        }
            break;
        case GrowingVCLifeDidAppear:{
            isTransition = 1;
            [[GrowingIMPTrack shareInstance] markInvisibleNodes];
            [[GrowingIMPTrack shareInstance] addWindowNodes];
        }
            break;

        default:
            break;
    }
}

- (void)becomeActive
{
    if (isInResignSate) {
        [self.bgSourceTable.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ((UIView *)obj).growingIMPTracked = NO;
        }];
        isInResignSate = NO;
    }
    [self.bgSourceTable removeAllObjects];
}

- (void)resignActive
{
    isInResignSate = YES;

    [self.sourceTable.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.bgSourceTable addObject:obj];
    }];
}

- (void)markInvisibleNodes
{
    if (self.sourceTable.count == 0) {
        return;
    }
    [self.sourceTable.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView <GrowingNode> *node = obj;
        if (![node growingImpNodeIsVisible]) {
            node.growingIMPTracked = NO;
        }
    }];
}

- (void)markInvisibleNode:(UIView *)node inSubView:(BOOL)flag;
{
    if (node.growingIMPTrackEventId > 0) {
        node.growingIMPTracked = NO;
    }

    if (flag) {
        [self enumerateSubViewsWithNode:node block:^(UIView *view) {
            if (view.growingIMPTrackEventId > 0) {
                view.growingIMPTracked = NO;
            }
        }];
    }
}

- (void)addWindowNodes
{
    [self.sourceTable removeAllObjects];
    
    UIWindow *window = [[UIApplication sharedApplication] growingMainWindow];
    
    if (window) {
        [self enumerateSubViewsWithNode:window block:^(UIView *view) {
            [self addNode:view];
        }];
    }
}

- (void)enumerateSubViewsWithNode:(UIView *)node block:(void(^)(UIView *view))block
{
    if (!self.impTrackActive) {
        return;
    }
    
    NSArray *array = node.subviews;
    for (UIView *subView in array) {
        block(subView);
        [self enumerateSubViewsWithNode:subView block:block];
    }
}

static GrowingIMPTrack *impTrack = nil;
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        impTrack = [[GrowingIMPTrack alloc] init];
        impTrack.IMPInterval = 0.0;
    });
    return impTrack;
}

- (instancetype)init
{
    if (impTrack != nil) {
        return nil;
    }
    
    if (self =[super init]) {
        self.sourceTable = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory |
                            NSPointerFunctionsObjectPointerPersonality
                   capacity:100];
        self.bgSourceTable = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory |
                              NSPointerFunctionsObjectPointerPersonality
                                                         capacity:100];
    }
    return self;
}

static BOOL impTrackIsRegistered = NO;
- (void)setImpTrackActive:(BOOL)impTrackActive
{
    _impTrackActive = impTrackActive;
    if (impTrackActive && !impTrackIsRegistered) {
        impTrackIsRegistered = YES;
        [self registerMainRunloopObserver];
    }
}

- (void)registerMainRunloopObserver
{
    
    [GrowingDispatchManager dispatchInMainThread:^{
        static CFRunLoopObserverRef observer;
        
        if (observer) {
            return;
        }
        
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        CFOptionFlags activities = (kCFRunLoopBeforeWaiting | 
                                    kCFRunLoopExit);          
        
        
        observer = CFRunLoopObserverCreateWithHandler(NULL,        
                                                      activities,  
                                                      YES,         
                                                      INT_MAX-1,     
                                                      ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
                                                          if (self.IMPInterval == 0.0) {
                                                              [self impTrack];
                                                          } else {
                                                              [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(impTrack) object:nil];
                                                              [self performSelector:@selector(impTrack) withObject:nil afterDelay:self.IMPInterval inModes:@[NSRunLoopCommonModes]];
                                                          }
                                                      });
        
        CFRunLoopAddObserver(runLoop, observer, kCFRunLoopCommonModes);
        
        CFRelease(observer);
    }];
}

- (void)impTrack
{
    if (isInResignSate) {
        return;
    }
    
    if (isTransition == -1) {
        return;
    }
    
    if (self.sourceTable.count == 0) {
        return;
    }
    
    [self.sourceTable.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView <GrowingNode> *node = obj;
        if ([node growingImpNodeIsVisible]) {
            if (node.growingIMPTracked == NO) {
                if (node.growingIMPTrackEventId.length > 0) {
                    [self sendCstm:node];
                }
            }
        } else {
            node.growingIMPTracked = NO;
        }
        
    }];
}

- (void)sendCstm:(UIView<GrowingNode> *)node
{
    node.growingIMPTracked = YES;
    
    NSString *v = [node growingNodeContent];
    
    if (v.length > 0 && v.length <= 50) {
        NSMutableDictionary *impTrackVariable;
        if (node.growingIMPTrackVariable.count > 0) {
            impTrackVariable = node.growingIMPTrackVariable.mutableCopy;
        } else {
            impTrackVariable = [[NSMutableDictionary alloc] init];
        }
        impTrackVariable[@"gio_v"] = v;
        node.growingIMPTrackVariable = impTrackVariable;
    }

    if (node.growingIMPTrackEventId.length > 0 && node.growingIMPTrackNumber && node.growingIMPTrackVariable.count > 0) {
        [Growing track:node.growingIMPTrackEventId withNumber:node.growingIMPTrackNumber andVariable:node.growingIMPTrackVariable];
    } else if (node.growingIMPTrackEventId.length > 0 && node.growingIMPTrackNumber) {
        [Growing track:node.growingIMPTrackEventId
            withNumber:node.growingIMPTrackNumber];
    } else if (node.growingIMPTrackEventId.length > 0 && node.growingIMPTrackVariable.count > 0) {
        [Growing track:node.growingIMPTrackEventId withVariable:node.growingIMPTrackVariable];
    } else if (node.growingIMPTrackEventId.length > 0) {
        [Growing track:node.growingIMPTrackEventId];
    }
}

- (void)addNode:(UIView *)node inSubView:(BOOL)flag;
{
    if (node.growingIMPTrackEventId.length > 0) {
        [self.sourceTable addObject:node];
    }
    
    if (flag) {
        [self enumerateSubViewsWithNode:node block:^(UIView *view) {
            if (view.growingIMPTrackEventId.length > 0) {
                [self.sourceTable addObject:view];
            }
        }];
    }
}

- (void)addNode:(UIView *)node
{
    if (node.growingIMPTrackEventId.length > 0) {
        [self.sourceTable addObject:node];
    }
}

- (void)clearNode:(UIView *)node
{
    node.growingIMPTrackEventId = nil;
    node.growingIMPTrackNumber = nil;
    node.growingIMPTrackVariable = nil;
    node.growingIMPTracked = NO;
    [self.sourceTable removeObject:node];
}

@end
