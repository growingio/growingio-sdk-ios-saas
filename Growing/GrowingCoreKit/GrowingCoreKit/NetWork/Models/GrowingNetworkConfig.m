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
#import "GrowingInstance.h"
#import "GrowingNetworkConfig.h"
#import "GrowingGlobal.h"
#import "GrowingCocoaLumberjack.h"
#import "GrowingNetworkPreflight.h"

@implementation GrowingNetworkConfig

static GrowingNetworkConfig *sharedInstance;
static NSString * const kGrowingNormalEventPath = @"/v2/%@/ios/events?stm=%llu";
static NSString * const kGrowingCustomEventPath = @"/custom/%@/ios/events?stm=%llu";
static NSString * const kGrowingDataHost = @"https://www.growingio.com";
static NSString * const kGrowingAssetsHost = @"https://assets.giocdn.com";
static NSString * const kGrowingReportHostFormat = @"https://t.growingio.com";
static NSString * const kGrowingTrackerHostFormat = @"https://api-os.growingio.com";
static NSString * const kGrowingAlternateTrackerHostFormat = @"https://api-cn.growingio.com";
static NSString * const kGrowingTagsHostFormat = @"https://tags%@.growingio.com";
static NSString * const kGrowingWsHostFormat =  @"wss://ws%@.growingio.com";
static NSString * const kGrowingGtaHost = @"https://gta.growingio.com";
//#define kGrowingHostFormat @"https://api%@.growingio.com/"
//#define kGrowingTagsHostFormat @"https://tags%@.growingio.com"
//#define kGrowingWsEndPointFormat @"wss://ws%@.growingio.com"


+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (NSString *)generateValidEndPoint:(NSString *)customHost
{
    NSString *validEndPoint = [[customHost stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] copy];
    if (!validEndPoint.length) {
        GIOLogError(@"An empty string is set as tracker host.");
        return @"";
    }
    if (![validEndPoint hasPrefix:@"http://"] && ![validEndPoint hasPrefix:@"https://"]) {
        validEndPoint = [NSString stringWithFormat:@"https://%@", validEndPoint];
    }

    NSURL *url = [NSURL URLWithString:validEndPoint];
    if (url == nil) {
        GIOLogError(@"An Invalid URL is set as tracker host.");
        return @"";
    }
    return validEndPoint;
}

- (NSString *)buildEndPointWithTemplate:(NSString *)template
                              accountId:(NSString *)accountId
                                 andSTM:(unsigned long long)stm
{
    return [NSString stringWithFormat:@"%@/%@",
                         [GrowingNetworkPreflight dataCollectionServerHost],
                         [NSString stringWithFormat:template, accountId, stm]];
}

- (void)setCustomTrackerHost:(NSString *)customHost
{
    NSString *validEndPoint = [GrowingNetworkConfig generateValidEndPoint:customHost];
    if (validEndPoint.length)
    {
        _customTrackerHost = validEndPoint;
    }
}

- (void)setCustomDataHost:(NSString *)customHost
{
    NSString *validEndPoint = [GrowingNetworkConfig generateValidEndPoint:customHost];
    if (validEndPoint.length)
    {
        _customDataHost = validEndPoint;
    }
}


- (void)setCustomAssetsHost:(NSString *)customAssetsHost
{
    NSString *validAssetsEndPoint = [GrowingNetworkConfig generateValidEndPoint:customAssetsHost];
    if (validAssetsEndPoint.length) {
        _customAssetsHost = validAssetsEndPoint;
    }
}
- (void)setCustomGtaHost:(NSString *)customHost
{
    NSString *validEndPoint = [GrowingNetworkConfig generateValidEndPoint:customHost];
    if (validEndPoint.length)
    {
        _customGtaHost = validEndPoint;
    }
}

- (void)setCustomWsHost:(NSString *)customHost
{
    
    if (customHost && customHost.length > 0) {
        _customWsHost = customHost;
    }
}

- (void)setCustomReportHost:(NSString *)customHost
{
    NSString *validEndPoint = [GrowingNetworkConfig generateValidEndPoint:customHost];
    if (validEndPoint.length)
    {
        _customReportHost = validEndPoint;
    }
}

- (void)setHybridJSSDKUrlPrefix:(NSString *)urlPrefix
{
    NSString *url = [GrowingNetworkConfig generateValidEndPoint:urlPrefix];
    if (url.length)
    {
        _customJSSDKUrlPrefix = url;
    }
}

- (NSString *)zonePrefix
{
    if (_zone && _zone.length != 0) {
        return [NSString stringWithFormat:@"-%@", _zone];
    } else {
        return @"";
    }
}

- (NSString *)growingApiHost
{
    return _customTrackerHost.length > 0 ? _customTrackerHost : kGrowingTrackerHostFormat;
}

- (NSString *)growingAlternateApiHost {
    return kGrowingAlternateTrackerHostFormat;
}

- (NSString *)growingDataHost
{
    return _customDataHost.length > 0 ? _customDataHost : kGrowingDataHost;
}

- (NSString *)growingAssetsHost
{
    return _customAssetsHost.length > 0 ? _customAssetsHost : kGrowingAssetsHost;
}

- (NSString *)tagsHost
{
    return [NSString stringWithFormat:kGrowingTagsHostFormat, [self zonePrefix]];
}

- (NSString *)wsEndPoint
{
    if (_customWsHost.length > 0) {
        return [_customWsHost stringByAppendingString:@"/app/%@/circle/%@"];
    } else {
        return [[NSString stringWithFormat:kGrowingWsHostFormat, [self zonePrefix]] stringByAppendingString:@"/app/%@/circle/%@"];
    }
    
}

- (NSString *)dataCheckEndPoint
{
    if (_customWsHost.length > 0) {
        return [_customWsHost stringByAppendingString:kGrowingDataCheckAddress];
    } else {
        return [[NSString stringWithFormat:kGrowingWsHostFormat, [self zonePrefix]] stringByAppendingString:kGrowingDataCheckAddress];
    }
}

- (NSString *)assetsEndPoint
{
    NSString *zonePrefix = [self zonePrefix];
    NSString *gtaHost = @"";
    if (_customGtaHost.length > 0) {
        gtaHost = [_customGtaHost stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    return [NSString stringWithFormat: @"%@/apps/circle/embedded.html?zone=%@&gtaHost=%@", [self growingAssetsHost], zonePrefix, gtaHost];
}

- (NSString *)growingReportEndPoint
{
    return (_customReportHost.length) > 0 ? _customReportHost : [NSString stringWithFormat:kGrowingReportHostFormat];
}

- (NSString *)buildReportEndPointWithTemplate:(NSString *)template
                                    accountId:(NSString *)accountId
                                       andSTM:(unsigned long long)stm
{
    return [NSString stringWithFormat:@"%@/app/%@",
                         (_customReportHost.length > 0 ? _customReportHost : [self growingReportEndPoint]),
                         [NSString stringWithFormat:template, accountId, stm]];
}

- (NSString *)hybridJSSDKUrlPrefix
{
    if (_customJSSDKUrlPrefix.length > 0) {
        return _customJSSDKUrlPrefix;
    }
    NSString *sdkVersion = nil;
#if kHybridModeTrack == 1
    sdkVersion = @"2.0";
#else
    sdkVersion = @"1.1";
#endif
    if (getSDKDistributedMode() == GrowingDistributeForOnPremise) {
        sdkVersion =  @"op/2.0";
    }
    
    return [NSString stringWithFormat:@"https://assets.giocdn.com/sdk/hybrid/%@", sdkVersion];
    
}

@end
