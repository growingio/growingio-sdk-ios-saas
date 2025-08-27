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
#import "GrowingCoreKit.h"
#import "GrowingInstance.h"
#import "GrowingCustomField.h"
#import "GrowingEventManager.h"
#import "GrowingDeviceInfo.h"
#import "GrowingGlobal.h"
#import "GrowingNetworkConfig.h"
#import "GrowingDispatchManager.h"
#import "GrowingMediator+GrowingDeepLink.h"
#import "NSString+GrowingHelper.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingEBUserIdEvent.h"
#import "GrowingEventBus.h"
#import "GrowingVersionManager.h"
#import "GrowingEBManualTrackEvent.h"
#import "GrowingEventBus.h"
#import "GrowingEBMonitorEvent.h"
#import "UIApplication+Growing.h"
#import "GrowingCocoaLumberjack.h"
#import "GrowingWKWebViewJavascriptBridge.h"
#import "GrowingNetworkPreflight.h"

@implementation Growing

+ (void)load
{
    [GrowingVersionManager registerVersionInfo:@{@"cv":[self sdkVersion]}];
}

static NSString* getDateFromMacro()
{
#ifdef COMPILE_DATE_TIME
    
    
    return @metamacro_stringify(COMPILE_DATE_TIME);
#else
    int month, day, year;
    int h, m, s;
    char s_month[5];
    static const char month_names[] = "JanFebMarAprMayJunJulAugSepOctNovDec";
    sscanf(__DATE__, "%s %d %d", s_month, &day, &year);
    month = (int)(strstr(month_names, s_month)-month_names) / 3 + 1;
    sscanf(__TIME__ , "%d:%d:%d", &h, &m, &s);
    return [NSString stringWithFormat:@"%d%02d%02d%02d%02d%02d",year,month,day,h,m,s];
#endif
}

+ (NSString*)sdkVersion
{
    static NSString *ver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifdef GROWINGIO_SDK_VERSION
        const char * v = metamacro_stringify(GROWINGIO_SDK_VERSION);
#else
        const char * v = "2.0";
#endif
#if defined(DEBUG) && DEBUG
        ver = [NSString stringWithFormat:@"%s-%@", v, @"debug"];
#else
        ver = [NSString stringWithFormat:@"%s", v];
#endif
    });
    return ver;
}

+ (void)setAspectMode:(GrowingAspectMode)aspectMode
{
    [GrowingInstance setAspectMode:aspectMode];
}

+ (GrowingAspectMode)getAspectMode
{
    return [GrowingInstance aspectMode];
}

static NSString *growingBundleId = nil;
+ (void)setBundleId:(NSString *)bundleId
{
    growingBundleId = bundleId;
}

+ (NSString *)getBundleId
{
    return growingBundleId;
}

static NSString *growingUrlScheme = nil;
+ (void)setUrlScheme:(NSString *)urlScheme
{
    growingUrlScheme = urlScheme;
}

+ (NSString *)getUrlScheme
{
    return growingUrlScheme;
}

+ (BOOL)handleUrl:(NSURL *)aUrl
{
    return [[GrowingMediator sharedInstance] performActionWithUrl:aUrl];
}

+ (void)startWithAccountId:(NSString *)accountId
{
    [self startWithAccountId:accountId withSampling:1];
}

