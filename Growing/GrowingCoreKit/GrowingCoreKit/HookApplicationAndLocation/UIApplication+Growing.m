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


#import "UIApplication+Growing.h"
#import "FoSwizzling.h"
#import "FoDelegateSwizzling.h"
#import "GrowingInstance.h"
#import "GrowingDeviceInfo.h"
#import "UIApplication+GrowingNode.h"
#import "UIApplication+GrowingHelper.h"
#import "UIWindow+GrowingHelper.h"
#import "GrowingAspect.h"
#import "GrowingEventManager.h"
#import "GrowingMobileDebugger.h"
#import "GrowingMediator.h"
#import "GrowingCustomField.h"
#import "GrowingEventBus.h"
#import "GrowingEBApplicationEvent.h"
#import "GrowingGlobal.h"
#import "GrowingCocoaLumberjack.h"
#import "GrowingNetworkPreflight.h"

FoHookInstance(UIApplication, @selector(sendEvent:), void, UIEvent *event)
{
    FoHookOrgin(event);
    if (event.type == UIEventTypeTouches)
    {
        if (NSClassFromString(@"GrowingWebSocket") != NULL) {
            [[GrowingMediator sharedInstance] performClass:@"GrowingWebSocket" action:@"setNeedUpdateScreen" params:nil];
        }
        
        
        [GrowingMobileDebugger updateScreenshot];
        
    }
}
FoHookEnd


FoSwizzleTemplet    (@selector(application:didFinishLaunchingWithOptions:),
                     BOOL,appdelegateDidFinishLaunching,UIApplication*,NSDictionary*)
FoSwizzleTempletVoid(@selector(applicationWillTerminate:),
                     void,applicationWillTerminate,UIApplication*)

FoSwizzleTempletVoid(@selector(applicationDidEnterBackground:),
                     void,applicationDidEnterBackground,UIApplication*)


FoSwizzleTempletVoid(@selector(applicationDidBecomeActive:),
                     void,applicationDidBecomeActive,UIApplication*)
FoSwizzleTempletVoid(@selector(applicationWillResignActive:),
                     void,applicationWillResignActive,UIApplication*)


FoSwizzleTempletVoid(@selector(applicationWillEnterForeground:),
                     void,applicationWillEnterForeground, UIApplication*)


FoSwizzleTempletVoid(@selector(application:didReceiveLocalNotification:),
                     void,appdelegateDidReceiveLocalNotification,UIApplication*,UILocalNotification *)

typedef void(^FetchCompletionHandler)();

FoSwizzleTempletVoid(@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:),
                     void,appdelegateDidReceiveRemoteNotification,UIApplication*,NSDictionary *,FetchCompletionHandler)

FoSwizzleTempletVoid(@selector(application:didReceiveRemoteNotification:),
                     void,appdelegateDidReceiveRemoteNotificationEarly,UIApplication*,NSDictionary *)

@implementation GrowingActivationTime

static BOOL _didStart = YES;

+ (BOOL)didStartFromScratch
{
    return _didStart;
}

