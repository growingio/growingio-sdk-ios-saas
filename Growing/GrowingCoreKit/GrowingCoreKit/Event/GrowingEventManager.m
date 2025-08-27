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

#import "GrowingEventManager.h"
#import "GrowingDeviceInfo.h"
#import "GrowingInstance.h"
#import "GrowingEventModel.h"
#import "NSDictionary+GrowingHelper.h"
#import "NSString+GrowingHelper.h"
#import "GROW_KDNetworkInterfaceManager.h"
#import "GrowingEvent.h"
#import "GrowingGlobal.h"
#import "NSData+GrowingHelper.h"
#import "GrowingEventCounter.h"
#import "GrowingMobileDebugger.h"
#import "GrowingMediator.h"
#import "GrowingDispatchManager.h"
#import "GrowingFileStore.h"
#import "GrowingCustomField.h"
#import "GrowingCocoaLumberjack.h"
#import "GrowingAsaFetcher.h"
#import "GrowingNetworkPreflight.h"

#define QUEUE_MAX_SIZE 10000
#define QUEUE_FILL_SIZE 1000

#define FIELD_SEPARATOR @"::"

typedef enum : NSUInteger {
    GrowingKeyEvent,
    GrowingNormalEvent,
    GrowingDropEvent,
} GrowingEventDestiny;

static NSString* getEventDBPath()
{
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        path = [[GrowingDeviceInfo currentDeviceInfo].storePath stringByAppendingString:@"/event.sqlite"];
    });
    return path;
}

@interface GrowingEventWhiteListItem : NSObject

@property (nonatomic, copy)     NSString *  domain;
@property (nonatomic, copy)     NSString *  xpath;
@property (nonatomic, copy)     NSString *  pageName;
@property (nonatomic, copy)     NSString *  hyperlink;
@property (nonatomic, copy)     NSString *  content;
@property (nonatomic, retain)   NSNumber *  index;
@property (nonatomic, copy)     NSString *  indexString;

@end

@implementation GrowingEventWhiteListItem

@end



@interface GrowingEventChannel : NSObject

@property (nonatomic, readonly, copy)   NSArray<NSString *> * eventTypes;
@property (nonatomic, readonly, copy)   NSString * urlTemplate;
@property (nonatomic, readonly, assign) BOOL isCustomEvent;
@property (nonatomic, readonly, assign) BOOL isReportEvent;
@property (nonatomic,           assign) BOOL isUploading;

@end

@implementation GrowingEventChannel

- (instancetype)initWithTypes:(NSArray<NSString *> *)eventTypes
                  urlTemplate:(NSString *)urlTemplate
                isCustomEvent:(BOOL)isCustomEvent
                isReportEvent:(BOOL)isReportEvent
                  isUploading:(BOOL)isUploading
{
    self = [super init];
    if (self)
    {
        _eventTypes = eventTypes;
        _urlTemplate = urlTemplate;
        _isCustomEvent = isCustomEvent;
        _isUploading = isUploading;
        _isReportEvent = isReportEvent;
    }
    return self;
}

+ (instancetype)eventChannelWithEventTypes:(NSArray<NSString *> *)eventTypes
                               urlTemplate:(NSString *)urlTemplate
                             isCustomEvent:(BOOL)isCustomEvent
                             isReportEvent:(BOOL)isReportEvent
{
    return [[GrowingEventChannel alloc] initWithTypes:eventTypes
                                          urlTemplate:urlTemplate
                                        isCustomEvent:isCustomEvent
                                        isReportEvent:isReportEvent
                                          isUploading:NO];
}

@end



@interface GrowingEventManager()

@property (nonatomic, retain) NSMutableArray<NSObject<GrowingEventManagerObserver>*>   *allObservers;

@property (nonatomic, retain)   NSMutableArray<GrowingEvent *> * eventQueue;
@property (nonatomic, readonly, retain)   NSArray<GrowingEventChannel *> * allEventChannels;
@property (nonatomic, readonly, retain)   NSDictionary<NSString *, GrowingEventChannel *> * eventChannelDict;
@property (nonatomic, readonly, retain)   GrowingEventChannel * otherEventChannel;
@property (nonatomic, readonly) dispatch_queue_t  eventDispatch;
@property (nonatomic, retain)   dispatch_source_t reportTimer;

@property (nonatomic, retain) GrowingEventDataBase *keyEventDB;
@property (nonatomic, retain) GrowingEventDataBase *normalEventDB;
@property (nonatomic, retain) GrowingEventDataBase *customEventDB;
@property (nonatomic, retain) GrowingEventDataBase *reportEventDB;
@property (nonatomic, retain) GrowingEventDataBase *seqIdDB;
@property (nonatomic, retain) GrowingEventCounter *eventCounter;
@property (nonatomic, assign) unsigned long long uploadEventSize;
@property (nonatomic, assign) unsigned long long uploadLimitOfCellular;


@property (nonatomic, assign) BOOL uploadType_isFullData_unsafe;

@property (nonatomic, copy) NSString *ai;

@property (nonatomic, copy) NSArray<GrowingEventWhiteListItem *> * whiteListItems;
@property (nonatomic, assign) BOOL whiteListImpOnly;
@property (nonatomic, assign) BOOL enableImp;
@property (nonatomic, assign) BOOL allNetwork;

@property (nonatomic, assign) NSUInteger packageNum;

@property (nonatomic, strong) NSOperationQueue *fetchTagsQ;

@property (nonatomic, strong) NSMutableArray *cacheArray;

@end

@implementation GrowingEventManager