+ (void)startWithAccountId:(NSString *)accountId withSampling:(CGFloat)sampling
{
    [self loggerSetting];
    if (![NSThread isMainThread]) {
        NSLog(@"请在applicationDidFinishLaunching中调用startWithAccountId函数,并且确保在主线程中");
    }
    
    if (!accountId.length) {
        NSLog(@"GrowingIO启动失败:AccountId不能为空");
        return;
    }
    
    BOOL urlSchemeRight = [self urlSchemeCheck];
    
    [self versionCheck];
    
    if (urlSchemeRight) {
        GIOLogError(@"!!! Thank you very much for using GrowingIO. We will do our best to provide you with the best service. !!!");
        GIOLogError(@"!!! GrowingIO version: %@ !!!", [Growing sdkVersion]);
        [GrowingInstance startWithAccountId:accountId withSampling:sampling];
    }
    
    
    [self sendGrowingEBMonitorEventState:GrowingMonitorStateUploadExceptionDefault];
    
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
+ (void)versionCheck
{
    NSString *coreKitVersion = [Growing sdkVersion];
    NSString *autoTrackKitVersion = @"";
    if ([Growing respondsToSelector:@selector(autoTrackKitVersion)]) {
        autoTrackKitVersion = [Growing performSelector:@selector(autoTrackKitVersion)];
    }
    NSString *reactNativeKitVersion = @"";
    if ([Growing respondsToSelector:@selector(rnKitVersion)]) {
        reactNativeKitVersion = [Growing performSelector:@selector(rnKitVersion)];
    }
    
    BOOL flag = YES;
    NSString *des = @"";
    if (autoTrackKitVersion.length > 0 && reactNativeKitVersion.length > 0) {
        if (![coreKitVersion isEqualToString:autoTrackKitVersion] || ![autoTrackKitVersion isEqualToString:reactNativeKitVersion]) {
            flag = NO;
            des = @"GrowingIO提示您需要保证Growing,GrowingCoreKit,GrowingAutoTrackKit,GrowingReactNativeKit版本号一致\n"
                "如果您使用cocoapods集成:\n"
                "pod 'Growing', 'version'\n"
                "pod 'GrowingCoreKit', 'version'\n"
                "pod 'GrowingAutoTrackKit', 'version'\n"
                "pod 'GrowingReactNativeKit', 'version'\n"
                "如果您手动集成:\n"
                "可以到对应链接根据tag下载版本\n"
                "Growing:https://github.com/growingio/GrowingSDK-iOS-PublicHeader\n"
                "GrowingCoreKit:https://github.com/growingio/GrowingSDK-iOS-GrowingCoreKit\n"
                "GrowingAutoTrackKit:https://github.com/growingio/GrowingSDK-iOS-GrowingAutoTrackKit\n"
                "GrowingReactNativeKit:https://github.com/growingio/GrowingSDK-iOS-GrowingReactNativeKit";
        }
    } else if (autoTrackKitVersion.length > 0) {
        if (![coreKitVersion isEqualToString:autoTrackKitVersion]) {
            flag = NO;
            des = @"GrowingIO提示您需要保证Growing,GrowingCoreKit,GrowingAutoTrackKit版本号一致\n"
            "如果您使用cocoapods集成:\n"
            "pod 'Growing', 'version'\n"
            "pod 'GrowingCoreKit', 'version'\n"
            "pod 'GrowingAutoTrackKit', 'version'\n"
            "如果您手动集成:\n"
            "可以到对应链接根据tag下载版本\n"
            "Growing:https://github.com/growingio/GrowingSDK-iOS-PublicHeader\n"
            "GrowingCoreKit:https://github.com/growingio/GrowingSDK-iOS-GrowingCoreKit\n"
            "GrowingAutoTrackKit:https://github.com/growingio/GrowingSDK-iOS-GrowingAutoTrackKit";
        }
    }
    if (!flag) {
        GIOLogWarn(@"%@", des);
    }
}
#pragma clang diagnostic pop

+ (BOOL)urlSchemeCheck
{
    if ([GrowingDeviceInfo currentDeviceInfo].urlScheme.length == 0) {
        GIOLogError(@"未检测到 GrowingIO 的 URLScheme !!!");
        GIOLogInfo(@"请参考帮助文档 https://docs.growingio.com/v3/developer-manual/sdkintegrated/ios-sdk/auto-ios-sdk#urlscheme 进行集成");
        return NO;
    } else {
        return YES;
    }
}

static BOOL _enableLog;
+ (void)setEnableLog:(BOOL)enableLog
{
    if (_enableLog == enableLog) {
        return;
    }
    _enableLog = enableLog;
    [GrowingLog removeLogger:[GrowingTTYLogger sharedInstance]];
    if (_enableLog) {
        [GrowingLog addLogger:[GrowingTTYLogger sharedInstance] withLevel:GrowingLogLevelDebug];
    } else {
        [GrowingLog addLogger:[GrowingTTYLogger sharedInstance] withLevel:GrowingLogLevelError];
    }
}

+ (BOOL)getEnableLog
{
    return _enableLog;
}

+ (void)setEnableDiagnose:(BOOL)enable
{
    g_dataCounterEnable = enable;
}

+ (void)loggerSetting {
    
    if (!_enableLog) {
        [GrowingLog addLogger:[GrowingTTYLogger sharedInstance] withLevel:GrowingLogLevelError];
    }
    
    
}

static BOOL _disablePushTrack = YES ;

+ (void)disablePushTrack:(BOOL)disable{
    _disablePushTrack = disable ;
}
+ (BOOL)getDisablePushTrack{
    return _disablePushTrack ;
}

+ (void)setEnableLocationTrack:(BOOL)enable;
{
    g_locationEnabled = enable;
}

+ (BOOL)getEnableLocationTrack
{
    return g_locationEnabled;
}

+ (void)setLocation:(CLLocation *)location {
    [GrowingInstance setLocation:location];
}

+ (void)cleanLocation {
    [GrowingInstance cleanLocation];
}

+ (void)setEncryptStringBlock:(NSString *(^)(NSString *string))block
{
    [GrowingDeviceInfo currentDeviceInfo].encryptStringBlock = block;
}


#define csFunction_body(n)                                                                              \
{                                                                                                       \
    if ([value isKindOfClass:[NSNumber class]])                                                         \
    {                                                                                                   \
        value = [(NSNumber *)value stringValue];                                                        \
    }                                                                                                   \
    if (![value isKindOfClass:[NSString class]] || value.length == 0)                                   \
    {                                                                                                   \
        [GrowingCustomField shareInstance].cs##n = nil;                                                 \
    }                                                                                                   \
    else                                                                                                \
    {                                                                                                   \
        [GrowingCustomField shareInstance].cs##n = value;                                               \
    }                                                                                                   \
}                                                                                                       \

+ (void)setCS1Value:(nonnull NSString *)value
{
    NSString * oldValue = [GrowingCustomField shareInstance].cs1;
    csFunction_body(1) 
    NSString * newValue = [GrowingCustomField shareInstance].cs1;
    
    [self resetSessionIDAndSendVstByCS1OldValue:oldValue cs1NewValue:newValue];
    
    
    if (oldValue.length == 0 && newValue.length > 0 && ![GrowingDeviceInfo currentDeviceInfo].isApplicationInWillEnterForeground)
    {
        
        
        [[GrowingMediator sharedInstance] performClass:@"GrowingPageEvent" action:@"resendPageEventForCS1Change" params:nil];;
    }
}

+ (void)resetSessionIDAndSendVstByCS1OldValue:(NSString *)oldValue cs1NewValue:(NSString *)newValue
{
    
    static NSString *lastCS1 = nil;
    
    
    if (oldValue.length > 0) {
        lastCS1 = oldValue;
    }
    
    
    if (lastCS1.length > 0 && newValue.length > 0 && ![lastCS1 isEqualToString:newValue]) {
        [GrowingNetworkPreflight sendPreflight];
        [[GrowingDeviceInfo currentDeviceInfo] resetSessionID];
        [GrowingVisitEvent send];
        
        
        if ([[GrowingCustomField shareInstance] growingVistorVar]) {
            [[GrowingCustomField shareInstance] sendVisitorEvent:[[GrowingCustomField shareInstance] growingVistorVar]];
        }
    }
}

+ (void)disable {
    g_doNotTrack = YES;
}

static void (^resendVstBlock)(void) = nil;


+ (void)disableDataCollect {
    g_GDPRFlag = YES;
    resendVstBlock = ^(){
        [GrowingVisitEvent send];
    };
}


+ (void)enableDataCollect {
    g_GDPRFlag = NO;
    if (resendVstBlock) {
        resendVstBlock();
        resendVstBlock = nil;
    }
    [GrowingNetworkPreflight sendPreflightIfNeeded];
    [GrowingInstance.sharedInstance runPastedDeeplink];
}

+ (void)setReadClipBoardEnable:(BOOL)enabled {
    g_readClipBoardEnable = enabled;
}

+ (void)setAsaEnabled:(BOOL)asaEnabled {
    g_asaEnabled = asaEnabled;
}

+ (void)setFlushInterval:(NSTimeInterval)interval
{
    g_flushInterval = interval;
}

+ (NSTimeInterval)getFlushInterval
{
    return g_flushInterval;
}

+ (void)setSessionInterval:(NSTimeInterval)interval
{
    g_sessionInterval = interval;
}

+ (NSTimeInterval)getSessionInterval
{
    return g_sessionInterval;
}

+ (void)setDailyDataLimit:(NSUInteger)numberOfKiloByte
{
    g_uploadLimitOfCellular = numberOfKiloByte * 1000;
}

+ (NSUInteger)getDailyDataLimit
{
    return (NSUInteger)(g_uploadLimitOfCellular / 1000);
}

+ (void)setTrackerHost:(NSString *)host
{
    [GrowingNetworkConfig.sharedInstance setCustomTrackerHost:host];
}

+ (void)setDataHost:(NSString *)host
{
    [GrowingNetworkConfig.sharedInstance setCustomDataHost:host];
}

+ (void)setAssetsHost:(NSString*)host
{
    [GrowingNetworkConfig.sharedInstance setCustomAssetsHost:host];
}

+ (void)setGtaHost:(NSString *)host
{
    [GrowingNetworkConfig.sharedInstance setCustomGtaHost:host];
}

+ (void)setWsHost:(NSString *)host
{
    [GrowingNetworkConfig.sharedInstance setCustomWsHost:host];
}

+ (void)registerDeeplinkHandler:(void(^)(NSDictionary *params, NSTimeInterval processTime, NSError *error))handler {
    [GrowingInstance setDeeplinkHandler:handler];
}

+ (BOOL)isDeeplinkUrl:(NSURL *)url
{
    return [[GrowingMediator sharedInstance] isShortChainUlink:url];
}

+ (BOOL)doDeeplinkByUrl:(NSURL *)url callback:(void(^)(NSDictionary *params, NSTimeInterval processTime, NSError *error))callback
{
    return [GrowingInstance doDeeplinkByUrl:url callback:callback];
}

+ (void)registerRealtimeReportHandler:(void(^)(NSDictionary *eventObject))handler {
        [GrowingEventManager shareInstance].reportHandler = handler;
}

+ (void)setReportHost:(NSString *)host
{
    [GrowingNetworkConfig.sharedInstance setCustomReportHost:host];
}

+ (void)setZone:(NSString *)zone
{
    GrowingNetworkConfig.sharedInstance.zone = zone;
}

+ (void)setDeviceIDModeToCustomBlock:(NSString *(^)(void))customBlock
{
    [GrowingDeviceInfo currentDeviceInfo].customDeviceIDBlock = customBlock;
}

+ (NSString *)getDeviceId
{
    return [GrowingDeviceInfo currentDeviceInfo].deviceIDString;
}
+ (NSString *)getVisitUserId
{
    return [GrowingDeviceInfo currentDeviceInfo].deviceIDString;
}

+ (NSString *)getSessionId
{
    return [GrowingDeviceInfo currentDeviceInfo].sessionID;
}


+ (void)setUserId:(NSString *)userId
{
    
    if (userId.length == 0 || userId.length > 1000) {
        return;
    }
        
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        [self setCS1Value:userId];
        GrowingEBUserIdEvent *setUserIdEvent = [[GrowingEBUserIdEvent alloc] initWithData:@{@"data":userId} operateType:GrowingSetUserIdType];
        [GrowingEventBus send:setUserIdEvent];
        
    }];
    
}

