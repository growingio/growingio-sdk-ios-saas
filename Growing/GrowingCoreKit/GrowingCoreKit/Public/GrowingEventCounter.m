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


#import "GrowingEventCounter.h"

@interface GrowingEventCounter()

@property (nonatomic, assign) NSInteger globalEventId;
@property (nonatomic, assign) NSInteger eventIdForVisit;
@property (nonatomic, assign) NSInteger eventIdForPage;
@property (nonatomic, assign) NSInteger eventIdForClick;
@property (nonatomic, assign) NSInteger eventIdForTextChange;
@property (nonatomic, assign) NSInteger eventIdForSbmt;
@property (nonatomic, assign) NSInteger eventIdForCustomEvent;
@property (nonatomic, assign) NSInteger eventIdForPvarEvent;
@property (nonatomic, assign) NSInteger eventIdForEvarEvent;
@property (nonatomic, assign) NSInteger eventIdForPplEvent;
@property (nonatomic, assign) NSInteger eventIdForVisitorEvent;
@property (nonatomic, assign) NSInteger eventIdForCloseEvent;
@property (nonatomic, assign) NSInteger eventIdForActivateEvent;
@property (nonatomic, assign) NSInteger eventIdForReengageEvent;


@property (nonatomic, retain) GrowingEventDataBase *seqIdDB;

@end

@implementation GrowingEventCounter {
    
    NSSet *_eventTypes;
}

- (instancetype)initWithDB:(GrowingEventDataBase*)dataBase
{
    self = [self init];
    if (self) {
        _eventTypes = [NSSet setWithObjects:@"vst", @"page", @"clck", @"chng", @"sbmt", @"cstm", @"pvar", @"evar", @"ppl", @"vstr",@"cls", @"activate", @"reengage", nil];
        self.seqIdDB = dataBase;
        [self restoreAllSeqID];
    }
    return self;
}

- (NSNumber*)nextGlobalEventIdFor:(NSString*)eventType
{
    if ([_eventTypes containsObject:eventType])
    {
        _globalEventId++;
        [_seqIdDB setValue:[@(_globalEventId) stringValue] forKey:@"globalEventId"];
        return [NSNumber numberWithUnsignedInteger:_globalEventId];
    }
    return nil;
}

- (NSNumber*)nextEventIdFor:(NSString*)eventType
{
    if ([eventType isEqualToString: @"vst"])
    {
        _eventIdForVisit++;
        [_seqIdDB setValue:[@(_eventIdForVisit) stringValue] forKey:@"eventIdForVisit"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForVisit];
    }
    else if ([eventType isEqualToString:@"page"])
    {
        _eventIdForPage++;
        [_seqIdDB setValue:[@(_eventIdForPage) stringValue] forKey:@"eventIdForPage"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForPage];
    }
    else if ([eventType isEqualToString:@"clck"])
    {
        _eventIdForClick++;
        [_seqIdDB setValue:[@(_eventIdForClick) stringValue] forKey:@"eventIdForClick"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForClick];

    }
    else if ([eventType isEqualToString:@"sbmt"])
    {
        _eventIdForSbmt++;
        [_seqIdDB setValue:[@(_eventIdForSbmt) stringValue] forKey:@"eventIdForSbmt"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForSbmt];
    }
    else if ([eventType isEqualToString:@"chng"])
    {
        _eventIdForTextChange++;
        [_seqIdDB setValue:[@(_eventIdForTextChange) stringValue] forKey:@"eventIdForTextChange"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForTextChange];
    }
    else if ([eventType isEqualToString:@"cstm"])
    {
        _eventIdForCustomEvent++;
        [_seqIdDB setValue:[@(_eventIdForCustomEvent) stringValue] forKey:@"eventIdForCustomEvent"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForCustomEvent];
    }
    else if ([eventType isEqualToString:@"pvar"])
    {
        _eventIdForPvarEvent++;
        [_seqIdDB setValue:[@(_eventIdForPvarEvent) stringValue] forKey:@"eventIdForPvarEvent"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForPvarEvent];
    }
    else if ([eventType isEqualToString:@"evar"])
    {
        _eventIdForEvarEvent++;
        [_seqIdDB setValue:[@(_eventIdForEvarEvent) stringValue] forKey:@"eventIdForEvarEvent"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForEvarEvent];
    }
    else if ([eventType isEqualToString:@"ppl"])
    {
        _eventIdForPplEvent++;
        [_seqIdDB setValue:[@(_eventIdForPplEvent) stringValue] forKey:@"eventIdForPplEvent"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForPplEvent];
    }
    else if ([eventType isEqualToString:@"vstr"])
    {
        _eventIdForVisitorEvent++;
        [_seqIdDB setValue:[@(_eventIdForVisitorEvent) stringValue] forKey:@"eventIdForVisitorEvent"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForVisitorEvent];
    }
    else if ([eventType isEqualToString:@"cls"])
    {
        _eventIdForCloseEvent++;
        [_seqIdDB setValue:[@(_eventIdForCloseEvent) stringValue] forKey:@"eventIdForCloseEvent"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForCloseEvent];
    }
    else if ([eventType isEqualToString:@"activate"])
    {
        _eventIdForActivateEvent++;
        [_seqIdDB setValue:[@(_eventIdForActivateEvent) stringValue] forKey:@"eventIdForActivateEvent"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForActivateEvent];
    }
    else if ([eventType isEqualToString:@"reengage"])
    {
        _eventIdForReengageEvent++;
        [_seqIdDB setValue:[@(_eventIdForReengageEvent) stringValue] forKey:@"eventIdForReengageEvent"];
        return [NSNumber numberWithUnsignedInteger:_eventIdForReengageEvent];
    }
    
    return nil;
}

- (void)restoreAllSeqID
{
    self.globalEventId = [[_seqIdDB valueForKey:@"globalEventId"] integerValue];
    self.eventIdForVisit = [[_seqIdDB valueForKey:@"eventIdForVisit"] integerValue];
    self.eventIdForPage = [[_seqIdDB valueForKey:@"eventIdForPage"] integerValue];
    self.eventIdForClick = [[_seqIdDB valueForKey:@"eventIdForClick"] integerValue];
    self.eventIdForTextChange = [[_seqIdDB valueForKey:@"eventIdForTextChange"] integerValue];
    self.eventIdForCustomEvent = [[_seqIdDB valueForKey:@"eventIdForCustomEvent"] integerValue];
    self.eventIdForPvarEvent = [[_seqIdDB valueForKey:@"eventIdForPvarEvent"] integerValue];
    self.eventIdForEvarEvent = [[_seqIdDB valueForKey:@"eventIdForEvarEvent"] integerValue];
    self.eventIdForPplEvent = [[_seqIdDB valueForKey:@"eventIdForPplEvent"] integerValue];
    self.eventIdForVisitorEvent = [[_seqIdDB valueForKey:@"eventIdForVisitorEvent"] integerValue];
    self.eventIdForActivateEvent = [[_seqIdDB valueForKey:@"eventIdForActivateEvent"] integerValue];
    self.eventIdForReengageEvent = [[_seqIdDB valueForKey:@"eventIdForReengageEvent"] integerValue];

}

@end