- (void)addObserver:(NSObject<GrowingEventManagerObserver> *)observer
{
    if (!observer)
    {
        return;
    }
    if (!self.allObservers)
    {
        self.allObservers = [[NSMutableArray alloc] init];
    }
    if ([self.allObservers containsObject:observer]) {
        
        return;
    }
    [self.allObservers addObject:observer];
}

- (void)removeObserver:(NSObject<GrowingEventManagerObserver> *)observer
{
    if (!observer)
    {
        return;
    }
    [self.allObservers removeObject:observer];
}

static GrowingEventManager *shareinstance = nil;

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareinstance = [[self alloc] initWithName:@"growing"
                                                ai:nil];
        if (getSDKDistributedMode() == GrowingDistributeForSaaS) {
            [shareinstance readWhiteListAndOptions];
        }

        shareinstance.shouldCacheEvent = YES;
        shareinstance.cacheArray = [[NSMutableArray alloc] init];
        shareinstance.inVCLifeCycleSendPageState = NO;
    });
    return shareinstance;
}

+ (BOOL)hasSharedInstance
{
    return shareinstance != nil;
}

- (dispatch_queue_t)eventDispatch
{
    static dispatch_queue_t  _eventDispatch = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _eventDispatch = dispatch_queue_create("io.growing", NULL);
        dispatch_set_target_queue(_eventDispatch,
                                  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    });

    return _eventDispatch;
}

- (NSString*)ai
{
    return _ai.length ? _ai : [GrowingInstance sharedInstance].accountID;
}

- (instancetype)initWithName:(NSString *)name ai:(NSString * _Nullable)ai
{
    self = [self init];
    if (self)
    {
        self.ai = ai;
        self.allowUploadViaCellular = YES;

        self.packageNum = g_maxBatchSize;

        [self dispathInUpload:^{
            
            self.keyEventDB = [GrowingEventDataBase databaseWithPath:getEventDBPath()
                                                                name:[name stringByAppendingString:@"keyevent"]];
            self.keyEventDB.autoFlushCount = g_maxDBCacheSize;

            self.normalEventDB = [GrowingEventDataBase databaseWithPath:getEventDBPath()
                                                                   name:[name stringByAppendingString:@"event"]];
            self.normalEventDB.autoFlushCount = g_maxDBCacheSize;

            self.customEventDB = [GrowingEventDataBase databaseWithPath:getEventDBPath()
                                                                   name:[name stringByAppendingString:@"customevent"]];

            self.reportEventDB = [GrowingEventDataBase databaseWithPath:getEventDBPath()
                                                                   name:[name stringByAppendingString:@"reportevent"]];

            self.seqIdDB = [GrowingEventDataBase databaseWithPath:getEventDBPath()
                                                             name:[name stringByAppendingString:@"eventsequenceid"]];
            self.seqIdDB.autoFlushCount = self.packageNum;
            self.eventCounter = [[GrowingEventCounter alloc] initWithDB:_seqIdDB];

            [self.keyEventDB vacuum];
        }];


        

        
        self.reportTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.eventDispatch);
        CGFloat dataUploadInterval = (g_flushInterval >= 5 ? g_flushInterval : 5); 
        dispatch_source_set_timer(self.reportTimer,
                                  dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5), 
                                  NSEC_PER_SEC * dataUploadInterval,
                                  NSEC_PER_SEC * 1);
        dispatch_source_set_event_handler(self.reportTimer, ^{
            [self timerSendEvent];
        });
        dispatch_resume(_reportTimer);
        [self dispathInUpload:^{
            
            _uploadType_isFullData_unsafe = NO;
            self.uploadType_isFullData_unsafe = YES;
        }];
        _allEventChannels = @[[GrowingEventChannel eventChannelWithEventTypes:@[@"imp"]
                                                                  urlTemplate:kGrowingEventApiTemplate_Imp
                                                                isCustomEvent:NO
                                                                isReportEvent:NO],
                              [GrowingEventChannel eventChannelWithEventTypes:@[@"vst", @"page", @"cls"]
                                                                  urlTemplate:kGrowingEventApiTemplate_PV
                                                                isCustomEvent:NO
                                                                isReportEvent:NO],
                              [GrowingEventChannel eventChannelWithEventTypes:@[@"cstm", @"pvar", @"evar", @"ppl", @"vstr"]
                                                                  urlTemplate:kGrowingEventApiTemplate_Custom
                                                                isCustomEvent:YES
                                                                isReportEvent:NO],
                              [GrowingEventChannel eventChannelWithEventTypes:@[@"activate", @"reengage"]
                                                                  urlTemplate:kGrowingEventApiTemplate_Activate
                                                                isCustomEvent:NO
                                                                isReportEvent:YES],
                              [GrowingEventChannel eventChannelWithEventTypes:nil
                                                                  urlTemplate:kGrowingEventApiTemplate_Other
                                                                isCustomEvent:NO
                                                                isReportEvent:NO],
                              ];
        _eventChannelDict = @{@"imp":self.allEventChannels[0],
                              @"vst":self.allEventChannels[1],
                              @"page":self.allEventChannels[1],
                              @"cls":self.allEventChannels[1],
                              @"cstm":self.allEventChannels[2],
                              @"pvar":self.allEventChannels[2],
                              @"evar":self.allEventChannels[2],
                              @"ppl":self.allEventChannels[2],
                              @"vstr":self.allEventChannels[2],
                              @"activate": self.allEventChannels[3],
                              @"reengage": self.allEventChannels[3],
                              };
        
        _otherEventChannel =self.allEventChannels[4];
        self.whiteListItems = [[NSMutableArray alloc] init];
        self.whiteListImpOnly = NO;
        self.enableImp =  g_enableImp;
        self.uploadLimitOfCellular = g_uploadLimitOfCellular;
        self.allNetwork = YES;
    }
    return self;
}

