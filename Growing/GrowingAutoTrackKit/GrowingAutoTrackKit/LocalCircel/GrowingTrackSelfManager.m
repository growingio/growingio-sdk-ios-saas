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


#import "GrowingTrackSelfManager.h"
#import "GrowingEventManager.h"
#import "GrowingDeviceInfo.h"
#import "GrowingLoginModel.h"
#import "GrowingInstance.h"
#import "GrowingEBTrackSelfEvent.h"

@interface GrowingTrackSelfManager()<GrowingEventManagerObserver>

@property (nonatomic, retain) GrowingEventManager *trackManager;
@property (nonatomic, copy)   NSString *domain;

@end

@implementation GrowingTrackSelfManager

static GrowingTrackSelfManager *shareInstance = nil;

subscribe
+ (void)trackSelfEvent:(GrowingEBTrackSelfEvent *)event
{
    [self startTrack];
}

+ (void)startTrack
{
    if (shareInstance)
    {
        return;
    }
    shareInstance = [[self alloc] init];
    [shareInstance start];
}

+ (void)stopTrack
{
    [shareInstance stop];
    shareInstance = nil;
}

- (void)start
{
    [[GrowingEventManager shareInstance] addObserver:self];
}

- (void)stop
{
    [[GrowingEventManager shareInstance] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSString *bundleId = [GrowingDeviceInfo currentDeviceInfo].bundleID;
        self.domain =  [[NSString alloc] initWithFormat:@"GioCircle.%@",bundleId];
        
        NSString *uuid = [GrowingDeviceInfo currentDeviceInfo].deviceIDString;
        self.trackManager = [[GrowingEventManager alloc] initWithName:@"trackCircle"
                                                                   ai:@"0a1b4118dd954ec3bcc69da5138bdb96"];
        
    }
    return self;
}

- (void)updateEventCommentField:(GrowingEvent*)event
{
    if ([event.dataDict[@"d"] length])
    {
        event.dataDict[@"d"] = self.domain;
    }
    NSString *session = event.dataDict[@"s"];
    event.dataDict[@"s"] = [session stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

-(void)sendTrackSelfVisitEvent
{
    GrowingVisitEvent *vst = [[GrowingVisitEvent alloc] init];
    vst.dataDict[@"cv"] = vst.dataDict[@"av"];
    
    static NSString *lastSession = nil;
    if ([lastSession isEqualToString:vst.dataDict[@"s"]])
    {
        return;
    }
    else
    {
        [self updateEventCommentField:vst];
        lastSession = vst.dataDict[@"s"];
        [self.trackManager addEvent:vst
                           thisNode:nil
                        triggerNode:nil
                        withContext:nil];
    }
}

- (BOOL)growingEventManagerShouldAddEvent:(GrowingEvent *)event
                                 thisNode:(id<GrowingNode>)thisNode
                              triggerNode:(id<GrowingNode>)triggerNode
                              withContext:(id<GrowingAddEventContext>)context
{
    @autoreleasepool {
        
        if ([event.dataDict[@"t"] isEqualToString:@"vst"])
        {
            [self sendTrackSelfVisitEvent];
            return YES;
        }
        
        
        BOOL isGrowingEvent = NO;
        for (id<GrowingNode> obj in [context contextNodes])
        {
            if ([obj isKindOfClass:[GrowingWindow class]])
            {
                isGrowingEvent = YES;
                break;
            }
        }
        if (!isGrowingEvent)
        {
            return YES;
        }
        
        
        
        GrowingMenuPageView *pageView = (id)[context contextNodes].lastObject;
        static NSDictionary *pageDict = nil;
        if([pageView isKindOfClass:[GrowingMenuPageView class]])
        {
            NSMutableDictionary *pageDicttemp = [[NSMutableDictionary alloc] init];
            
            [pageDicttemp setValue:NSStringFromClass(pageView.class) forKey:@"p"];
            [pageDicttemp setValue:pageView.showTime                 forKey:@"ptm"];
            pageDict = pageDicttemp;
            
            
            
            [event.dataDict addEntriesFromDictionary:pageDict];
            event.dataDict[@"t"] = @"page";
            event.dataDict[@"tm"] = event.dataDict[@"ptm"];
            event.dataDict[@"tl"]  = pageView.title;
            event.dataDict[@"cs1"] = [[NSString alloc] initWithFormat:@"user:%@",[GrowingLoginModel sdkInstance].userId];
            event.dataDict[@"cs2"] = [[NSString alloc] initWithFormat:@"ai:%@",[GrowingInstance sharedInstance].accountID];
            event.dataDict[@"v"] = nil;
            event.dataDict[@"x"] = nil;
            event.dataDict[@"n"] = nil;
        }
        else
        {
            [event.dataDict addEntriesFromDictionary:pageDict];
        }
        
        
        [self updateEventCommentField:event];

        
        [self.trackManager addEvent:event
                           thisNode:nil
                        triggerNode:triggerNode
                        withContext:context];
        return NO;
    }
}


@end
