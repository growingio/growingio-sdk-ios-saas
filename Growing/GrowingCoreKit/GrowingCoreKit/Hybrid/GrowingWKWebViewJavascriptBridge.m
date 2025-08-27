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


#import "GrowingWKWebViewJavascriptBridge.h"
#import "GrowingWKWebViewJavascriptBridge_JS.h"
#import "GrowingWebViewJavascriptBridgeConfiguration.h"
#import "GrowingWebViewJavascriptMessage.h"
#import "GrowingCoreKit.h"
#import "GrowingInstance.h"
#import "GrowingDeviceInfo.h"

static NSString *const kGrowingWKWebViewJavascriptBridge = @"GrowingWebViewJavascriptBridge";

@interface GrowingWebViewJavascriptBridge () <WKScriptMessageHandler>
@end

@implementation GrowingWebViewJavascriptBridge
+ (instancetype)bridgeForWebView:(WKWebView *)webView {
    GrowingWebViewJavascriptBridge *bridge = [[self alloc] init];
    [webView.configuration.userContentController addScriptMessageHandler:bridge name:kGrowingWKWebViewJavascriptBridge];

    NSString *projectId = [GrowingInstance sharedInstance].accountID;
    NSString *appId = [GrowingDeviceInfo currentDeviceInfo].urlScheme;
    NSString *nativeSdkVersion = [Growing sdkVersion];
    int nativeSdkVersionCode = 0;
    GrowingWebViewJavascriptBridgeConfiguration *configuration = [GrowingWebViewJavascriptBridgeConfiguration configurationWithProjectId:projectId
                                                                                                                                   appId:appId
                                                                                                                        nativeSdkVersion:nativeSdkVersion
                                                                                                                    nativeSdkVersionCode:nativeSdkVersionCode];
    [webView.configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:[GrowingWKWebViewJavascriptBridge_JS createJavascriptBridgeJsWithNativeConfiguration:configuration]
                                                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                                                   forMainFrameOnly:NO]];
    return bridge;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:kGrowingWKWebViewJavascriptBridge]) {
        [GrowingWebViewJavascriptMessage handleJavascriptBridgeMessage:message.body];
    }
}


@end