- (void)setUploadType_isFullData_unsafe:(BOOL)uploadType_isFullData_unsafe
{
    if (_uploadType_isFullData_unsafe != uploadType_isFullData_unsafe )
    {
        _uploadType_isFullData_unsafe = uploadType_isFullData_unsafe;
        [self reloadFromDB_unsafe];
    }
}

- (void)reloadFromDB_unsafe
{
    self.eventQueue = nil;
    [self loadFromDB_unsafe];
}

- (unsigned long long)uploadEventSize
{
    return [GrowingFileStore cellularNetworkUploadEventSize];
}

- (void)setUploadEventSize:(unsigned long long)uploadEventSize
{
    [GrowingFileStore cellularNetworkStorgeEventSize:uploadEventSize];
}

- (void)dbErrorWithError:(NSError*)error
{
    if (!error || !g_dataCounterEnable)
    {
        return;
    }
}

- (void)loadFromDB_unsafe
{
    NSInteger keyCount = self.keyEventDB.countOfEvents;
    NSInteger nCount = self.normalEventDB.countOfEvents;
    NSInteger qCount = self.eventQueue.count;

    if (self.eventQueue
        && qCount == (keyCount + nCount))
    {
        return;
    }

    self.eventQueue = [[NSMutableArray alloc] init];

    __block BOOL fillEnd = NO;
    NSError *error1 =
    [self.keyEventDB enumerateKeysAndValuesUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        GrowingEvent *event = [[GrowingEvent alloc] initWithUUID:key data:[value growingHelper_jsonObject]];
        [self.eventQueue addObject:event];
        if (self.eventQueue.count >= QUEUE_MAX_SIZE)
        {
            *stop = YES;
            fillEnd = YES;
        }
    }];
    [self dbErrorWithError:error1];


    if (!fillEnd && self.uploadType_isFullData_unsafe)
    {
        NSError *error2 =
        [self.normalEventDB enumerateKeysAndValuesUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            GrowingEvent *event = [[GrowingEvent alloc] initWithUUID:key data:[value growingHelper_jsonObject]];
            [self.eventQueue addObject:event];
            if (self.eventQueue.count >= QUEUE_MAX_SIZE)
            {
                *stop = YES;
                fillEnd = YES;
            }
        }];
        [self dbErrorWithError:error2];
    }
}

- (NSArray *)getCustomEventsToBeUploaded_unsafe
{
    if (self.customEventDB.countOfEvents == 0)
    {
        return nil;
    }

    NSMutableArray * customEventQueue = [[NSMutableArray alloc] init];

    NSError *error1 =
    [self.customEventDB enumerateKeysAndValuesUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        GrowingEvent *event = [[GrowingEvent alloc] initWithUUID:key data:[value growingHelper_jsonObject]];
        [customEventQueue addObject:event];
        if (customEventQueue.count >= self.packageNum)
        {
            *stop = YES;
        }
    }];
    [self dbErrorWithError:error1];

    return customEventQueue;
}

- (NSArray *)getReportEventsToBeUploaded_unsafe
{
    if (self.reportEventDB.countOfEvents == 0)
    {
        return nil;
    }

    NSMutableArray * reportEventQueue = [[NSMutableArray alloc] init];

    NSError *error1 =
    [self.reportEventDB enumerateKeysAndValuesUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        GrowingEvent *event = [[GrowingEvent alloc] initWithUUID:key data:[value growingHelper_jsonObject]];
        [reportEventQueue addObject:event];
        if (reportEventQueue.count >= self.packageNum)
        {
            *stop = YES;
        }
    }];
    [self dbErrorWithError:error1];

    return reportEventQueue;
}


- (void)timerSendEvent
{
    [self sendEvents];
}

- (void)dispathInUpload:(void(^_Nullable)(void))block
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == self.eventDispatch)
#pragma clang diagnostic pop
    {
        block();
    }
    else
    {
        dispatch_async(self.eventDispatch,block);
    }
}

- (BOOL)triggerNodeNeedTrack:(id<GrowingNode>)node
               witheventType:(GrowingEventType)eventType
                   withChild:(BOOL)withChild
{
    for (id<GrowingEventManagerObserver> obj in self.allObservers)
    {
       if ([obj respondsToSelector:@selector(growingEventManagerShouldTriggerNode:eventType:withChild:)])
       {
           if (NO == [obj growingEventManagerShouldTriggerNode:node eventType:eventType withChild:withChild])
           {
               return NO;
           }
       }
    }

    
    for (id<GrowingEventManagerObserver> obj in self.allObservers)
    {
        if ([obj respondsToSelector:@selector(growingEventManagerWillTriggerNode:eventType:withChild:)])
        {
            [obj growingEventManagerWillTriggerNode:node
                                          eventType:eventType
                                          withChild:withChild];
        }
    }
    return YES;

}

