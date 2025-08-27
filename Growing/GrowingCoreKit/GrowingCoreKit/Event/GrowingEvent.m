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


#import "GrowingEvent.h"
#import <UIKit/UIKit.h>
#import "GrowingInstance.h"
#import "GrowingDeviceInfo.h"
#import "GrowingCustomField.h"
#import "NSDictionary+GrowingHelper.h"
#import "NSString+GrowingHelper.h"
#import "UIApplication+Growing.h"
#import "UIApplication+GrowingNode.h"
#import "GROW_KDNetworkInterfaceManager.h"
#import "GrowingDispatchManager.h"
#import "GrowingEventManager.h"
#import "GrowingVersionManager.h"

#define RETURN_NAME(NAME,ENUMVALUE,DESP)  \
if (type == GrowingEventType ## NAME )      \
{   \
    return DESP;\
}\

NSString* _Nullable GrowingEventTypeGetDescription(GrowingEventType type)
{
    GROWING_EVENT_LIST(RETURN_NAME)
    return @"";
}

@interface GrowingEvent()

@end


@implementation GrowingEvent

+ (BOOL)nodeShouldTriggered:(id<GrowingNode>)triggerNode
                   withType:(GrowingEventType)type
                  withChild:(BOOL)withChild
{
    return ![GrowingEventManager hasSharedInstance] ||
    [[GrowingEventManager shareInstance] triggerNodeNeedTrack:triggerNode
                                                witheventType:type
                                                    withChild:withChild];
}

+ (BOOL)hasExtraFields
{
    return YES; 
}

- (void)sendWithTriggerNode:(id<GrowingNode>)triggerNode
                   thisNode:(id<GrowingNode>)thisNode
           triggerEventType:(GrowingEventType)eventType
                    context:(id<GrowingAddEventContext>)context
{
    _eventType = eventType;
    [[GrowingEventManager shareInstance] addEvent:self
                                         thisNode:thisNode
                                      triggerNode:triggerNode
                                      withContext:context];
}

- (instancetype)initWithUUID:(NSString*)uuid data:(NSDictionary*)data
{
    self = [super init];
    if (self)
    {
        _uuid = uuid;
        self.dataDict = [[NSMutableDictionary alloc] initWithDictionary:data];
        if (data.count == 0 && self.class.hasExtraFields)
        {
            [self assignLocationIfAny];
        }
    }
    return self;
}

- (_Nullable instancetype)initWithUUID:(NSString* _Nonnull)uuid withType:(GrowingEventType)type data:(NSDictionary* _Nullable)data {

    self = [self initWithUUID:uuid data:data];
    _eventType = type;
    return self;

}

- (instancetype)initWithTimestamp:(NSNumber *)tm
{
    self = [self initWithUUID:[[NSUUID UUID] UUIDString] data:nil];
    if (self)
    {
        self.dataDict[@"s"]  = [GrowingDeviceInfo currentDeviceInfo].sessionID ?: @"";
        if (tm)
        {
            self.dataDict[@"tm"] = tm;
        }
        else
        {
            self.dataDict[@"tm"] = GROWGetTimestamp();
        }
        self.dataDict[@"t"] = [self eventTypeKey];
        self.dataDict[@"d"] = [GrowingDeviceInfo currentDeviceInfo].bundleID;
        if ([GrowingCustomField shareInstance].cs1.length > 0)
        {
            self.dataDict[@"cs1"] = [GrowingCustomField shareInstance].cs1;
        }
        self.dataDict[@"u"] = [GrowingDeviceInfo currentDeviceInfo].deviceIDString ?: @"";
    }
    return self;
}

- (instancetype)init
{
    return [self initWithTimestamp:nil];
}

+ (instancetype)event
{
    return [[self alloc] init];
}

+ (instancetype)eventWithTimestamp:(NSNumber *)tm
{
    return [[self alloc] initWithTimestamp:tm];
}

- (NSString*)description
{
    return self.dataDict.description;
}

- (NSString*)eventTypeKey
{
    return @"";
}


- (void)assignLocationIfAny
{
    CLLocation * gpsLocation = [GrowingInstance getLocation];
    if (gpsLocation != nil)
    {
        self.dataDict[@"lat"] = @(gpsLocation.coordinate.latitude);
        self.dataDict[@"lng"] = @(gpsLocation.coordinate.longitude);
    }
}


- (void)assignRadioType
{
    
    GROW_KDNetworkInterfaceManager * network = [GROW_KDNetworkInterfaceManager sharedInstance];
    [network updateInterfaceInfo];
    if (network.isUnknown)
    {
        self.dataDict[@"r"] = @"UNKNOWN";
    }
    else if (network.WiFiValid)
    {
        self.dataDict[@"r"] = @"WIFI";
    }
    else if (network.WWANValid)
    {
        self.dataDict[@"r"] = @"CELL";
    }
    else
    {
        self.dataDict[@"r"] = @"NONE";
    }
}

- (instancetype)copyWithZone:(NSZone *)zone {

    GrowingEvent *event = [[[self class] allocWithZone:zone] initWithUUID:self.uuid.copy withType:self.eventType data:[[NSMutableDictionary alloc] initWithDictionary:self.dataDict copyItems:YES]];
    return event;
}

@end

@implementation GrowingAppSimpleEvent

- (GrowingEventType)simpleEventType
{
    return GrowingEventTypeNotInit;
}

+ (void)send
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    
    if (SDKDoNotTrack()) {
        return;
    }
    
    GrowingAppSimpleEvent *event = [[self alloc] init];
    if (NO == [GrowingEvent nodeShouldTriggered:nil
                                       withType:[event simpleEventType]
                                      withChild:NO])
    {
        return ;
    }

    [event sendWithTriggerNode:nil
                      thisNode:nil
              triggerEventType:[event simpleEventType]
                       context:nil];
}