+ (void)clearUserId
{
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        [self setCS1Value:@""];
        GrowingEBUserIdEvent *clearUserIdEvent = [[GrowingEBUserIdEvent alloc] initWithData:nil operateType:GrowingClearUserIdType];
        [GrowingEventBus send:clearUserIdEvent];
        
    }];
    
}

#pragma mark --

+ (void)setEvar:(NSDictionary<NSString *, NSObject *> *)variable
{
    if (![variable isKindOfClass:[NSDictionary class]]) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{

         [[GrowingCustomField shareInstance] sendEvarEvent:variable];
        
    }];
    
}

+ (void)setEvarWithKey:(NSString *)key andStringValue:(NSString *)stringValue
{
    if (key == nil || ![key isKindOfClass:[NSString class]]) {
        GIOLogError(parameterKeyErrorLog);
        return ;
    }
    if (![key isValidKey])
    {
        return ;
    }
    if (![stringValue isKindOfClass:[NSString class]])
    {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    if (stringValue.length > 1000 || stringValue.length == 0) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        [[GrowingCustomField shareInstance] sendEvarEvent:@{key:stringValue}];
        
    }];
    
}

+ (void)setEvarWithKey:(NSString *)key andNumberValue:(NSNumber *)numberValue
{
    if (key == nil || ![key isKindOfClass:[NSString class]]) {
        GIOLogError(parameterKeyErrorLog);
        return ;
    }
    if (![key isValidKey])
    {
        return ;
    }
    if (numberValue != nil && [numberValue isKindOfClass:[NSNumber class]])
    {
        [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
            
             [[GrowingCustomField shareInstance] sendEvarEvent:@{key:numberValue}];
            
        }];
        
    }else{
        GIOLogError(parameterValueErrorLog);
    }
}