- (void)addEvent:(GrowingEvent *)event
        thisNode:(id<GrowingNode> _Nullable)thisNode
     triggerNode:(id<GrowingNode>)triggerNode
     withContext:(id<GrowingAddEventContext>)context
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    if (SDKDoNotTrack()) {
        return;
    }
    
    if (!event) {
        return;
    }

    [GrowingDispatchManager dispatchInMainThread:^{

        for (NSObject<GrowingEventManagerObserver> * obj in self.allObservers)
        {
            if ([obj respondsToSelector:@selector(growingEventManagerShouldAddEvent:thisNode:triggerNode:withContext:)])
            {
                BOOL should =
                [obj growingEventManagerShouldAddEvent:event
                                              thisNode:thisNode
                                           triggerNode:triggerNode
                                           withContext:context];
                if (!should)
                {
                    return;
                }
            }
        }

        for (NSObject<GrowingEventManagerObserver> * obj in self.allObservers)
        {
            if ([obj respondsToSelector:@selector(growingEventManagerWillAddEvent:thisNode:triggerNode:withContext:)])
            {
                [obj growingEventManagerWillAddEvent:event
                                            thisNode:thisNode
                                         triggerNode:triggerNode
                                         withContext:context];
            }
        }

        [self handleEvent:event];

    }];

    if ([event.dataDict[@"t"] isEqualToString:@"vst"]
            && [[GrowingCustomField shareInstance] isOnlyCoreKit]) {
        [[GrowingCustomField shareInstance] sendGIOFakePageEvent];
    }

}

- (void)handleEvent:(GrowingEvent *)event
{
    GrowingEvent *dbEvent = event.copy;
    
    if ([event.dataDict[@"t"] isEqualToString:@"cstm"] && [UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        @weakify(self);
        [self dispathInUpload:^{
            @strongify(self);
            [self writeToDBWithEvent:dbEvent];
        }];
        return;
    }

    
    
    if (self.shouldCacheEvent) {

        [self.cacheArray addObject:dbEvent];

    } else {
        static BOOL resetPagetm = NO;
        if (!resetPagetm && [GrowingEventManager shareInstance].lastPageEvent) {
            GrowingEvent *lastPageEvent = [GrowingEventManager shareInstance].lastPageEvent;
            lastPageEvent.dataDict[@"tm"] = event.dataDict[@"tm"];
            lastPageEvent.dataDict[@"ptm"] = event.dataDict[@"tm"];
            lastPageEvent.dataDict[@"s"] = event.dataDict[@"s"];
        }
        resetPagetm = YES;

        @weakify(self);
        [self dispathInUpload:^{
            @strongify(self);
            if (self.cacheArray.count) {
                for (int i = 0; i < self.cacheArray.count; i++) {
                    GrowingEvent *cacheEvent = self.cacheArray[i];
                    [cacheEvent.dataDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL * stop) {

                        if ([key isEqualToString:@"tm"]) {
                            cacheEvent.dataDict[@"tm"] = dbEvent.dataDict[@"tm"];
                        } else if ([key isEqualToString:@"ptm"]) {
                            cacheEvent.dataDict[@"ptm"] = dbEvent.dataDict[@"tm"];
                        } else if ([key isEqualToString:@"s"]) {
                            cacheEvent.dataDict[@"s"] = dbEvent.dataDict[@"s"];
                        }

                    }];
                    [self writeToDBWithEvent:cacheEvent];
                }
                [self.cacheArray removeAllObjects];
            }
            [self writeToDBWithEvent:dbEvent];
        }];
    }
}

- (void)writeToDBWithEvent:(GrowingEvent *)event
{
    
    GrowingEventDestiny eventDestiny = [self destinyOfEvent:event];

    NSString* eventType = event.dataDict[@"t"];

    event.dataDict[@"gesid"] = [_eventCounter nextGlobalEventIdFor:eventType];
    event.dataDict[@"esid"] = [_eventCounter nextEventIdFor:eventType];

    GrowingEventChannel * eventChannel = self.eventChannelDict[event.dataDict[@"t"]] ?: self.otherEventChannel;
    BOOL isCustomEvent = eventChannel.isCustomEvent;
    BOOL isReportEvent = eventChannel.isReportEvent;

    if (eventDestiny == GrowingDropEvent)
    {
        return;
    }

    if (self.eventQueue.count >= QUEUE_FILL_SIZE)
    {
        
    }
    else if (!isCustomEvent && !isReportEvent && event != nil) 
    {
        
        if (eventDestiny == GrowingKeyEvent)
        {
            [self.eventQueue addObject:event];
        }
        
        else if (self.uploadType_isFullData_unsafe)
        {
            [self.eventQueue addObject:event];
        }
    }

    NSError *error = nil;
    GrowingEventDataBase *db = (isCustomEvent ? self.customEventDB : (eventDestiny == GrowingKeyEvent ? self.keyEventDB : self.normalEventDB));

    if (isReportEvent) {
        db = self.reportEventDB;
    }

    NSString *eventJsonString = [[NSString alloc] initWithJsonObject_growingHelper:event.dataDict];
    [db setValue:eventJsonString
          forKey:event.uuid
           error:g_dataCounterEnable ? &error : nil ];

    [self dbErrorWithError:error];
    
    if (self.reportHandler &&
        event.dataDict &&
        [NSJSONSerialization isValidJSONObject:event.dataDict]) {
                NSDictionary *eventObject = [event.dataDict copy];
                self.reportHandler(eventObject);
    }
}

- (BOOL)preDetermineShouldNotTrackImp {
    
    
    return !self.whiteListImpOnly && !self.enableImp;
}


