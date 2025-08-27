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


#import <Foundation/Foundation.h>
#import "GrowingEvent.h"
#import "GrowingEventDataBase.h"
#import "GrowingAddEventContextProtocal.h"

@protocol GrowingEventManagerObserver <NSObject>

@optional

- (BOOL)growingEventManagerShouldTriggerNode:(id<GrowingNode> _Nullable)triggerNode
                                   eventType:(GrowingEventType)eventType
                                   withChild:(BOOL)withChild;

- (void)growingEventManagerWillTriggerNode:(id<GrowingNode> _Nullable)triggerNode
                                 eventType:(GrowingEventType)eventType
                                 withChild:(BOOL)withChild;


- (BOOL)growingEventManagerShouldAddEvent:(GrowingEvent* _Nullable)event
                                 thisNode:(id<GrowingNode> _Nullable)thisNode
                              triggerNode:(id<GrowingNode> _Nullable)triggerNode
                              withContext:(id<GrowingAddEventContext> _Nullable)context;

- (void)growingEventManagerWillAddEvent:(GrowingEvent* _Nullable)event
                               thisNode:(id<GrowingNode> _Nullable)thisNode
                            triggerNode:(id<GrowingNode> _Nullable)triggerNode
                            withContext:(id<GrowingAddEventContext> _Nullable)context;
@end

@interface GrowingEventManager : NSObject
@property (nonatomic, strong) GrowingEvent *lastPageEvent;
@property (nonatomic, strong) GrowingVisitEvent *vstEvent;
@property (nonatomic, assign) BOOL shouldCacheEvent;
@property (nonatomic, assign) BOOL allowUploadViaCellular;
@property (nonatomic, assign) BOOL inVCLifeCycleSendPageState;
@property (nonatomic, copy) void(^reportHandler)(NSDictionary *eventObject);

+ (_Nonnull instancetype)shareInstance;
+ (BOOL)hasSharedInstance;
+ (NSString *)jointField:(NSString *)fieldA withField:(NSString *)fieldB;
- (_Nonnull instancetype)initWithName:(NSString *_Nonnull)name ai:(NSString *_Nullable)ai;

- (void)sendEvents;

- (void)flushDB;

- (void)clearAllEvents;

- (void)addObserver:(NSObject<GrowingEventManagerObserver>* _Nonnull)observer;
- (void)removeObserver:(NSObject<GrowingEventManagerObserver> *_Nonnull)observer;

- (void)dispathInUpload:(void(^_Nullable)(void))block;


- (void)addEvent:(GrowingEvent* _Nullable)event
        thisNode:(id<GrowingNode> _Nullable)thisNode
     triggerNode:(id<GrowingNode> _Nullable)triggerNode
     withContext:(id<GrowingAddEventContext> _Nullable)context;


- (BOOL)triggerNodeNeedTrack:(id<GrowingNode> _Nullable)node
               witheventType:(GrowingEventType)eventType
                   withChild:(BOOL)withChild;

- (BOOL)preDetermineShouldNotTrackImp;

@end
