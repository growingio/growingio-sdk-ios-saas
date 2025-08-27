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


#ifndef GrowingConstApi_h
#define GrowingConstApi_h







#define kGrowingEventApiTemplate_Custom @"v3/%@/ios/cstm?stm=%llu"
#define kGrowingEventApiTemplate_PV @"v3/%@/ios/pv?stm=%llu"
#define kGrowingEventApiTemplate_Imp @"v3/%@/ios/imp?stm=%llu"
#define kGrowingEventApiTemplate_Activate @"%@/ios/ctvt?stm=%llu"
#define kGrowingEventApiTemplate_Other @"v3/%@/ios/other?stm=%llu"
#define kGrowingEventApiV3(Template, AI, STM) [[GrowingNetworkConfig sharedInstance] buildEndPointWithTemplate:(Template) accountId:(AI) andSTM:(STM)]

#define kGrowingReportApi(Template, AI, STM) ([[GrowingNetworkConfig sharedInstance] buildReportEndPointWithTemplate:(Template) accountId:(AI) andSTM:(STM)])

#define kGrowingDataApiHost(path) ([NSString stringWithFormat: @"%@/%@", [[GrowingNetworkConfig sharedInstance] growingDataHost], path])



#define kGrowingRealtimeApi             kGrowingDataApiHost(@"mobile/realtime")
#define kGrowingTagApi                  kGrowingDataApiHost(@"mobile/events")
#define kGrowingAllProducts             kGrowingDataApiHost(@"mobile/products")
#define kGrowingXRankQuery              kGrowingDataApiHost(@"mobile/xrank")
#define kGrowingVRankQuery              kGrowingDataApiHost(@"mobile/vrank")
#define kGrowingHeatMap                 kGrowingDataApiHost(@"mobile/heatmap/data")
#define kGrowingWebCircleWSPost         kGrowingDataApiHost(@"mobile/link")

#define kGrowingLoginApiV2              kGrowingDataApiHost(@"oauth2/token")

#define kGrowingDataCounterAddress      @"http:

#define kGrowingDataCheckAddress      @"/feeds/apps/%@/exchanges/data-check/%@?clientType=sdk"

#define kGrowingAddTagPage          ([[GrowingNetworkConfig sharedInstance] assetsEndPoint])

#endif 




@interface GrowingNetworkConfig : NSObject

@property (nonatomic, copy) NSString *customTrackerHost;
@property (nonatomic, copy) NSString *customDataHost;
@property (nonatomic, copy) NSString *customAssetsHost;
@property (nonatomic, copy) NSString *customReportHost;
@property (nonatomic, copy) NSString *customWsHost;
@property (nonatomic, copy) NSString *customGtaHost;
@property (nonatomic, copy) NSString *customJSSDKUrlPrefix;
@property (nonatomic, copy) NSString *zone;

+ (instancetype)sharedInstance;

- (NSString *)buildEndPointWithTemplate:(NSString *)path
                              accountId:(NSString *)accountId
                                 andSTM:(unsigned long long)stm;

- (NSString *)buildReportEndPointWithTemplate:(NSString *)template
                                    accountId:(NSString *)accountId
                                       andSTM:(unsigned long long)stm;

- (NSString *)growingApiHost;

- (NSString *)growingAlternateApiHost;

- (NSString *)growingDataHost;

- (NSString *)assetsEndPoint;

- (NSString *)tagsHost;

- (NSString *)wsEndPoint;

- (NSString *)dataCheckEndPoint;

- (NSString *)growingReportEndPoint;

- (void)setHybridJSSDKUrlPrefix:(NSString *)urlPrefix;

- (NSString *)hybridJSSDKUrlPrefix;

@end
