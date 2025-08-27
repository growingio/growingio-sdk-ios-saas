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


#import "GrowingNetworkPreflight.h"
#import "GrowingNetworkConfig.h"
#import "GrowingGlobal.h"
#import "GrowingBaseModel.h"
#import "GrowingInstance.h"

typedef NS_ENUM(NSUInteger, GrowingNetworkPreflightStatus) {
    GrowingNWPreflightStatusNotDetermined,       
    GrowingNWPreflightStatusWaitingForResponse,  
    GrowingNWPreflightStatusAuthorized,          
    GrowingNWPreflightStatusDenied,              
    GrowingNWPreflightStatusClosed,              
};

static NSTimeInterval const kGrowingPreflightMaxTime = 300;

@interface GrowingNetworkPreflight ()

@property (nonatomic, assign) GrowingNetworkPreflightStatus status;
@property (nonatomic, assign) NSTimeInterval nextPreflightTime;
@property (nonatomic, assign) NSTimeInterval minPreflightTime;
@property (nonatomic, copy) NSString *dataCollectionServerHost;

@end

@implementation GrowingNetworkPreflight

#pragma mark - Initialize

- (instancetype)init {
    if (self = [super init]) {
        _dataCollectionServerHost = [[GrowingNetworkConfig sharedInstance] growingApiHost];
        
        NSString *customTrackerHost = [[GrowingNetworkConfig sharedInstance] customTrackerHost];
        if (customTrackerHost.length > 0) {
            
            _status = GrowingNWPreflightStatusClosed;
        }
        
        NSTimeInterval dataUploadInterval = g_flushInterval;
        dataUploadInterval = MAX(dataUploadInterval, 5);
        _minPreflightTime = dataUploadInterval;
    }
    return self;
}

+ (instancetype)sharedInstance {
    static GrowingNetworkPreflight *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance reset];
    });
    return instance;
}

#pragma mark - Public Methods

+ (BOOL)isSucceed {
    GrowingNetworkPreflight *preflight = [GrowingNetworkPreflight sharedInstance];
    return preflight.status > GrowingNWPreflightStatusWaitingForResponse;
}

+ (NSString *)dataCollectionServerHost {
    
    GrowingNetworkPreflight *preflight = [GrowingNetworkPreflight sharedInstance];
    return preflight.dataCollectionServerHost;
}

+ (void)sendPreflight {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingNetworkPreflight *preflight = [GrowingNetworkPreflight sharedInstance];
    [preflight reset];
    
    if (preflight.status == GrowingNWPreflightStatusNotDetermined ||
        preflight.status == GrowingNWPreflightStatusAuthorized ||
        preflight.status == GrowingNWPreflightStatusDenied) {
        if (SDKDoNotTrack()) {
            preflight.status = GrowingNWPreflightStatusNotDetermined;
            return;
        }
        [preflight sendPreflight];
    }
}

+ (void)sendPreflightIfNeeded {
    if (![GrowingInstance sharedInstance]) {
        return;
    }
    
    GrowingNetworkPreflight *preflight = [GrowingNetworkPreflight sharedInstance];
    [preflight sendPreflightIfNeeded];
}

#pragma mark - Private Methods

- (void)reset {
    self.nextPreflightTime = self.minPreflightTime;
    self.dataCollectionServerHost = [[GrowingNetworkConfig sharedInstance] growingApiHost];
}

- (void)sendPreflight {
    self.status = GrowingNWPreflightStatusWaitingForResponse;
    
    GrowingBaseModel *shareModel = [GrowingBaseModel shareInstanceWithType:GrowingModelTypeOptions];
    unsigned long long stm = GROWGetTimestamp().unsignedLongLongValue;
    NSString *ai = [GrowingInstance sharedInstance].accountID;
    NSString *urlString = kGrowingEventApiV3(kGrowingEventApiTemplate_PV, ai, stm);
    [shareModel startTaskWithURL:urlString
                      httpMethod:@"OPTIONS"
                      parameters:nil
                    outsizeBlock:nil
                   configRequest:nil
                  isSendingEvent:NO
                             STM:stm
                timeoutInSeconds:15
                   isFromHTTPDNS:NO
                         success:^(NSHTTPURLResponse *httpResponse, NSData *data) {
        self.status = GrowingNWPreflightStatusAuthorized;
    } failure:^(NSHTTPURLResponse *httpResponse, NSData *data, NSError *error) {
        if (httpResponse.statusCode == 403) {
            self.status = GrowingNWPreflightStatusDenied;
            self.dataCollectionServerHost = [[GrowingNetworkConfig sharedInstance] growingAlternateApiHost];
        } else {
            self.status = GrowingNWPreflightStatusNotDetermined;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.nextPreflightTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self sendPreflightIfNeeded];
            });
            
            self.nextPreflightTime = MIN(self.nextPreflightTime * 2, kGrowingPreflightMaxTime);
        }
    }];
}

- (void)sendPreflightIfNeeded {
    if (self.status == GrowingNWPreflightStatusNotDetermined) {
        [self sendPreflight];
    }
}

@end