- (GrowingEventDestiny)destinyOfEvent:(GrowingEvent*)event
{
    if ([event.dataDict[@"t"] isEqualToString:@"imp"])
    {
        
        if (self.whiteListImpOnly)
        {
            BOOL isWhiteListEvent = [self isMatchingAnyTag:event];
            if (self.allNetwork)
            {
                if (isWhiteListEvent)
                {
                    return GrowingKeyEvent; 
                }
                else
                {
                    return GrowingDropEvent; 
                }
            }
            else
            {
                if (isWhiteListEvent)
                {
                    return GrowingNormalEvent; 
                }
                else
                {
                    return GrowingDropEvent; 
                }
            }
        }
        else
        {
            if (self.enableImp)
            {
                if (self.allNetwork)
                {
                    return GrowingKeyEvent; 
                }
                else
                {
                    return GrowingNormalEvent; 
                }
            }
            else
            {
                return GrowingDropEvent; 
            }
        }
    }
    else
    {
        
        return GrowingKeyEvent;
    }
}

- (void)flushDB
{
    [self.keyEventDB flush];
    [self.normalEventDB flush];
    
    [self.seqIdDB flush];

}

- (void)removeEvents_unsafe:(NSArray<__kindof GrowingEvent *>*)events forChannel:(GrowingEventChannel *)channel
{
    if (channel.isReportEvent)
    {
        for (NSInteger i = 0 ; i < events.count ; i++)
        {
            GrowingEvent *event = events[i];
            if ([event.dataDict[@"t"] isEqualToString:@"activate"]) {
                GrowingAsaFetcher.status = GrowingAsaFetcherStatusCompleted;
                [GrowingFileStore setDidUploadActivate:YES];
            }
            [self.reportEventDB setValue:nil forKey:events[i].uuid];
        }
    }
    if (channel.isCustomEvent)
    {
        for (NSInteger i = 0 ; i < events.count ; i++)
        {
            [self.customEventDB setValue:nil forKey:events[i].uuid];
        }
    }
    else
    {
        [self.eventQueue removeObjectsInArray:events];

        for (NSInteger i = 0 ; i < events.count; i++)
        {
            [self.keyEventDB setValue:nil forKey:events[i].uuid];
            [self.normalEventDB setValue:nil forKey:events[i].uuid];
        }

        if (self.eventQueue.count <= QUEUE_FILL_SIZE)
        {
            [self loadFromDB_unsafe];
        }
    }
}


- (void)sendEvents
{
    [self dispathInUpload:^{
        [self flushDB];
        for (GrowingEventChannel * channel in self.allEventChannels)
        {
            [self sendEventsOfChannel_unsafe:channel];
        }
    }];
}


- (void)sendEventsOfChannel_unsafe:(GrowingEventChannel *)channel
{
    if (self.ai.length == 0)
    {
        GIOLogError(@"No valid AI (channel = %lu).", (unsigned long)[self.allEventChannels indexOfObject:channel]);
        return;
    }
    if (!channel.isCustomEvent && !channel.isReportEvent && self.eventQueue.count == 0)
    {
        return;
    }
    
    if (![GrowingNetworkPreflight isSucceed]) {
        return;
    }

    if (channel.isUploading) {
        
        
        return;
    }

    [[GROW_KDNetworkInterfaceManager sharedInstance] updateInterfaceInfo];

    BOOL isViaCellular = NO;
    
    if (   ![GROW_KDNetworkInterfaceManager sharedInstance].WWANValid
        && ![GROW_KDNetworkInterfaceManager sharedInstance].WiFiValid)
    {
        
        GIOLogDebug(@"No availabel Internet connection, delay upload (channel = %lu).", (unsigned long)[self.allEventChannels indexOfObject:channel]);
        return;
    }
    else
    {
        
        if ([GROW_KDNetworkInterfaceManager sharedInstance].WiFiValid)
        {
            BOOL someChannelIsUsingEventQueue = NO;
            for (GrowingEventChannel * channel in self.allEventChannels)
            {
                if (!channel.isCustomEvent && !channel.isReportEvent && channel.isUploading)
                {
                    someChannelIsUsingEventQueue = YES;
                    break;
                }
            }
            if (!someChannelIsUsingEventQueue)
            {
                self.uploadType_isFullData_unsafe = YES;
            }
        }
        
        else if (self.allowUploadViaCellular && self.uploadEventSize < self.uploadLimitOfCellular)
        {
            self.uploadType_isFullData_unsafe = NO;
            GIOLogDebug(@"Upload key data with mobile network (channel = %lu).", (unsigned long)[self.allEventChannels indexOfObject:channel]);
            isViaCellular = YES;
        }
        
        else
        {
            GIOLogDebug(@"Mobile network is forbidden. upload later (channel = %lu).", (unsigned long)[self.allEventChannels indexOfObject:channel]);
            return;
        }
    }

    NSArray *events = [self getEventsToBeUploaded_unsafe:channel];
    if (channel.isReportEvent) {
        events = [self uploadAsaDataInActivateEvent:events];
    }
    if (events.count == 0)
    {
        return;
    }
    channel.isUploading = YES;
    unsigned long long stm = GROWGetTimestamp().unsignedLongLongValue;
    NSArray * compressedEvents = [self compressEvents:events];
    GIOLogDebug(@"(channel = %lu)\n%@", (unsigned long)[self.allEventChannels indexOfObject:channel], compressedEvents);
    NSString *urlString = channel.isReportEvent ? (kGrowingReportApi(channel.urlTemplate, self.ai, stm)) : (kGrowingEventApiV3(channel.urlTemplate, self.ai, stm));

    if (channel.isReportEvent) {
        [self sendReportChannelWithCompressedEvents:compressedEvents
                                       originEvents:events
                                         forChannel:channel
                                          UrlString:urlString
                                      isViaCellular:isViaCellular
                                             andSTM:stm];
        return;
    }

    __block unsigned long long sendBufferSize = 0;
    void(^outsizeBlock)(unsigned long long outsize) = ^(unsigned long long outsize) {
        sendBufferSize = outsize;
    };

    [[GrowingEventModel shareInstanceWithType:GrowingModelTypeEvent]
            uploadEvents:compressedEvents
             toURLString:urlString
          diagnoseEnable:g_dataCounterEnable
                  withAI:self.ai
                  andSTM:stm
                 outsizeBlock:outsizeBlock
                 succeed:^{
                     [self dispathInUpload:^{

                         if (isViaCellular)
                         {
                             self.uploadEventSize += sendBufferSize;
                         }
                         [self removeEvents_unsafe:events forChannel:channel];
                         channel.isUploading = NO;
                         
                         if (channel.isCustomEvent && self.customEventDB.countOfEvents >= self.packageNum)
                         {
                             [self sendEvents];
                         }

                         if (!channel.isCustomEvent && !channel.isReportEvent && self.eventQueue.count >= self.packageNum)
                         {
                             [self sendEvents];
                         }
                     }];
                 }
                    fail:^(NSError *error) {
                        [self dispathInUpload:^{
                            channel.isUploading = NO;
                        }];
                    }];
}