@end


@implementation GrowingVisitEvent

- (GrowingEventType)simpleEventType
{
    return GrowingEventTypeAppLifeCycleAppNewVisit;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        GrowingDeviceInfo *deviceInfo = [GrowingDeviceInfo currentDeviceInfo];
        self.dataDict[@"l"]  = deviceInfo.language;
        self.dataDict[@"dm"] = deviceInfo.deviceModel;
        self.dataDict[@"ph"] = deviceInfo.isPhone;
        self.dataDict[@"db"] = deviceInfo.deviceBrand;
        self.dataDict[@"os"] = deviceInfo.systemName;
        self.dataDict[@"osv"]= deviceInfo.systemVersion;
        self.dataDict[@"sn"] = deviceInfo.displayName;
        self.dataDict[@"d"]  = deviceInfo.bundleID;
        self.dataDict[@"cv"] = deviceInfo.appShortVersion;
        self.dataDict[@"v"]  = deviceInfo.urlScheme;
        self.dataDict[@"ui"] = deviceInfo.idfa;
        self.dataDict[@"iv"] = deviceInfo.idfv;
        self.dataDict[@"av"] = [Growing sdkVersion];
        self.dataDict[@"fv"] = [GrowingVersionManager versionInfo];


        CGSize size = [UIScreen mainScreen].bounds.size;
        CGFloat scale = [UIScreen mainScreen].scale;

        if (size.height < size.width)
        {
            
            CGFloat temp = size.width;
            size.width = size.height;
            size.height = temp;
        }

        size.width *= scale;
        size.height *= scale;

        size.width += 0.5f;
        size.height += 0.5f;

        self.dataDict[@"sw"] = [NSNumber numberWithInteger:size.width];
        self.dataDict[@"sh"] = [NSNumber numberWithInteger:size.height];

        
        [GrowingEventManager shareInstance].vstEvent = self;
    }
    return self;
}

- (NSString*)eventTypeKey
{
    return @"vst";
}

+ (void)onGpsLocationChanged:(CLLocation * _Nullable)location
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingVisitEvent *vstEvent = [GrowingEventManager shareInstance].vstEvent;
    if (location != nil &&
        vstEvent.dataDict[@"lat"] == nil &&
        vstEvent.dataDict[@"lng"] == nil)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            vstEvent.dataDict[@"lat"] = @(location.coordinate.latitude);
            vstEvent.dataDict[@"lng"] = @(location.coordinate.longitude);
            [[GrowingEventManager shareInstance] addEvent:vstEvent
                                                 thisNode:nil
                                              triggerNode:nil
                                              withContext:nil];
        });
    }
}


@end

@implementation GrowingCustomRootEvent

+ (BOOL)hasExtraFields
{
    return NO; 
}

@end
