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


#import "GrowingMediator+GrowingDeepLink.h"
#import "NSURL+GrowingHelper.h"
#import "GrowingInstance.h"
#import "GrowingNetworkConfig.h"
#import "GrowingMobileDebugger.h"
#import "GrowingAlertMenu.h"
#import "GrowingDispatchManager.h"
#import "GrowingCocoaLumberjack.h"
#import "GrowingASLLoggerFormat.h"

@implementation GrowingMediator (GrowingDeepLink)

- (BOOL)isV1Url:(NSURL *)url
{
    return ([url.host isEqualToString:@"datayi.cn"] || [url.host hasSuffix:@".datayi.cn"]);
}

- (BOOL)isGrowingIOUrl:(NSURL *)url
{
    if(!url)
    {
        return NO;
    }
    
    
    
    BOOL isV1Url = [self isV1Url:url];
    
    if (!isV1Url && ![url.scheme hasPrefix:@"growing."] && !([url.absoluteString rangeOfString:@"growingio.com"].location != NSNotFound || [url.absoluteString rangeOfString:@"gio.ren"].location != NSNotFound))
    {
        return NO;
    }
    
    
    if (!isV1Url && ![[url host] isEqualToString:@"growing"] && !([url.absoluteString rangeOfString:@"growingio.com"].location != NSNotFound || [url.absoluteString rangeOfString:@"gio.ren"].location != NSNotFound))
    {
        return NO;
    }
    return YES;
}

- (BOOL)isShortChainUlink:(NSURL *)url
{
    if (!url) {
        return NO;
    }
    
    BOOL isShortChainUlink = ([url.host isEqualToString:@"gio.ren"] || [self isV1Url:url]) && [url.path componentsSeparatedByString:@"/"].count == 2;
    return isShortChainUlink;
}