- (NSArray *)uploadAsaDataInActivateEvent:(NSArray *)events {
    GrowingEvent *activate = nil;
    for (int i = 0; i < events.count; i++) {
        GrowingEvent *event = events[i];
        if ([event.dataDict[@"t"] isEqualToString:@"activate"]) {
            activate = event;
            break;
        }
    }
    
    if (events.count == 0 || activate == nil) {
        if (![GrowingDeviceInfo currentDeviceInfo].isNewInstall
            && !GrowingFileStore.didUploadActivate) {
            GrowingAsaFetcher.status = GrowingAsaFetcherStatusCompleted;
            [GrowingFileStore setDidUploadActivate:YES];
        }
        return events;
    }
    
    if (GrowingAsaFetcher.status == GrowingAsaFetcherStatusFetching) {
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:events];
        [array removeObject:activate];
        return array;
    } else {
        if (GrowingAsaFetcher.asaData.allKeys.count > 0) {
            activate.dataDict[@"asa"] = GrowingAsaFetcher.asaData;
        }
        
        if (GrowingAsaFetcher.status == GrowingAsaFetcherStatusFailure) {
            
            [GrowingAsaFetcher retry];
        }
    }
    
    return events;
}

- (void)sendReportChannelWithCompressedEvents:(NSArray *)compressedEvents
                                 originEvents:(NSArray<GrowingEvent *> *)originEvents
                                   forChannel:(GrowingEventChannel *)channel
                                    UrlString:(NSString *)urlString
                                isViaCellular:(BOOL)isViaCellular
                                       andSTM:(unsigned long long)stm {

    GrowingBaseModel *shareModel = [GrowingBaseModel shareInstanceWithType:GrowingModelTypeEvent];

    __block unsigned long long sendBufferSize = 0;
    void(^outsizeBlock)(unsigned long long outsize) = ^(unsigned long long outsize) {\
        sendBufferSize = outsize;
    };

    [shareModel startTaskWithURL:urlString
                      httpMethod:@"POST"
                      parameters:compressedEvents
                    outsizeBlock:outsizeBlock
                   configRequest:nil
                  isSendingEvent:YES
                             STM:stm
                timeoutInSeconds:15
                   isFromHTTPDNS:NO
                         success:^(NSHTTPURLResponse *httpResponse, NSData *data) {

        [self dispathInUpload:^{

            if (isViaCellular) {
                self.uploadEventSize += sendBufferSize;
            }
            [self removeEvents_unsafe:originEvents forChannel:channel];
            channel.isUploading = NO;
            if (channel.isReportEvent && self.reportEventDB.countOfEvents >= self.packageNum) {
                [self sendEvents];
            }
        }];

    } failure:^(NSHTTPURLResponse *httpResponse, NSData *data, NSError *error) {
        [self dispathInUpload:^{
            channel.isUploading = NO;
        }];
    }];
}

- (NSArray<GrowingEvent *> *)getEventsToBeUploaded_unsafe:(GrowingEventChannel *)channel
{
    if (channel.isReportEvent)
    {
        return [self getReportEventsToBeUploaded_unsafe];
    }
    else if (channel.isCustomEvent)
    {
        return [self getCustomEventsToBeUploaded_unsafe];
    }
    else
    {
        NSMutableArray<GrowingEvent *> * events = [[NSMutableArray alloc] initWithCapacity:self.eventQueue.count];
        NSArray<NSString *> * eventTypes = channel.eventTypes;
        const NSUInteger eventTypesCount = eventTypes.count;
        NSUInteger count = 0;
        for (GrowingEvent * e in self.eventQueue)
        {
            if (   (eventTypesCount == 0 && self.eventChannelDict[e.dataDict[@"t"]] == nil) 
                || (eventTypesCount > 0 && [eventTypes indexOfObject:e.dataDict[@"t"]] != NSNotFound)) 
            {
                [events addObject:e];
                count++;
                if (count >= self.packageNum)
                {
                    break;
                }
            }
        }
        return events;
    }
}

