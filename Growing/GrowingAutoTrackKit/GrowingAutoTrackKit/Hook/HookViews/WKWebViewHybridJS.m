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


#import "WKWebViewHybridJS.h"
#import "GrowingNetworkConfig.h"
#import "GrowingCoreKit.h"
#import "GrowingEventNodeManager.h"
#import "GrowingGlobal.h"

@implementation WKWebViewHybridJS

+ (NSString *)hybridJS {
    return [self hybridJSSDKScript];
}

+ (NSString *)hybridJSSDKScript
{
    NSString *hybridJSName = nil;
#if kHybridModeTrack == 1
    hybridJSName = @"gio_hybrid.min.js";
#else
    hybridJSName = @"vds_hybrid.min.js";
#endif
    NSString *sdkUrl = [NSString stringWithFormat:@"%@/%@?sdkVer=%@&platform=iOS", [GrowingNetworkConfig.sharedInstance hybridJSSDKUrlPrefix], hybridJSName, [Growing sdkVersion]];
    return [self wrapperJSScriptWithLink:sdkUrl];
}

+ (NSString *)configHybridScript
{
    NSString *configString = [NSString stringWithFormat:@"{\"enableHT\":%@,\"disableImp\":%@,\"phoneWidth\":%f,\"phoneHeight\":%f,\"protocolVersion\":%d}", g_isHashTagEnabled?@"true":@"false", !g_enableImp?@"true":@"false", [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height, 1];
    return [NSString stringWithFormat:@"window._vds_hybrid_config = %@", configString];
}


+ (NSString *)wrapperJSScriptWithLink:(NSString *)link
{
    return [NSString stringWithFormat:@"javascript:(function(){try{if(window.self==window.top||document.head.childElementCount||document.body.childElementCount){var p=document.createElement('script');p.src='%@';document.head.appendChild(p);}}catch(e){}})()", link];
}
@end