+ (void)setVisitor:(NSDictionary<NSString *, NSObject *> *)variable
{

    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        [[GrowingCustomField shareInstance] sendVisitorEvent:variable];
        
        GrowingEBManualTrackEvent *visitorTrackEvent = [[GrowingEBManualTrackEvent alloc] initWithData:@{@"data" : [GrowingCustomField shareInstance].growingVistorVar?:@{}} manualTrackEventType:GrowingManualTrackVisitorEventType];
        [GrowingEventBus send:visitorTrackEvent];
        
    }];

}

+ (void)setPeopleVariable:(NSDictionary<NSString *, NSObject *> *)variable
{
    if (![variable isKindOfClass:[NSDictionary class]]) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
         [[GrowingCustomField shareInstance] sendPeopleEvent:variable];
        
    }];
    
   
}

+ (void)setPeopleVariableWithKey:(NSString *)key andStringValue:(NSString *)stringValue
{
    if (![key isKindOfClass:[NSString class]]) {
        GIOLogError(parameterKeyErrorLog);
        return ;
    }
    if (![key isValidKey])
    {
        return;
    }
    if (![stringValue isKindOfClass:[NSString class]]) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    if (stringValue.length > 1000 || stringValue.length == 0 ) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        [[GrowingCustomField shareInstance] sendPeopleEvent:@{key:stringValue}];
        
    }];
    
}