- (NSArray*)compressEvents:(NSArray<GrowingEvent*>*)events
{
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] init];

    for (GrowingEvent *event in events)
    {
        NSDictionary *e = [event.dataDict copy];
        NSString *type = e[@"t"];
        if ([type isEqualToString:@"imp"] ||
            [type isEqualToString:@"clck"] ||
            [type isEqualToString:@"chng"] ||
            [type isEqualToString:@"sbmt"])
        {
            NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%@-%@-%@-%@",
                             e[@"u"],
                             e[@"p"],
                             e[@"ptm"],
                             e[@"s"],
                             e[@"t"],
                             e[@"r"],
                             e[@"d"],
                             e[@"pg"]
                             ];
            NSMutableDictionary *impDict = dataDict[key];
            NSMutableArray *impElements = impDict[@"e"];
            if (!impDict)
            {
                impDict = [[NSMutableDictionary alloc] init];
                dataDict[key] = impDict;
                [dataArray addObject:impDict];
                NSString *cs1 = e[@"cs1"];
                if (cs1.length > 0) {
                    impDict[@"cs1"] = cs1;
                }
                impDict[@"p"] = e[@"p"];
                impDict[@"ptm"] = e[@"ptm"];
                impDict[@"s"] = e[@"s"];
                impDict[@"t"] = e[@"t"];
                impDict[@"d"] = e[@"d"];
                impDict[@"tm"] = e[@"tm"];
                impDict[@"q"] = e[@"q"];
                impDict[@"lat"] = e[@"lat"];
                impDict[@"lng"] = e[@"lng"];
                impDict[@"r"] = e[@"r"];
                impDict[@"pg"] = e[@"pg"];
                impDict[@"u"] = e[@"u"];
                impElements = [[NSMutableArray alloc] init];
                impDict[@"e"] = impElements;
            }

            NSMutableDictionary *element = [[NSMutableDictionary alloc] init];
            element[@"tm"] = e[@"tm"];
            element[@"v"] = e[@"v"];
            element[@"h"] = e[@"h"];
            if (e[@"idx"] != nil)
            {
                element[@"idx"] = e[@"idx"];
            }
            element[@"x"] = e[@"x"];
            element[@"obj"] = e[@"obj"];
            element[@"gesid"] = e[@"gesid"];
            element[@"esid"] = e[@"esid"];
            [impElements addObject:element];
        }
        else
        {
            if ([type isEqualToString:@"page"]) {
                NSMutableDictionary *copye = [NSMutableDictionary dictionaryWithDictionary:e];
                [copye removeObjectForKey:@"ptm"];
                e = copye;
            }
            [dataArray addObject:e];
        }
    }

    return dataArray;
}

- (void)clearAllEvents
{
    self.eventQueue = [[NSMutableArray alloc] init];
    [self dispathInUpload:^() {
        [self.keyEventDB clearAllItems];
        [self.normalEventDB clearAllItems];
        [self.customEventDB clearAllItems];
        [self.reportEventDB clearAllItems];
    }];
}

- (NSURL *)generateWhiteListAndOptionsURL
{
    
    
    unsigned long long timestamp = [GROWGetTimestamp() unsignedLongLongValue];
    NSString * ai = [GrowingInstance sharedInstance].accountID;
    if (ai.length == 0)
    {
        return nil;
    }
    NSString * d = [GrowingDeviceInfo currentDeviceInfo].bundleID;
    NSString * cv = [GrowingDeviceInfo currentDeviceInfo].appShortVersion;
    NSString * av = [Growing sdkVersion];
    NSString * signText = [NSString stringWithFormat:@"api=/products/%@/ios/%@/settings&av=%@&cv=%@&timestamp=%llu",
                           ai, d, av, cv,timestamp];
    NSString * hash = signText.growingHelper_sha1;

    NSString * urlString = [NSString stringWithFormat:@"%@/products/%@/ios/%@/settings?&av=%@&cv=%@&timestamp=%llu&sign=%@",
                            [GrowingNetworkConfig.sharedInstance tagsHost], ai, d,  av, cv,timestamp, hash];
    return [NSURL URLWithString:urlString];
}

- (void)readWhiteListAndOptions
{
    NSString * contentKey = @"white_list_and_options";
    NSString * etagKey = @"white_list_and_options_etag";
    GrowingEventDataBase * db = [GrowingEventDataBase databaseWithName:@"white_list_and_options_table"];
    NSDictionary * content = [[db valueForKey:contentKey] growingHelper_dictionaryObject];
    NSString * etag = [db valueForKey:etagKey];

    [self readOptions_unsafe:content];
    @weakify(self);
    [self dispathInUpload:^{
        @strongify(self);
        [self readWhiteList_unsafe:content];
        NSURL * url = self.generateWhiteListAndOptionsURL;
        if (url == nil)
        {
            return;
        }
        NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
        urlRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        [urlRequest setTimeoutInterval:15];
        if (etag.length > 0)
        {
            [urlRequest setValue:etag forHTTPHeaderField:@"If-None-Match"];
        }
        self.fetchTagsQ = [[NSOperationQueue alloc] init];
        self.fetchTagsQ.name = @"fetchTags";
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        @weakify(self);
        [NSURLConnection sendAsynchronousRequest:urlRequest
                                           queue:self.fetchTagsQ
                               completionHandler:^(NSURLResponse * response, NSData * data, NSError * connectionError) {
                                   @strongify(self);
                                   
                                   if ([response isKindOfClass:[NSHTTPURLResponse class]])
                                   {
                                       NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
                                       NSInteger statusCode = httpResponse.statusCode;
                                       if (statusCode == 304)
                                       {
                                           
                                           return;
                                       }
                                       else if (statusCode == 200)
                                       {
                                           NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                           NSDictionary * content = [string growingHelper_dictionaryObject];
                                           NSString * etag = [httpResponse.allHeaderFields valueForKey:@"Etag"];
                                           
                                           [self readOptions_unsafe:content];
                                           [self dispathInUpload:^{
                                               [self readWhiteList_unsafe:content];
                                               [db setValue:string forKey:contentKey];
                                               [db setValue:etag forKey:etagKey];
                                           }];
                                       }
                                   }
                               }];
    }];
    SEL sel = @selector(custom_cancel);
    NSMethodSignature* sig = [self methodSignatureForSelector:sel];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:self];
    [invocation setSelector:sel];
    NSTimer *timer = [NSTimer timerWithTimeInterval:15 invocation:invocation repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}