- (BOOL)isLongChainDeeplink:(NSURL *)url
{
    if (!url) {
        return NO;
    }
    
    NSDictionary *params = url.growingHelper_queryDict;
    
    if (params[@"link_id"]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)performActionWithUrl:(NSURL *)url
{
    
    if (![self isGrowingIOUrl:url]) {
        return NO;
    }
    
    NSDictionary *params = url.growingHelper_queryDict;
    
    
    BOOL isShortChainUlink = [self isShortChainUlink:url];
    
    if (isShortChainUlink) {
        
        [GrowingInstance reportShortChainDeeplink:url];
        return YES;
    }
    
    if ([self isLongChainDeeplink:url]) {
        
        [GrowingInstance reportGIODeeplink:url];
        return YES;
    }
    
    if (![[url path] isEqualToString:@"/oauth2/token"]) {
        return NO;
    }
    
    
    NSString *openConsoleLog = params[@"openConsoleLog"];
    if ([openConsoleLog isEqualToString:@"Yes"] && ![GrowingLog.allLoggers containsObject:[GrowingASLLogger sharedInstance]]) {
        [GrowingLog addLogger:[GrowingASLLogger sharedInstance] withLevel:GrowingLogLevelAll];
        [GrowingASLLogger sharedInstance].logFormatter = [GrowingASLLoggerFormat new];
        return YES;
    }
    
    
    if ([params.allKeys containsObject:@"gtouchType"]) {
        return [[[GrowingMediator sharedInstance] performClass:@"GrowingTouchHandleURL" action:@"growingTouchHandleUrl:" params:@{@"0":params}] boolValue];
    }
    
    NSString *circleTypes = params[@"circleType"];
    NSString *token = [params[@"token"] stringByRemovingPercentEncoding];
    NSString *circleRoomNumber = params[@"circleRoomNumber"];
    NSString *dataCheckRoomNumber = params[@"dataCheckRoomNumber"];
    NSString *loginToken = [params[@"loginToken"] stringByRemovingPercentEncoding];
    NSString *wsHost = [params[@"wsHost"] stringByRemovingPercentEncoding];
    NSString *gtaHost = [params[@"gtaHost"] stringByRemovingPercentEncoding];
    NSString *paireKey = [params[@"pairKey"] stringByRemovingPercentEncoding];
    if ((!circleTypes.length || !loginToken.length) && !dataCheckRoomNumber)
    {
        return NO;
    }
    
    GrowingNetworkConfig.sharedInstance.customWsHost = wsHost;
    GrowingNetworkConfig.sharedInstance.customGtaHost = gtaHost;
    
    NSMutableDictionary *circleTypeDict = nil;
    circleTypeDict = [[NSMutableDictionary alloc] init];
    NSArray *arr = [circleTypes componentsSeparatedByString:@","];
    for (NSString* type in arr)
    {
        [circleTypeDict setValue:@YES forKey:type];
    }
    
    
    if (circleTypeDict[@"web"]) {
        void (^startWebCircleApp)(void) = ^() {
            [GrowingInstance setCircleType:GrowingCircleTypeWeb withParameter:paireKey];
        };
        [self authorizationWithToken:token loginToken:loginToken block:startWebCircleApp];
        
    } else if(circleTypeDict[@"debugger"] ) {
        [[GrowingMobileDebugger shareDebugger] debugWithRoomNumber:circleRoomNumber dataCheck:false];
    }else if (dataCheckRoomNumber){
        [[GrowingMobileDebugger shareDebugger] debugWithRoomNumber:dataCheckRoomNumber dataCheck:true];
    }else {
        GrowingCircleType circleType = GrowingCircleTypeNone;
        
        if (circleTypeDict[@"list"])
        {
            circleType = circleType | GrowingCircleTypeEventList;
        }
        if (circleTypeDict[@"drag"])
        {
            circleType = circleType | GrowingCircleTypeDragView;
        }
        if (circleTypeDict[@"replay"])
        {
            circleType = circleType | GrowingCircleTypeReplay;
        }
        if (circleTypeDict[@"heatmap"])
        {
            circleType = circleType | GrowingCircleTypeHeatMap | GrowingCircleTypeDragView;
        }
        
        
        if (circleType == GrowingCircleTypeNone)
        {
            circleType = GrowingCircleTypeDragView;
        }
        
        
        void (^startCircle)(void) = ^() {
            [GrowingDispatchManager dispatchInMainThread:^{
                [GrowingInstance setCircleType:circleType];
            }];
        };
        [self authorizationWithToken:token loginToken:loginToken block:startCircle];
        
    }
    return YES;
}

- (void)authorizationWithToken:(NSString *)token loginToken:(NSString *)loginToken block:(void(^)(void))block
{
    
    id loginModel = [[GrowingMediator sharedInstance] performClass:@"GrowingLoginModel" action:@"sdkInstance" params:nil];
    
    if (loginToken.length > 0)
    {
        void (^loginSuccess)(void) = ^ {
            [[GrowingMediator sharedInstance] performClass:@"GrowingLoginMenu" action:@"clearGrowingLoginMenu" params:nil];
            block();
        };
        
        void (^loginFailure)(NSString * _Nullable msg) = ^(NSString *msg) {
            GIOLogError(@"登陆失败：%@", msg);
            [GrowingAlertMenu alertWithTitle:@"登录失败"
                                        text:msg
                                     buttons:@[[GrowingMenuButton buttonWithTitle:@"确定" block:^(){
                void (^showSucceed)(void) = ^ {
                    block();
                };
                
                void (^showFail)(void) = ^ {
                    
                };
                [[GrowingMediator sharedInstance] performClass:@"GrowingLoginMenu" action:@"showWithSucceed:fail:" params:@{@"0":showSucceed, @"1":showFail}];
            }]]];
        };
        [[GrowingMediator sharedInstance] performTarget:loginModel action:@"loginWithLoginToken:success:failure:" params:@{@"0":loginToken, @"1":loginSuccess, @"2":loginFailure}];
    }
    else if (token.length > 0)
    {
        [[GrowingMediator sharedInstance] performTarget:loginModel action:@"loginWithToken:" params:@{@"0":token}];
        block();
    }
}

@end