+ (void)setPeopleVariableWithKey:(NSString *)key andNumberValue:(NSNumber *)numberValue
{
    if (![key isKindOfClass:[NSString class]]) {
        GIOLogError(parameterKeyErrorLog);
        return ;
    }
    if (![key isValidKey])
    {
        return ;
    }
    if (numberValue != nil && [numberValue isKindOfClass:[NSNumber class]])
    {
        [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
            
             [[GrowingCustomField shareInstance] sendPeopleEvent:@{key:numberValue}];
            
        }];
        
    }else{
        GIOLogError(parameterValueErrorLog);
    }
}

#pragma mark Track Custom Event

+ (void)track:(NSString *)eventId
{
    if (![eventId isKindOfClass:[NSString class]]) {
        GIOLogError(parameterKeyErrorLog);
        return ;
    }
    if (![eventId isValidKey]) {
        return ;
    }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
         [[GrowingCustomField shareInstance] sendCustomTrackEventWithName:eventId andNumber:@LLONG_MIN andVariable:nil];
        
    }];
    
}

+ (void)track:(NSString *)eventId withNumber:(NSNumber *)number
{
    if (![eventId isKindOfClass:[NSString class]]) {
        GIOLogError(parameterKeyErrorLog);
        return ;
    }
    if (![eventId isValidKey]) {
        return ;
    }
    if (![number isKindOfClass:[NSNumber class]]) {
        GIOLogError(parameterKeyErrorLog);
        return ;
    }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        [[GrowingCustomField shareInstance] sendCustomTrackEventWithName:eventId andNumber:number andVariable:nil];
        
    }];
    
}

+ (void)track:(NSString *)eventId withVariable:(NSDictionary<NSString *, NSObject *> *)variable
{
    if (![eventId isKindOfClass:[NSString class]]) {
        GIOLogError(parameterKeyErrorLog);
        return ;
    }
    if (![variable isKindOfClass:[NSDictionary class]]) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    if (variable.count > 100 ) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    if (![eventId isValidKey] || ![variable isValidDicVar]) {
        return ;
    }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
         [[GrowingCustomField shareInstance] sendCustomTrackEventWithName:eventId andNumber:@LLONG_MIN andVariable:variable];
        
    }];
    
}

+ (void)track:(NSString *)eventId withNumber:(NSNumber *)number andVariable:(NSDictionary<NSString *, NSObject *> *)variable
{
    if (![eventId isKindOfClass:[NSString class]]) {
        GIOLogError(parameterKeyErrorLog);
        return ;
    }
    if (![number isKindOfClass:[NSNumber class]]) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    if (![variable isKindOfClass:[NSDictionary class]]) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    if (variable.count > 100 ) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    if (![eventId isValidKey] || ![variable isValidDicVar]) {
        return ;
    }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        [[GrowingCustomField shareInstance] sendCustomTrackEventWithName:eventId andNumber:number andVariable:variable];
        
    }];
    
}

+ (void)setUploadExceptionEnable:(BOOL)uploadExceptionEnable {
        
    GrowingMonitorState state = uploadExceptionEnable ? GrowingMonitorStateUploadExceptionEnable : GrowingMonitorStateUploadExceptionDisable;
    [self sendGrowingEBMonitorEventState:state];
    
}

+ (void)sendGrowingEBMonitorEventState:(GrowingMonitorState)state {
    NSDictionary *dataDict = @{@"v": [NSString stringWithFormat:@"GrowingCoreKit-%@", [self sdkVersion]],
                               @"u": [GrowingDeviceInfo currentDeviceInfo].deviceIDString ?: @"",
                               @"ai": [GrowingInstance sharedInstance].accountID ?: @"",
    };
    
    GrowingEBMonitorEvent *monitorEvent = [[GrowingEBMonitorEvent alloc] initWithData:dataDict growingMonitorState:state];
    [GrowingEventBus send:monitorEvent];
}

+ (void)bridgeForWKWebView:(WKWebView *)webView {
    [GrowingWebViewJavascriptBridge bridgeForWebView:webView];
}

@end