- (void)custom_cancel
{
    if(self.fetchTagsQ)
    {
       [self.fetchTagsQ cancelAllOperations];
    }
}

- (void)readOptions_unsafe:(NSDictionary *)dict
{
    if (dict.count == 0)
    {
        return;
    }

    
    NSNumber * allDisabled = dict[@"disabled"];
    if ([allDisabled isKindOfClass:[NSNumber class]])
    {
        g_doNotTrack = [allDisabled boolValue];
    }

    NSNumber * whiteListImpOnly = dict[@"throttle"];
    if ([whiteListImpOnly isKindOfClass:[NSNumber class]])
    {
        self.whiteListImpOnly = [whiteListImpOnly boolValue];
    }

    NSNumber * enableImp = dict[@"imp"];
    if ([enableImp isKindOfClass:[NSNumber class]])
    {
        self.enableImp = ([enableImp boolValue] && g_enableImp);
    }

    NSNumber * allNetwork = dict[@"net"];
    if ([allNetwork isKindOfClass:[NSNumber class]])
    {
        self.allNetwork = [allNetwork boolValue];
    }

    NSNumber * sampling = dict[@"sampling"];
    if ([sampling isKindOfClass:[NSNumber class]])
    {
        [GrowingInstance updateSampling:sampling.floatValue];
    }
}

+ (NSString *)jointField:(NSString *)fieldA withField:(NSString *)fieldB
{
    return [NSString stringWithFormat:@"%@%@%@", fieldA ?: @"", FIELD_SEPARATOR, fieldB ?: @""];
}

- (void)readWhiteList_unsafe:(NSDictionary *)dict
{
    NSArray<NSDictionary *> * tags = dict[@"tags"];
    if (![tags isKindOfClass:[NSArray class]])
    {
        return;
    }
    NSMutableArray<GrowingEventWhiteListItem *> * parsedTags = [[NSMutableArray alloc] init];
    NSString * currentDomain = [GrowingDeviceInfo currentDeviceInfo].bundleID;
    NSString * currentH5DomainPrefix = [[self class] jointField:currentDomain withField:nil];
    for (NSDictionary * tag in tags)
    {
        if (![tag isKindOfClass:[NSDictionary class]])
        {
            continue;
        }
        NSString * domain = tag[@"d"];
        if (![domain isEqualToString:currentDomain] && ![domain hasPrefix:currentH5DomainPrefix])
        {
            continue;
        }
        GrowingEventWhiteListItem * item = [[GrowingEventWhiteListItem alloc] init];
        item.domain = domain;

        item.pageName = tag[@"p"];
        item.xpath = tag[@"x"];
        item.hyperlink = tag[@"h"];
        item.content = tag[@"v"];

        NSNumber * index = tag[@"idx"];
        if (index != nil)
        {
            item.index = index;
            item.indexString = [NSString stringWithFormat:@"%ld", (unsigned long)index.unsignedIntegerValue];
        }
        [parsedTags addObject:item];
    }

    self.whiteListItems = parsedTags;
}

- (BOOL)isMatchingAnyTag:(GrowingEvent *)event
{
    __block NSString * plainXPath = nil;
    void (^updatePlainXPath)(NSString * x) = ^void(NSString * x) {
        plainXPath = x;
    };
    NSString * xpath = event.dataDict[@"x"];
    for (GrowingEventWhiteListItem * item in self.whiteListItems)
    {
        if (![item.domain isEqualToString:event.dataDict[@"d"]])
        {
            continue;
        }
        if (item.content.length > 0 && ![item.content isEqualToString:event.dataDict[@"v"]])
        {
            continue;
        }
        if (item.hyperlink.length > 0 && ![item.hyperlink isEqualToString:event.dataDict[@"h"]])
        {
            continue;
        }
        if (item.pageName.length > 0 && ![event.dataDict[@"p"] growingHelper_matchWildly:item.pageName])
        {
            continue;
        }
        if (item.index != nil && ![item.indexString isEqualToString:event.dataDict[@"idx"]])
        {
            continue;
        }

        
        if (xpath.length == 0) {
            xpath = @"";
        }
        if (plainXPath.length == 0) {
            plainXPath = @"";
        }
        if (item.xpath.length == 0) {
            item.xpath = @"";
        }
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:xpath, @"0", plainXPath, @"1", item.xpath, @"2", nil];
        if (updatePlainXPath) {
            [params setValue:updatePlainXPath forKey:@"3"];
        }
        NSNumber *boolNumber = [[GrowingMediator sharedInstance] performClass:@"GrowingNodeManager" action:@"isElementXPath:orElementPlainXPath:matchToTagXPath:updatePlainXPathBlock:" params:params];


        if (!boolNumber.boolValue)
        {
            continue;
        }
        
        return YES;
    }
    return NO;
}

@end
