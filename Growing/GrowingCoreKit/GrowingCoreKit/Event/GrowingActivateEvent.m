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


#import "GrowingActivateEvent.h"
#import "GrowingDeviceInfo.h"
#import "GrowingInstance.h"
#import "GrowingEventManager.h"

@implementation GrowingActivateEvent

- (instancetype)initWithQueryDict:(NSDictionary *)queryDict {
    GrowingActivateEvent *activateEvent = [[GrowingActivateEvent alloc] init];

    GrowingDeviceInfo *deviceInfo = [GrowingDeviceInfo currentDeviceInfo];
    NSMutableDictionary *dataDict = activateEvent.dataDict;
    dataDict[@"ui"] = deviceInfo.idfa;
    dataDict[@"iv"] = deviceInfo.idfv;
    dataDict[@"osv"]= deviceInfo.systemVersion;
    dataDict[@"dm"] = deviceInfo.deviceModel;
        
    if (queryDict.count != 0) {
        [dataDict addEntriesFromDictionary:queryDict];
    }
    
    return activateEvent;
}

+ (void)sendEventQueryDict:(NSDictionary *)queryDict {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingActivateEvent *activateEvent = [[GrowingActivateEvent alloc] initWithQueryDict:queryDict];
    [[GrowingEventManager shareInstance] addEvent:activateEvent
                                         thisNode:nil
                                      triggerNode:nil
                                      withContext:nil];
}

- (NSString *)eventTypeKey {
    return @"activate";
}

+ (BOOL)hasExtraFields {
    return NO;
}

@end

@implementation GrowingReengageEvent

- (instancetype)initWithQueryDict:(NSDictionary *)queryDict withVariable:(NSDictionary<NSString *,NSObject *> *)variable {
    GrowingReengageEvent *reengageEvent = [[GrowingReengageEvent alloc] init];

    GrowingDeviceInfo *deviceInfo = [GrowingDeviceInfo currentDeviceInfo];
    NSMutableDictionary *dataDict = reengageEvent.dataDict;
    dataDict[@"ui"] = deviceInfo.idfa;
    dataDict[@"iv"] = deviceInfo.idfv;
    dataDict[@"osv"]= deviceInfo.systemVersion;
    dataDict[@"dm"] = deviceInfo.deviceModel;
    
    if (variable.count != 0) {
        dataDict[@"var"] = variable;
    }
    
    if (queryDict.count != 0) {
        [dataDict addEntriesFromDictionary:queryDict];
    }
    
    return reengageEvent;
}

+ (void)sendEventWithQueryDict:(NSDictionary *)queryDict andVariable:(NSDictionary<NSString *,NSObject *> *)variable {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingReengageEvent *reengageEvent = [[GrowingReengageEvent alloc] initWithQueryDict:queryDict withVariable:variable];
    [[GrowingEventManager shareInstance] addEvent:reengageEvent
                                         thisNode:nil
                                      triggerNode:nil
                                      withContext:nil];

}

- (NSString *)eventTypeKey {
    return @"reengage";
}

+ (BOOL)hasExtraFields {
    return NO;
}

@end
