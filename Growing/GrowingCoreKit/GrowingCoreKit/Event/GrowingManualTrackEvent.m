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


#import "GrowingManualTrackEvent.h"
#import "GrowingInstance.h"
#import "GrowingEventManager.h"
#import "GrowingGlobal.h"
#import "GrowingDeviceInfo.h"
#import "NSString+GrowingHelper.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingEBManualTrackEvent.h"
#import "GrowingEventBus.h"
#import "GrowingCocoaLumberjack.h"



@implementation GrowingEvarEvent

- (NSString*)eventTypeKey
{
    return @"evar";
}

+ (void)sendEvarEvent:(NSDictionary<NSString *, NSObject *> * _Nonnull)evar
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingEvarEvent * event = [[GrowingEvarEvent alloc] init];
    event.dataDict[@"var"] = evar;
    [[GrowingEventManager shareInstance] addEvent:event thisNode:nil triggerNode:nil withContext:nil];
}

@end

@implementation GrowingCustomTrackEvent
- (instancetype)initWithEventName:(NSString *)eventName withNumber:(NSNumber *)number withVariable:(NSDictionary<NSString *, NSObject *> *)variable
{
    if (![GrowingInstance sharedInstance]) {
        return nil;
    }
    
    if (eventName == nil || ![eventName isKindOfClass:[NSString class]]) {
        GIOLogError(parameterKeyErrorLog);
        return nil;
    }
    
    if (![eventName isValidKey])
    {
        return nil; 
    }
    
    if (number == nil)
    {
        GIOLogError(parameterValueErrorLog);
        return nil;
    }
    
    
    if (CFNumberIsFloatType((CFNumberRef)number))
    {
        NSString *str = [NSString stringWithFormat:@"%.2f", number.doubleValue];
        number = @(str.doubleValue);
    }
    
    GrowingCustomTrackEvent *customEvent = [[GrowingCustomTrackEvent alloc] init];
    NSMutableDictionary *dataDict = customEvent.dataDict;
    dataDict[@"n"] = eventName;
    if (variable.count != 0) {
        dataDict[@"var"] = variable;
    }
    if (![number isEqualToNumber: @LLONG_MIN]) {
        dataDict[@"num"] = number;
    }
    return customEvent;
}

- (NSString *)eventTypeKey
{
    return @"cstm";
}

+ (void)sendEventWithName:(NSString * _Nonnull)eventName
                andNumber:(NSNumber * _Nullable)number
              andVariable:(NSDictionary<NSString *, NSObject *> * _Nonnull)variable
{
    GrowingCustomTrackEvent *customEvent = [[GrowingCustomTrackEvent alloc] initWithEventName:eventName withNumber:number withVariable:variable];
    if (!customEvent) {
        return;
    }
    
    GrowingEBManualTrackEvent *customTrackEvent = [[GrowingEBManualTrackEvent alloc] initWithData:@{@"data" : customEvent.dataDict} manualTrackEventType:GrowingManualTrackCustomEventType];
    [GrowingEventBus send:customTrackEvent];
    
    NSMutableDictionary *dataDict = customEvent.dataDict;
    if ([GrowingEventManager shareInstance].lastPageEvent) {
        dataDict[@"p"] = [GrowingEventManager shareInstance].lastPageEvent.dataDict[@"p"];
        dataDict[@"ptm"] = [GrowingEventManager shareInstance].lastPageEvent.dataDict[@"ptm"];
    }
    [[GrowingEventManager shareInstance] addEvent:customEvent thisNode:nil triggerNode:nil withContext:nil];
}

@end

@implementation GrowingPeopleVarEvent

- (NSString *)eventTypeKey
{
    return @"ppl";
}

+ (void)sendEventWithVariable:(NSDictionary<NSString *, NSObject *> * _Nonnull)variable
{
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingEBManualTrackEvent *peopleTrackEvent = [[GrowingEBManualTrackEvent alloc] initWithData:@{@"data" : variable} manualTrackEventType:GrowingManualTrackPeopleVarEventType];
    [GrowingEventBus send:peopleTrackEvent];
    GrowingPeopleVarEvent * event = [[GrowingPeopleVarEvent alloc] init];
    event.dataDict[@"var"] = variable;
    [[GrowingEventManager shareInstance] addEvent:event thisNode:nil triggerNode:nil withContext:nil];
}

@end

@implementation GrowingVisitorEvent

- (instancetype)initWithVisitorVariable:(NSDictionary<NSString *, NSObject *> *)variable {
    if (![GrowingInstance sharedInstance]) {
        return nil;
    }
    
    if ([variable isKindOfClass:[NSDictionary class]]) {
        if (![variable isValidDicVar]) {
            return nil;
        }
        if (variable.count > 100 ) {
            GIOLogError(parameterValueErrorLog);
            return nil;
        }
    }

    GrowingVisitorEvent *visitorEvent = [[GrowingVisitorEvent alloc] init];
    visitorEvent.dataDict[@"var"] = variable;
    return visitorEvent;
}

- (NSString*)eventTypeKey {
    return @"vstr";
}

+ (void)sendVisitorEvent:(NSDictionary<NSString *, NSObject *> * _Nonnull)variable {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingVisitorEvent *event = [[GrowingVisitorEvent alloc] init];
    event.dataDict[@"var"] = variable;
    [[GrowingEventManager shareInstance] addEvent:event thisNode:nil triggerNode:nil withContext:nil];
}

@end