+ (BOOL)didActivateInShortTime
{
    if (_resignActiveDate != nil)
    {
        NSTimeInterval interval = -[_resignActiveDate timeIntervalSinceNow];
        if (interval > 0 && interval <= g_sessionInterval)
        {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)didActivateInLongTime
{
    if (_resignActiveDate != nil)
    {
        NSTimeInterval interval = -[_resignActiveDate timeIntervalSinceNow];
        if (interval > g_sessionInterval)
        {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)didActivateInLongTime:(NSDate *)date;
{
    _resignActiveDate = date;
    return [self didActivateInLongTime];
}

+ (BOOL)isNormal
{
    if (_resignActiveDate != nil)
    {
        NSTimeInterval interval = -[_resignActiveDate timeIntervalSinceNow];
        if (interval <= 0)
        {
            return YES;
        }
    }
    return NO;
}

+ (void)reset
{
    _resignActiveDate = [NSDate dateWithTimeIntervalSinceNow:60*60*24*365];
}

@end







FoHookDelegate(UIApplication, @selector(setDelegate:), void, NSObject<UIApplicationDelegate>*, delegate)


GrowingAspectAfter(delegate,
                   appdelegateDidReceiveLocalNotification,
                   void, @selector(application:didReceiveLocalNotification:), (UIApplication*)application ,(UILocalNotification *)notification ,
                   {
                       if([Growing getDisablePushTrack]){
                           return ;
                       }
                       GIOLogDebug(@"appdelegateDidReceiveLocalNotification");
                       NSMutableDictionary *variableDic =  [[NSMutableDictionary alloc] init];
                       variableDic[@"notification_title"] = notification.alertTitle ;
                       variableDic[@"notification_content"] = notification.alertBody ;
                       
                       [Growing track:@"notification_click"  withVariable:variableDic];
                   })
,

GrowingAspectBeforeNoAdd(delegate,appdelegateDidReceiveRemoteNotificationEarly,void, @selector(application:didReceiveRemoteNotification:),(UIApplication*)application,(NSDictionary *)userInfo,
    {
                    NSMutableDictionary *eventDataDic =  [[NSMutableDictionary alloc] init];
                    eventDataDic[@"data"] = userInfo;
                    GrowingEBApplicationEvent *applicationEvent = [[GrowingEBApplicationEvent alloc] initWithData:eventDataDic lifeType:GrowingApplicationDidReceiveRemoteNotification];
                    [GrowingEventBus send:applicationEvent];

                    if([Growing getDisablePushTrack]){
                          return ;
                    }
                    GIOLogDebug(@"appdelegateDidReceiveLocalNotification");
                    NSMutableDictionary *temDic = userInfo[@"aps"];
                    NSMutableDictionary *variableDic =   [[NSMutableDictionary alloc] init];
                    if ([temDic[@"alert"] isKindOfClass:[NSString class]]) {
                        variableDic[@"notification_title"] = temDic[@"alert"] ;
                        variableDic[@"notification_content"] = temDic[@"alert"] ;
                    }else if([temDic[@"alert"] isKindOfClass:[NSDictionary class]]){
                        NSMutableDictionary *alertDic = temDic[@"alert"];
                        variableDic[@"notification_title"] = alertDic[@"title"] ;
                        variableDic[@"notification_content"] = alertDic[@"body"] ;
                    }
                    [Growing track:@"notification_click"  withVariable:variableDic];
}),

GrowingAspectBeforeNoAdd(delegate,appdelegateDidReceiveRemoteNotification,void, @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:),(UIApplication*)application,(NSDictionary *)userInfo, (FetchCompletionHandler)    fetchCompletionHandler, {
    
                    NSMutableDictionary *eventDataDic =  [[NSMutableDictionary alloc] init];
                    eventDataDic[@"data"] = userInfo;
                    GrowingEBApplicationEvent *applicationEvent = [[GrowingEBApplicationEvent alloc] initWithData:eventDataDic lifeType:GrowingApplicationDidReceiveRemoteNotification];
                    [GrowingEventBus send:applicationEvent];
    
                    if([Growing getDisablePushTrack]){
                        return ;
                    }
    
                    GIOLogDebug(@"appdelegateDidReceiveLocalNotification");
                    NSMutableDictionary *temDic = userInfo[@"aps"];
                    NSMutableDictionary *variableDic =   [[NSMutableDictionary alloc] init];
                    if ([temDic[@"alert"] isKindOfClass:[NSString class]]) {
                        variableDic[@"notification_title"] = temDic[@"alert"] ;
                        variableDic[@"notification_content"] = temDic[@"alert"] ;
                    }else if([temDic[@"alert"] isKindOfClass:[NSDictionary class]]){
                        NSMutableDictionary *alertDic = temDic[@"alert"];
                        variableDic[@"notification_title"] = alertDic[@"title"] ;
                        variableDic[@"notification_content"] = alertDic[@"body"] ;
                    }
                    [Growing track:@"notification_click"  withVariable:variableDic];
}),




GrowingAspectBefore(delegate,
                   appdelegateDidFinishLaunching,
                   BOOL, @selector(application:didFinishLaunchingWithOptions:), (UIApplication*)application ,(NSDictionary*)dict ,
                   {
                       NSString *ai = [GrowingDeviceInfo currentDeviceInfo].configAccountID;
                       if (ai.length)
                       {
                           [Growing startWithAccountId:ai withSampling:1];
                       }
                       GIOLogDebug(@"applicationDidFinishLaunching");
                       
                       NSMutableDictionary *eventDataDic =  [[NSMutableDictionary alloc] init];
                       if(dict){
                           eventDataDic[@"data"] = dict;
                       }
                       GrowingEBApplicationEvent *applicationEvent = [[GrowingEBApplicationEvent alloc] initWithData:eventDataDic lifeType:GrowingApplicationDidFinishLaunching];
                       [GrowingEventBus send:applicationEvent];
                   })
,

GrowingAspectBefore(delegate,
                    applicationWillTerminate,
                    void, @selector(applicationWillTerminate:),(UIApplication *)application , {
                        GIOLogDebug(@"applicationWillTerminateNotification");

                        GrowingEBApplicationEvent *applicationEvent = [[GrowingEBApplicationEvent alloc] initWithLifeType:GrowingApplicationWillTerminate];
                        [GrowingEventBus send:applicationEvent];
                        
                        GrowingEvent *lastPageEvent= [GrowingEventManager shareInstance].lastPageEvent;
                        if(!lastPageEvent)
                        {
                            return;
                        }
                        GrowingEvent *closeEvent = [[GrowingEvent alloc] init];
                        [closeEvent assignRadioType];
                        closeEvent.dataDict[@"t"] = @"cls" ;
                        closeEvent.dataDict[@"p"] = lastPageEvent.dataDict[@"p"];
                        [[GrowingEventManager shareInstance] addEvent:closeEvent
                                                             thisNode:nil
                                                          triggerNode:nil
                                                          withContext:nil];
                        [[GrowingEventManager shareInstance] flushDB];
})
,


GrowingAspectBefore(delegate, applicationDidEnterBackground, void, @selector(applicationDidEnterBackground:), (UIApplication *)application, {
    
    GrowingEBApplicationEvent *applicationEvent = [[GrowingEBApplicationEvent alloc] initWithLifeType:GrowingApplicationDidEnterBackground];
    [GrowingEventBus send:applicationEvent];
    
    
    [[GrowingEventManager shareInstance] flushDB];
})
,


GrowingAspectBefore(delegate,
                    applicationDidBecomeActive,
                    void, @selector(applicationDidBecomeActive:),(UIApplication *)application, {
                        GIOLogDebug(@"applicationDidBecomeActive");
                        growingDidBecomeActive();

                    })
,

GrowingAspectBefore(delegate,
                    applicationWillResignActive,
                    void, @selector(applicationWillResignActive:), (UIApplication *)application, {
                        GIOLogDebug(@"applicationWillResignActive");
                        growingWillResignActive();

                    })
,

GrowingAspectBefore(delegate,
                    applicationWillEnterForeground,
                    void, @selector(applicationWillEnterForeground:), (UIApplication *)application, {
                        GIOLogDebug(@"applicationWillEnterForeground");
                        growingWillEnterForeground();

                    })
,






FoHookDelegateEnd

void growingDidBecomeActive()
{
    [GrowingEventManager shareInstance].shouldCacheEvent = NO;
    [GrowingDeviceInfo currentDeviceInfo].isResetSIDByWillEnterForeground = NO;
    [GrowingDeviceInfo currentDeviceInfo].isApplicationInWillEnterForeground = NO;
    
    
    if ([GrowingActivationTime didActivateInLongTime])
    {
        [GrowingNetworkPreflight sendPreflight];
        [[GrowingDeviceInfo currentDeviceInfo] resetSessionID];
        [GrowingVisitEvent send];
        
        
        if ([[GrowingCustomField shareInstance] growingVistorVar]) {
            [[GrowingCustomField shareInstance] sendVisitorEvent:[[GrowingCustomField shareInstance] growingVistorVar]];
        }
    }
    [GrowingActivationTime reset];
    
    
    if (![GrowingActivationTime didStartFromScratch])
    {
        UIWindow *window = [[UIApplication sharedApplication] growingMainWindow];
        UIViewController *vc = [[GrowingMediator sharedInstance] performTarget:window action:@"growingHook_curViewController" params:nil];
        [[GrowingMediator sharedInstance] performTarget:vc action:@"GROW_outOfLifetimeShow" params:nil];
    } else {
        _didStart = NO;
    }
    
    GrowingEBApplicationEvent *applicationEvent = [[GrowingEBApplicationEvent alloc] initWithLifeType:GrowingApplicationDidBecomeActive];
    [GrowingEventBus send:applicationEvent];
}

void growingWillResignActive()
{
    GrowingEBApplicationEvent *applicationEvent = [[GrowingEBApplicationEvent alloc] initWithLifeType:GrowingApplicationWillResignActive];
    [GrowingEventBus send:applicationEvent];
    
    _resignActiveDate = [NSDate date];
    
    [[GrowingEventManager shareInstance] sendEvents];
    GrowingEvent *lastPageEvent= [GrowingEventManager shareInstance].lastPageEvent;
    if(!lastPageEvent)
    {
        return;
    }
    GrowingEvent *closeEvent = [[GrowingEvent alloc] init];
    [closeEvent assignRadioType];
    closeEvent.dataDict[@"t"] = @"cls" ;
    closeEvent.dataDict[@"p"] = lastPageEvent.dataDict[@"p"];
    [[GrowingEventManager shareInstance] addEvent:closeEvent
                                         thisNode:nil
                                      triggerNode:nil
                                      withContext:nil];
}

void growingWillEnterForeground()
{
    
    if ([GrowingActivationTime didActivateInLongTime])
    {
        [GrowingNetworkPreflight sendPreflight];
        [[GrowingDeviceInfo currentDeviceInfo] resetSessionID];
        [GrowingVisitEvent send];
        [GrowingDeviceInfo currentDeviceInfo].isResetSIDByWillEnterForeground = YES;
        
        
        if ([[GrowingCustomField shareInstance] growingVistorVar]) {
            [[GrowingCustomField shareInstance] sendVisitorEvent:[[GrowingCustomField shareInstance] growingVistorVar]];
        }
        
    }  else {
        [GrowingDeviceInfo currentDeviceInfo].isResetSIDByWillEnterForeground = NO;
    }
    [GrowingDeviceInfo currentDeviceInfo].isApplicationInWillEnterForeground = YES;
    [GrowingActivationTime reset];
    
    GrowingEBApplicationEvent *applicationEvent = [[GrowingEBApplicationEvent alloc] initWithLifeType:GrowingApplicationWillEnterForeground];
    [GrowingEventBus send:applicationEvent];
}
