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


#import "GrowingJavascriptCore.h"
#import "GrowingAutoTrackEvent.h"
#import "GrowingManualTrackEvent.h"
#import "NSString+GrowingHelper.h"
#import "UIImage+GrowingHelper.h"
#import "GrowingNodeManager.h"
#import "UIView+GrowingNode.h"
#import "UIApplication+GrowingNode.h"
#import "UIWindow+Growing.h"
#import "UIViewController+Growing.h"
#import "UIViewController+GrowingNode.h"
#import "GrowingLocalCircleModel.h"
#import "NSArray+GrowingHelper.h"
#import "GrowingTaggedViews.h"
#import "GrowingGlobal.h"
#import "GrowingInstance.h"
#import "GrowingNetworkConfig.h"
#import "GrowingLoginModel.h"
#import "GrowingDeviceInfo.h"
#import "GrowingCustomField.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingEventNodeManager.h"
#import <GrowingAutoTrackKit/GrowingAutoTrackKit.h>
static NSString * GrowingJavascriptBridgeSignature = @"/growinghybridsdk";
NSString * WKScriptMessagePredefinedName = @"GrowingIO_WKWebView";
NSString * webCircleHybridEvent = @"webCircleHybridEvent";
NSString * onDOMChanged = @"onDOMChanged";

NSString * WKScriptMessageBodyOnPageLoaded = @"GrowingIO_OnPageLoaded";

NSString *GrowingJavascriptSDKVersion = @"1.1";


static NSArray * UserApplicationPathKeys = nil;
static NSArray * UserApplicationPathSubstitutions = nil;

@interface GrowingJavascriptCore ()

@property (nonatomic, retain, readonly) UIScrollView * scrollView;
@property (nonatomic, weak) UIViewController * hostViewController;
@property (nonatomic, copy) NSString * xPathInHost;
@property (nonatomic, assign) NSInteger keyIndexInHost;
@property (nonatomic, retain) NSDictionary * pageData;
@property (nonatomic, assign) NSUInteger sequenceId;
@property (nonatomic, retain) NSMutableDictionary<NSString *, JavascriptCallbackType> * callbackCache;
@property (nonatomic, assign) BOOL isCircleOnlyJavascriptContentLoaded;

@end

@implementation GrowingJavascriptCore


+ (BOOL)enableTryCatchBlock
{
    return YES;
}

static NSHashTable<GrowingJavascriptCore*> *allJsCore = nil;
+ (void)addGlobalNewJSCore:(GrowingJavascriptCore*)jsCore
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allJsCore = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:2];
    });
    [allJsCore addObject:jsCore];
}

+ (NSString *)nativeInfo {
    NSString *ai = [GrowingInstance sharedInstance].accountID;
    NSString *page = [[[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController] growingNodeDataDict][@"p"];
    NSString *domain = [GrowingDeviceInfo currentDeviceInfo].bundleID;
    NSString *gtaHost= GrowingNetworkConfig.sharedInstance.customGtaHost ?: @"";
    if (!ai.length || !page.length || !domain.length)
    {
        return @"{}";
    }
    
    NSString *cs1 = [GrowingCustomField shareInstance].cs1 ?: @"";
    NSString *token = [GrowingLoginModel sdkInstance].token ?: @"";
    NSString *sessionId = [GrowingDeviceInfo currentDeviceInfo].sessionID ?: @"";
    NSString *u = [GrowingDeviceInfo currentDeviceInfo].deviceIDString ?: @"";
    NSDictionary *paramDict = @{@"ai" : ai,
                                @"d" : domain,
                                @"u" : u,
                                @"s" : sessionId,
                                @"cs1" : cs1,
                                @"p" : page,
                                @"token" : token,
                                @"gtaHost":gtaHost
                                };
    
    return [paramDict growingHelper_jsonString];
    
}

+ (void)allWebViewExecuteJavascriptMethod:(NSString*)methodName
                            andParameters:(NSArray*)methodParameters
{
    NSArray<GrowingJavascriptCore*> *array = allJsCore.allObjects;
    [array enumerateObjectsUsingBlock:^(GrowingJavascriptCore * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj executeJavascriptMethod:methodName
                       andParameters:methodParameters
                        withCallback:nil];
    }];
}


+ (void)startWebViewCircle
{
    NSArray<GrowingJavascriptCore*> *array = allJsCore.allObjects;
    [array enumerateObjectsUsingBlock:^(GrowingJavascriptCore * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj startCircleIfNeed];
    }];
}

#pragma mark - 初始化

- (instancetype)initWithWKWebView:(UIView *)wkWebView
{
    self = [super init];
    if (self)
    {
        if ([GrowingJavascriptCore isWKWebView:wkWebView])
        {
            _wkWebView = wkWebView;
        }
        else
        {
            _wkWebView = nil;
        }
        _webView = wkWebView;
        [self privateInit];
        
    }
    return self;
}

- (void)privateInit
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (UserApplicationPathKeys == nil || UserApplicationPathSubstitutions == nil)
        {
            NSString * UserApplicationHomeDir = nil;
            NSString * UserApplicationHomeDirEnc = nil;
            NSString * UserApplicationBundleDir = nil;
            NSString * UserApplicationBundleDirEnc = nil;
            NSString * UserApplicationHomeGUID = nil;
            NSString * UserApplicationBundleGUID = nil;
            NSArray<NSString *> * pathComponents = nil;
            NSRange asciiPrintableRange = NSMakeRange(32, 127-32); 
            
            UserApplicationHomeDir = NSHomeDirectory();
            UserApplicationHomeDirEnc = [UserApplicationHomeDir stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithRange:asciiPrintableRange]];
            if ([UserApplicationHomeDirEnc isEqualToString:UserApplicationHomeDir])
            {
                UserApplicationHomeDirEnc = nil;
            }
            pathComponents = [UserApplicationHomeDir pathComponents];
            if (pathComponents.count > 0)
            {
                UserApplicationHomeGUID = pathComponents.lastObject;
            }
            UserApplicationBundleDir = [[NSBundle mainBundle] bundlePath];
            UserApplicationBundleDirEnc = [UserApplicationBundleDir stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithRange:asciiPrintableRange]];
            if ([UserApplicationBundleDirEnc isEqualToString:UserApplicationBundleDir])
            {
                UserApplicationBundleDirEnc = nil;
            }
            pathComponents = [UserApplicationBundleDir pathComponents];
            if (pathComponents.count > 1)
            {
                UserApplicationBundleGUID = [pathComponents objectAtIndex:(pathComponents.count - 2)];
            }
        #define VALIDATE(S) (S.length > 0 ? S : [NSNull null])
            UserApplicationPathKeys = @[VALIDATE(UserApplicationHomeDir),
                                        VALIDATE(UserApplicationBundleDir),
                                        VALIDATE(UserApplicationHomeDirEnc),
                                        VALIDATE(UserApplicationBundleDirEnc),
                                        VALIDATE(UserApplicationHomeGUID),
                                        VALIDATE(UserApplicationBundleGUID),
                                        ];
            UserApplicationPathSubstitutions = @[@"/_growing_io_app_home_dir",
                                                 @"/_growing_io_app_bundle_dir",
                                                 @"/_growing_io_app_home_dir_enc",
                                                 @"/_growing_io_app_bundle_dir_enc",
                                                 @"/_growing_io_app_home_dir_guid",
                                                 @"/_growing_io_app_bundle_dir_guid",
                                                 ];
        #undef VALIDATE
        }
    });

    self.sequenceId = 1;
    self.callbackCache = [[NSMutableDictionary alloc] init];
    self.responsive = NO;
    self.isCircleOnlyJavascriptContentLoaded = NO;
    
    [[self class] addGlobalNewJSCore:self];
    
    
    [self executeJavascript:@"window._vds_ios = true;" force:YES];
}


- (NSString *)configHybridScript
{
    NSString *configString = [NSString stringWithFormat:@"{\"enableHT\":%@,\"disableImp\":%@,\"phoneWidth\":%f,\"phoneHeight\":%f,\"protocolVersion\":%d}", g_isHashTagEnabled?@"true":@"false", !g_enableImp?@"true":@"false", [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height, 1];
    return [NSString stringWithFormat:@"window._vds_hybrid_config = %@", configString];
}



- (NSString *)configHybridNativeInfo
{
    GrowingNodeManager *manager = [[GrowingEventNodeManager alloc] initWithNodeAndParent:self.webView checkBlock:nil];
    __weak GrowingJavascriptCore * wself = self;
    __block  NSString * xPath  = nil;
    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode,
                                           GrowingNodeManagerEnumerateContext *context) {
        if (aNode == wself.webView)
        {
            xPath = [context xpath];
        }
    }];

    NSMutableDictionary  *nativeInfoDic = [[[GrowingJavascriptCore nativeInfo] growingHelper_dictionaryObject] mutableCopy];
    NSMutableArray  *dirInfo = [[NSMutableArray alloc] initWithCapacity:6];
    nativeInfoDic[@"x"] = xPath ;
    const NSInteger count = UserApplicationPathKeys.count;
    for (NSInteger i = 0; i < count; i++)
    {
        if (UserApplicationPathKeys[i] != [NSNull null] && UserApplicationPathKeys[i] != nil)
        {
            [dirInfo addObject:UserApplicationPathKeys[i]];
        }else{
            [dirInfo addObject:@"null"];
        }
    }
    nativeInfoDic[@"dirInfo"] = [dirInfo growingHelper_jsonString] ;
    NSString *nativeInfo = [nativeInfoDic growingHelper_jsonString];
    return [NSString stringWithFormat:@"window._vds_hybrid_native_info = %@", nativeInfo];
}

- (NSString *)hybridJSSDKScript
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

- (NSString *)hybridJSSDKCircleScript
{
    NSString *sdkCircleUrl = [NSString stringWithFormat:@"%@/vds_hybrid_circle_plugin.min.js?sdkVer=%@&platform=iOS", [GrowingNetworkConfig.sharedInstance hybridJSSDKUrlPrefix], [Growing sdkVersion]];
    return [self wrapperJSScriptWithLink:sdkCircleUrl];
}


- (NSString *)hybridJSSDKCircleScriptWeb
{
    NSString *sdkCircleUrl = [NSString stringWithFormat:@"%@/vds_web_circle_plugin.min.js?sdkVer=%@&platform=iOS", [GrowingNetworkConfig.sharedInstance hybridJSSDKUrlPrefix], [Growing sdkVersion]];
    return [self wrapperJSScriptWithLink:sdkCircleUrl];
}



- (NSString *)wrapperJSScriptWithLink:(NSString *)link
{
    return [NSString stringWithFormat:@"javascript:(function(){try{var p=document.createElement('script');p.src='%@';document.head.appendChild(p);}catch(e){}})()", link];
}

#pragma mark - 识别自身环境

- (void)refreshContext
{
    if (self.webView == nil)
    {
        return;
    }
    GrowingNodeManager *manager = [[GrowingEventNodeManager alloc] initWithNodeAndParent:self.webView
                                                                              checkBlock:nil];
    GrowingRootNode *rootNode = [manager nodeAtFirst];
    NSDictionary *pageData = [rootNode growingNodeDataDict];
    
    if (!manager || rootNode != [GrowingRootNode rootNode])
    {
        return;
    }
    self.hostViewController = nil;
    self.keyIndexInHost = [GrowingNodeItemComponent indexNotDefine];
    self.xPathInHost = nil;
    __weak GrowingJavascriptCore * wself = self;

    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode,
                                           GrowingNodeManagerEnumerateContext *context) {
        if (aNode == wself.webView)
        {
            wself.xPathInHost = [context xpath];
            wself.keyIndexInHost = [context nodeKeyIndex];
            wself.pageData = pageData;
            wself.hostViewController = [[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController];
            [context stop];
        }
    }];
}

- (void)onPageLoaded
{
    self.isCircleOnlyJavascriptContentLoaded = NO; 
    [[GrowingTaggedViews shareInstance] removeAsyncNativeHandler:self];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)( 0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self executeBuiltInJavascript];
    });
}

#pragma mark - Native调用Javascript

- (void)executeSyncJavascript:(NSString *)javascript
                 withCallback:(JavascriptCallbackType)javascriptCallback
{
    if ([GrowingJavascriptCore enableTryCatchBlock])
    {
        javascript = [NSString stringWithFormat:@"try { %@ } catch (e) { }", javascript.length > 0 ? javascript : @";"];
    }
  
    if (self.wkWebView != nil)
    {
        CALL_INSTANCE_METHOD_RETURNVOID_ID_ID([GrowingJavascriptCore WKWebViewClass], self.wkWebView,
                                              @selector(evaluateJavaScript:completionHandler:),
                                              javascript, ^(id ret, NSError * error) {
                                                  NSDictionary * callbackDictionary = nil;
                                                  if (error == nil)
                                                  {
                                                      if ([ret isKindOfClass:[NSDictionary class]])
                                                      {
                                                          callbackDictionary = ret;
                                                      }
                                                      else if ([ret isKindOfClass:[NSString class]])
                                                      {
                                                          id dict = [(NSString *)ret growingHelper_jsonObject];
                                                          if ([dict isKindOfClass:[NSDictionary class]])
                                                          {
                                                              callbackDictionary = dict;
                                                          }
                                                      }
                                                  }
                                                  if (javascriptCallback != nil)
                                                  {
                                                      javascriptCallback(callbackDictionary);
                                                  }
                                              });
        
    }
    else
    {
        if (javascriptCallback != nil)
        {
            javascriptCallback(nil);
        }
    }
}

- (void)executeJavascriptMethod:(NSString *)methodName
                  andParameters:(NSArray *)methodParameters
                   withCallback:(JavascriptCallbackType)javascriptCallback
{
    [self executeJavascriptMethod:methodName andParameters:methodParameters withCallback:javascriptCallback force:NO];
}

- (void)executeJavascriptMethod:(NSString *)methodName
                  andParameters:(NSArray *)methodParameters
                   withCallback:(JavascriptCallbackType)javascriptCallback
                          force:(BOOL)force
{
    NSMutableString * javascriptLine = [NSMutableString stringWithString:methodName];
    NSString * sequenceString = [NSString stringWithFormat:@"seq%lu", (unsigned long)self.sequenceId];
    
    if (javascriptCallback != nil)
    {
        if (methodParameters == nil)
        {
            methodParameters = @[[NSString stringWithFormat:@"\"%@\"", sequenceString]];
        }
        else
        {
            methodParameters = [methodParameters arrayByAddingObject:[NSString stringWithFormat:@"\"%@\"", sequenceString]];
        }
    }
    
    if (methodParameters.count > 0)
    {
        [javascriptLine appendFormat:@"(%@", methodParameters[0]];
        for (NSUInteger i = 1; i < methodParameters.count; i++)
        {
            [javascriptLine appendFormat:@", %@", methodParameters[i]];
        }
        [javascriptLine appendString:@");"];
    }
    else
    {
        [javascriptLine appendString:@"();"];
    }
    
    if (javascriptCallback != nil)
    {
        self.callbackCache[sequenceString] = javascriptCallback;
        self.sequenceId++;
    }
    
    [self executeJavascript:javascriptLine force:force];
}

- (void)executeJavascript:(NSString *)javascript
{
    [self executeJavascript:javascript force:NO];
}

- (void)executeJavascript:(NSString *)javascript onFinish:(void (^)())onFinish
{
    [self executeJavascript:javascript force:NO onFinish:onFinish];
}

- (void)executeJavascript:(NSString *)javascript force:(BOOL)force
{
    [self executeJavascript:javascript force:force onFinish:nil];
}

- (void)executeJavascript:(NSString *)javascript force:(BOOL)force onFinish:(void (^)())onFinish
{
    if (!(self.responsive || force))
    {
        return;
    }
    __weak GrowingJavascriptCore * wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (wself != nil && (wself.responsive || force))
        {
            NSString * js = (javascript.length > 0 ? javascript : @";");
            if ([GrowingJavascriptCore enableTryCatchBlock])
            {
                js = [NSString stringWithFormat:@"try { %@ } catch (e) { }", js];
            }
            
            if (wself.wkWebView != nil)
            {
                CALL_INSTANCE_METHOD_RETURNVOID_ID_ID([GrowingJavascriptCore WKWebViewClass], wself.wkWebView,
                                                      @selector(evaluateJavaScript:completionHandler:),
                                                      js, nil);
                
            }
            self.responsive = YES;
            if (onFinish)
            {
                onFinish();
            }
        }
    });
}


- (void)executeBuiltInJavascript
{


    
    [self executeJavascript:[self configHybridNativeInfo] force:YES];

    
    if (self.webView == self.wkWebView)
    {
        [self executeJavascriptMethod:@"_vds_hybrid.startTracing"
                        andParameters:@[@"\"WKWebView\""]
                         withCallback:nil
                                force:YES];
    }
    
    [self startCircleIfNeed];
}

- (void)executeHelloJavascript
{
    [self executeJavascriptMethod:@"_vds_hybrid.pollEvents" andParameters:nil withCallback:nil force:YES];
}

#pragma mark - Javascript调用Native

- (BOOL)handleWKWebViewCallback:(WKScriptMessage *)scriptMessage 
API_AVAILABLE(ios(8.0))
{
    if ([scriptMessage.name isEqualToString:webCircleHybridEvent]) {
        if (self.webScoketDelegate && [self.webScoketDelegate respondsToSelector:@selector(didRecieveWkWebivewMesage:andWebview:)]) {
            if (@available(iOS 8.0, *)) {
                [self.webScoketDelegate didRecieveWkWebivewMesage:scriptMessage andWebview:self.wkWebView];
            }
        }
    }

    if ([scriptMessage.name isEqualToString:onDOMChanged]) {
        if (self.webScoketDelegate && [self.webScoketDelegate respondsToSelector:@selector(onDomChangeWkWebivew)]) {
            if (@available(iOS 8.0, *)) {
                [self.webScoketDelegate onDomChangeWkWebivew];
            }
        }
    }
    
    
    if ([scriptMessage.name isEqualToString:WKScriptMessagePredefinedName]) {
        
        if (self.wkWebView.growingAttributesDonotTrack) {
            return YES;
        }
        
        if (g_allWebViewsDisabled && !((WKWebView *)self.wkWebView).growingAttributesIsTracked) {
            return YES;
        }
        
        if ([scriptMessage.body isKindOfClass:[NSArray class]]) {
            NSArray * callbackDataDictionaryArray = (NSArray *)scriptMessage.body;
            [self handleCallback:callbackDataDictionaryArray];
            return YES;
        } else if ([scriptMessage.body isKindOfClass:[NSString class]] &&
                   [scriptMessage.body isEqualToString:WKScriptMessageBodyOnPageLoaded]) {
            
            
            [self onPageLoaded];
            return YES;
        }
    }
    
    return NO;
}

- (void)startCircleIfNeed
{
    __weak GrowingJavascriptCore *wself = self;
    if (!self.isCircleOnlyJavascriptContentLoaded
        && [GrowingInstance circleType] == GrowingCircleTypeWeb)
    {
        
        [self executeJavascript:[self hybridJSSDKCircleScriptWeb]
                          force:YES
                       onFinish:^() {
                           GrowingJavascriptCore * sself = wself;
                           if (sself == nil)
                           {
                               return;
                           }
                           sself.isCircleOnlyJavascriptContentLoaded = YES;
                       }];
    }else if (!self.isCircleOnlyJavascriptContentLoaded && [GrowingInstance circleType] == GrowingCircleTypeDragView){
        
        [self executeJavascript:[self hybridJSSDKCircleScript]
                          force:YES
                       onFinish:^() {
                           GrowingJavascriptCore * sself = wself;
                           if (sself == nil)
                           {
                               return;
                           }
                           sself.isCircleOnlyJavascriptContentLoaded = YES;
                       }];
    }
}

- (BOOL)maybeContextChanged:(NSArray *)callbackDataDictionaryArray
{
    if (callbackDataDictionaryArray.count == 1) {
        NSDictionary *callbackDataDictionary = callbackDataDictionaryArray.firstObject;
        NSString *eventType = callbackDataDictionary[@"t"];
        if ([eventType isEqualToString:@"clck"]) {
            return NO;
        } else if ([eventType isEqualToString:@"imp"]) {
            return NO;
        } else {
            return YES;
        }
    } else {
        return YES;
    }
}

- (void)handleCallback:(NSArray<NSDictionary *> *)callbackDataDictionaryArray
{
    
    [self executeHelloJavascript];
    
    
    if ([self maybeContextChanged:callbackDataDictionaryArray]) {
        [self refreshContext];
    }

    for (NSUInteger i = 0; i < callbackDataDictionaryArray.count; i++)
    {
        NSDictionary * callbackDataDictionary = callbackDataDictionaryArray[i];
        JavascriptCallbackType javascriptCallback = nil;
        NSString * sequenceId = callbackDataDictionary[@"seqid"];
        if (sequenceId.length > 0)
        {
            javascriptCallback = self.callbackCache[sequenceId];
            [self.callbackCache removeObjectForKey:sequenceId];
        }
        else
        {
            NSDictionary<NSString *, JavascriptCallbackType> * builtInCallbackCache =
            @{
              @"page":^(NSDictionary * javascriptCallback) {
                  [self handlePageCallback:callbackDataDictionary];
              },
              @"imp" :^(NSDictionary * javascriptCallback) {
                  [self handleImpressionCallback:callbackDataDictionary];
              },
              @"clck":^(NSDictionary * javascriptCallback) {
                  [self handleClickCallback:callbackDataDictionary];
              },
              @"chng" : ^(NSDictionary * javascriptCallback) {
                  [self handleChangeCallback:callbackDataDictionary];
              },
              @"sbmt" : ^(NSDictionary * javascriptCallback) {
                  [self handleSubmitCallback:callbackDataDictionary];
              },
              
#if kHybridModeTrack == 1
              @"cstm" : ^(NSDictionary * javascriptCallback) {
                  [self handleCustomEventCallback:callbackDataDictionary];
              },
              @"pvar" : ^(NSDictionary * javascriptCallback) {
                  [self handlePageVarEventCallback:callbackDataDictionary];
              },
              @"evar" : ^(NSDictionary * javascriptCallback) {
                  [self handleEVarEventCallback:callbackDataDictionary];
              },
              @"ppl" : ^(NSDictionary * javascriptCallback) {
                  [self handlePeopleVarEventCallback:callbackDataDictionary];
              },
              @"hybridSetUserID" : ^(NSDictionary * javascriptCallback) {
                  [self handleSetUserIDEventCallback:callbackDataDictionary];
              },
              @"hybridClearUserID" : ^(NSDictionary * javascriptCallback) {
                  [self  handleClearUserIDEventCallback:callbackDataDictionary];
              },
              @"hybridSetVisitor" : ^(NSDictionary * javascriptCallback) {
                  [self  handleVisitorEventCallback:callbackDataDictionary];
              },
#endif
              };
            
            NSString *type = callbackDataDictionary[@"t"];
            javascriptCallback = builtInCallbackCache[type];
        }
        if (javascriptCallback != nil)
        {
            javascriptCallback(callbackDataDictionary);
        }
    }
}

- (void)handlePageCallback:(NSDictionary *)callbackData
{
    
    if (self.hostViewController.view.window != nil)
    {
        NSDictionary * pageData = [self getPageDataFromCallbackDictionary:callbackData];
        [GrowingPageEvent sendEventWithJavascriptCore:self andPageDataDict:pageData];
    }
}

- (void)handleImpressionCallback:(NSDictionary *)callbackData
{
    
    if (self.hostViewController.view.window != nil)
    {
        if (!g_enableImp)
        {
            return;
        }
        
        NSDictionary * pageData = [self getPageDataFromCallbackDictionary:callbackData];
        NSArray<GrowingDullNode *> * allNodes = [self getAllNodesFromCallbackDictionary:callbackData];
        [GrowingImpressionEvent sendEventsWithJavascriptCore:self
                                                    andNodes:allNodes
                                                   eventType:GrowingEventTypeH5Element
                                             andPageDataDict:pageData];
    }
}

- (void)handleClickCallback:(NSDictionary *)callbackData
{
    
    if (self.hostViewController.view.window != nil)
    {
        NSDictionary * pageData = [self getPageDataFromCallbackDictionary:callbackData];
        NSArray<GrowingDullNode *> * allNodes = [self getAllNodesFromCallbackDictionary:callbackData];
        [GrowingClickEvent sendEventsWithJavascriptCore:self
                                               andNodes:allNodes
                                              eventType:GrowingEventTypeH5ElementClick
                                        andPageDataDict:pageData];
    }
}


- (void)handleChangeCallback:(NSDictionary *)callbackData {
    
    if (self.hostViewController.view.window != nil)
    {
        NSDictionary * pageData = [self getPageDataFromCallbackDictionary:callbackData];
        NSArray<GrowingDullNode *> * allNodes = [self getAllNodesFromCallbackDictionary:callbackData];
        [GrowingTextEditContentChangeEvent sendEventsWithJavascriptCore:self
                                                               andNodes:allNodes
                                                              eventType:GrowingEventTypeH5ElementChangeText
                                                        andPageDataDict:pageData];
    }
}


- (void)handleSubmitCallback:(NSDictionary *)callbackData {
    if (self.hostViewController.view.window != nil)
    {
        NSDictionary * pageData = [self getPageDataFromCallbackDictionary:callbackData];
        NSArray<GrowingDullNode *> * allNodes = [self getAllNodesFromCallbackDictionary:callbackData];
        [GrowingSubmitEvent sendEventsWithJavascriptCore:self
                                                andNodes:allNodes
                                               eventType:GrowingEventTypeH5ElementSubmit
                                         andPageDataDict:pageData];
    }
}


- (void)handleCustomEventCallback:(NSDictionary *)callbackData {
    [GrowingCustomTrackEvent sendEventWithJavascriptCore:self andPageDataDict:callbackData];
}


- (void)handlePageVarEventCallback:(NSDictionary *)callbackData {
    [GrowingPvarEvent sendEventWithJavascriptCore:self andPageDataDict:callbackData];
}


- (void)handleEVarEventCallback:(NSDictionary *)callbackData {
    [GrowingEvarEvent sendEventWithJavascriptCore:self andPageDataDict:callbackData];
}


- (void)handlePeopleVarEventCallback:(NSDictionary *)callbackData {
    [GrowingPeopleVarEvent sendEventWithJavascriptCore:self andPageDataDict:callbackData];
}


- (void)handleSetUserIDEventCallback:(NSDictionary *)callbackData {
    [Growing setUserId:[callbackData objectForKey:@"userID"]];
}


- (void)handleClearUserIDEventCallback:(NSDictionary *)callbackData {
    [Growing clearUserId];
}


- (void)handleVisitorEventCallback:(NSDictionary *)callbackData {
    NSObject * visitor = [callbackData objectForKey:@"visitorJson"] ;
    if ([visitor isKindOfClass:[NSDictionary class]])
    {
       [Growing setVisitor:(NSDictionary *)visitor ];
    }
}

#pragma mark - 向Native代码提供的API

- (void)highlightElementAtPoint:(CGPoint)point 
{
    if (self.webView == nil)
    {
        return;
    }
    point = [self.webView.window convertPoint:point toView:self.webView];

    
    point.y -= self.scrollView.contentInset.top;
    
    
    if ([self.scrollView respondsToSelector:@selector(safeAreaInsets)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
        point.y -= self.scrollView.safeAreaInsets.top;
#pragma clang diagnostic pop
    }
    
    
    
    
    
    
    
    [self executeJavascriptMethod:@"_vds_hybrid.hoverOn"
                    andParameters:@[[NSString stringWithFormat:@"%lf", point.x],
                                    [NSString stringWithFormat:@"%lf", point.y]]
                     withCallback:nil];
}

- (void)findNodeAtPoint:(CGPoint)point 
           withCallback:(void(^)(NSArray<GrowingDullNode *> * nodes, NSDictionary * pageData))callback
{
    if (callback == nil)
    {
        return;
    }
    [self executeJavascriptMethod:@"_vds_hybrid.findElementAtPoint"
                    andParameters:nil
                     withCallback:^void(NSDictionary * callbackData) {
                         
                         
                         NSString * nodeType = callbackData[@"t"];
                         if (![nodeType isEqualToString:@"snap"])
                         {
                             callback(nil, nil);
                             return;
                         }
                         NSDictionary * pageData = [self getPageDataFromCallbackDictionary:callbackData];
                         NSArray<GrowingDullNode *> * allNodes = [self getAllNodesFromCallbackDictionary:callbackData];
                         callback(allNodes, pageData);
                     }];
}

- (void)cancelHighlight
{
    [self executeJavascriptMethod:@"_vds_hybrid.cancelHover"
                    andParameters:nil
                     withCallback:nil];
}

- (void)impressAllChildren
{
    [self executeJavascriptMethod:@"_vds_hybrid.impressAllElements"
                    andParameters:@[@"true"] 
                     withCallback:nil];
}

- (void)getAllNode:(void(^)(NSArray<GrowingDullNode *> * nodes, NSDictionary * pageData))callback
{
    [self executeJavascriptMethod:@"_vds_hybrid.snapshotAllElements"
                    andParameters:nil
                     withCallback:^void(NSDictionary * callbackData) {
                         
                         
                         NSString * nodeType = callbackData[@"t"];
                         if (![nodeType isEqualToString:@"snap"])
                         {
                             callback(nil, nil);
                             return;
                         }
                         NSDictionary * pageData = [self getPageDataFromCallbackDictionary:callbackData];
                         NSArray<GrowingDullNode *> * allNodes = [self getAllNodesFromCallbackDictionary:callbackData];
                         callback(allNodes, pageData);
                     }];
}

- (void)getPageInfoWithCallback:(void(^)(NSDictionary * pageData))callback
{
    [self executeSyncJavascript:@"_vds_hybrid.getPageInfo()"
                   withCallback:callback];
}

#pragma mark - 一些工具方法

+ (Class)WKWebViewClass
{
    static Class c = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = NSClassFromString(@"WKWebView");
    });
    return c;
}

+ (BOOL)isWKWebView:(UIView *)wkWebView
{
    return [GrowingJavascriptCore WKWebViewClass] != nil
        && [wkWebView isKindOfClass:[GrowingJavascriptCore WKWebViewClass]];
}

+ (NSString *)jointField:(NSString *)fieldA withField:(NSString *)fieldB
{
    return [NSString stringWithFormat:@"%@%@%@", fieldA ?: @"", FIELD_SEPARATOR, fieldB ?: @""];
}

- (NSString *)jointField:(NSString *)fieldA withField:(NSString *)fieldB
{
    return [[self class] jointField:fieldA withField:fieldB];
}

- (NSString *)joinXPath:(NSString *)nativeXPath hybridXPaths:(NSArray *)xpaths
{
    if (!nativeXPath.length || !xpaths.count) return @"";
    NSMutableString *joinedXPaths = [[NSMutableString alloc] init];
    for (NSString *xpath in xpaths) {
        [joinedXPaths appendFormat:@"%@%@%@,", nativeXPath, FIELD_SEPARATOR, xpath];
    }
    return [joinedXPaths substringToIndex:joinedXPaths.length-1];
}

+ (BOOL)parseJointField:(NSString *)jointField toFieldA:(NSMutableString *)fieldA toFieldB:(NSMutableString *)fieldB
{
    NSRange separatorRange = [jointField rangeOfString:FIELD_SEPARATOR];
    if (separatorRange.location == NSNotFound)
    {
        return NO;
    }
    else
    {
        [fieldA setString:[jointField substringToIndex:separatorRange.location]];
        [fieldB setString:[jointField substringFromIndex:(separatorRange.location + separatorRange.length)]];
        return YES;
    }
}

- (BOOL)parseJointField:(NSString *)jointField toFieldA:(NSMutableString *)fieldA toFieldB:(NSMutableString *)fieldB
{
    return [[self class] parseJointField:jointField toFieldA:fieldA toFieldB:fieldB];
}

- (UIScrollView *)scrollView
{
    if (self.wkWebView != nil)
    {
        
        CALL_INSTANCE_METHOD_RETURNID([GrowingJavascriptCore WKWebViewClass], self.wkWebView, @selector(scrollView));
        UIScrollView * scrollView = returnId;
        return scrollView;
        
    }
    return nil;
}

- (NSString *)stringByRemovingLocalDir:(NSString *)string
{
    const NSInteger count = UserApplicationPathKeys.count;
    for (NSInteger i = 0; i < count; i++)
    {
        if (UserApplicationPathKeys[i] != [NSNull null] && UserApplicationPathKeys[i] != nil)
        {
            string = [string stringByReplacingOccurrencesOfString:UserApplicationPathKeys[i]
                                                       withString:UserApplicationPathSubstitutions[i]];
        }
    }
    return string;
}

- (NSString *)stringByAddingLocalDir:(NSString *)string
{
    const NSInteger count = UserApplicationPathKeys.count;
    for (NSInteger i = 0; i < count; i++)
    {
        if (UserApplicationPathKeys[i] != [NSNull null])
        {
            string = [string stringByReplacingOccurrencesOfString:UserApplicationPathSubstitutions[i]
                                                       withString:UserApplicationPathKeys[i]];
        }
    }
    return string;
}

- (NSDictionary *)getPageDataFromCallbackDictionary:(NSDictionary *)callbackData
{
    
    
    NSMutableDictionary * pageData = [[NSMutableDictionary alloc] init];
    NSEnumerator<NSString *> * keyEnumerator = [callbackData keyEnumerator];
    NSString * key = nil;
    while (key = [keyEnumerator nextObject])
    {
        if ([key isEqualToString:@"e"])
        {
            continue;
        }
        
        
        if ([key isEqualToString:@"p"] || [key isEqualToString:@"q"] || [key isEqualToString:@"h"] || [key isEqualToString:@"rp"])
        {
            pageData[key] = [self stringByRemovingLocalDir:callbackData[key]];
        }
        else
        {
            pageData[key] = callbackData[key];
        }
    }
    
    return pageData;
}

- (NSArray<GrowingDullNode *> *)getAllNodesFromCallbackDictionary:(NSDictionary *)callbackData
{
    NSArray * nodeDictionaryArray = callbackData[@"e"];
    
    
    BOOL global_isHybridTrackingEditText = [callbackData[@"isTrackingEditText"] boolValue];
    
    NSMutableArray * allNodes = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < nodeDictionaryArray.count; i++)
    {
        NSDictionary * nodeDictionary = nodeDictionaryArray[i];
        [allNodes addObject:[self parseNode:nodeDictionary global_isTrackingEditText:global_isHybridTrackingEditText]];
    }
    return allNodes;
}


- (GrowingDullNode *)parseNode:(NSDictionary *)nodeDictionary global_isTrackingEditText:(BOOL)global_isHybridTrackingEditText
{
    
    
    BOOL isHybridTrackingEditText = [[nodeDictionary allKeys] containsObject:@"isTrackingEditText"] ? [nodeDictionary[@"isTrackingEditText"] boolValue] : global_isHybridTrackingEditText;
    
    
    NSString * nodeName = @"H5元素";
    
    NSNumber * frameHeight = nodeDictionary[@"eh"];
    NSNumber * frameWidth = nodeDictionary[@"ew"];
    NSNumber * frameOriginX = nodeDictionary[@"ex"];
    NSNumber * frameOriginY = nodeDictionary[@"ey"];
    CGRect frame;
    if (frameHeight == nil || frameWidth == nil || frameOriginX == nil || frameOriginY == nil)
    {
        frame = CGRectZero;
    }
    else
    {
        CGFloat scale = self.scrollView.zoomScale;
        
        frame = CGRectMake(frameOriginX.floatValue * scale,
                           frameOriginY.floatValue * scale + self.scrollView.contentInset.top,
                           frameWidth.floatValue * scale,
                           frameHeight.floatValue * scale);
        
        if ([self.webView respondsToSelector:@selector(safeAreaInsets)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
            frame.origin.y += self.webView.safeAreaInsets.top;
#pragma clang diagnostic pop
        }
        
        frame = [self.webView convertRect:frame toView:self.webView.window];
        CGRect webViewFrame = [self.webView convertRect:self.webView.bounds toView:self.webView.window];
        frame = CGRectIntersection(frame, webViewFrame);
        if (CGRectIsNull(frame))
        {
            frame = CGRectZero;
        }
    }
    
    NSString *nodeContent = nodeDictionary[@"v"];
    NSInteger nodeKeyIndex = (nodeDictionary[@"idx"] != nil ? [nodeDictionary[@"idx"] integerValue] : [GrowingNodeItemComponent indexNotDefine]);
    NSInteger finalKeyIndex = [GrowingNodeItemComponent indexNotDefine];
    NSString *finalXPath = nil;
    NSString *finalPatternXPath = nil;
    
    NSString *xpath = nodeDictionary[@"x"];
    
#if kHybridPatternServer == 1
    
    NSArray *patterns = nodeDictionary[@"patterns"];
#endif
    
    if (self.keyIndexInHost == [GrowingNodeItemComponent indexNotDefine])
    {
        finalKeyIndex = nodeKeyIndex;
        finalXPath = [self jointField:self.xPathInHost withField:xpath];
#if kHybridPatternServer == 1
        finalPatternXPath = [self joinXPath:self.xPathInHost hybridXPaths:patterns];
#endif
    }
    else if (nodeKeyIndex == [GrowingNodeItemComponent indexNotDefine])
    {
        finalKeyIndex = self.keyIndexInHost;
        finalXPath = [self jointField:self.xPathInHost withField:xpath];
#if kHybridPatternServer == 1
        finalPatternXPath = [self joinXPath:self.xPathInHost hybridXPaths:patterns];
#endif
    }
    else
    {
        
        finalKeyIndex = nodeKeyIndex;
        NSString *replacedXPath = [self.xPathInHost
                                   stringByReplacingOccurrencesOfString:@"[-]"
                                   withString:[NSString stringWithFormat:@"[%ld]", (long)self.keyIndexInHost]];
        finalXPath = [self jointField:replacedXPath withField:xpath];
#if kHybridPatternServer == 1
        finalPatternXPath = [self joinXPath:replacedXPath hybridXPaths:patterns];
#endif
    }
    
    NSString * nodeHyperlink = nodeDictionary[@"h"];
    NSString * nodeType = nodeDictionary[@"nodeType"];
    NSString * nodeAttributesInfo = nodeDictionary[@"obj"];
    NSValue *value = nil;
    
    if ([self.webView respondsToSelector:@selector(safeAreaInsets)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
        value = [NSValue valueWithUIEdgeInsets:self.webView.safeAreaInsets];
#pragma clang diagnostic pop
    }
    return [[GrowingDullNode alloc] initWithName:nodeName
                                      andContent:nodeContent
                              andUserInteraction:YES
                                        andFrame:frame
                                     andKeyIndex:finalKeyIndex
                                        andXPath:finalXPath
                                 andPatternXPath:finalPatternXPath
                                    andHyperlink:nodeHyperlink
                                     andNodeType:nodeType
                            andNodAttributesInfo:nodeAttributesInfo
                          andSafeAreaInsetsValue:value
                        isHybridTrackingEditText:isHybridTrackingEditText];
}

#pragma mark - 显示已圈选元素

- (void)setShouldDisplayTaggedViews:(BOOL)shouldDisplayTaggedViews
{
    _shouldDisplayTaggedViews = shouldDisplayTaggedViews;
    [self executeJavascriptMethod:@"_vds_hybrid.setShowCircledTags"
                    andParameters:@[(shouldDisplayTaggedViews ? @"true" : @"false")]
                     withCallback:nil];
}

- (void)setCircledTags:(NSArray<GrowingTagItem *> *)tags onFinish:(void(^)())onFinish
{
    NSMutableArray<NSDictionary *> * tagsDicts = [[NSMutableArray alloc] initWithCapacity:tags.count];
    for (GrowingTagItem * tag in tags)
    {
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        dict[@"eventType"] = (tag.isPageTag ? @"page" : @"elem");
        if (tag.tagId.length > 0)
        {
            dict[@"id"] = tag.tagId;
        }
        if (tag.name.length > 0)
        {
            dict[@"name"] = tag.name;
        }
        NSMutableDictionary * filter = [[NSMutableDictionary alloc] init];
        [filter addEntriesFromDictionary:[tag toDict]];
        if (filter[@"path"])
        {
            filter[@"path"] = [self stringByAddingLocalDir:filter[@"path"]];
        }
        if (filter[@"query"])
        {
            filter[@"query"] = [self stringByAddingLocalDir:filter[@"query"]];
        }
        if (filter[@"href"])
        {
            filter[@"href"] = [self stringByAddingLocalDir:filter[@"href"]];
        }
        dict[@"filter"] = filter;
        if (tag.originElement != nil)
        {
            NSMutableDictionary * attrs = [[NSMutableDictionary alloc] init];
            [filter addEntriesFromDictionary:[tag.originElement toDict]];
            if (attrs[@"path"])
            {
                attrs[@"path"] = [self stringByAddingLocalDir:filter[@"path"]];
            }
            if (attrs[@"query"])
            {
                attrs[@"query"] = [self stringByAddingLocalDir:filter[@"query"]];
            }
            if (attrs[@"href"])
            {
                attrs[@"href"] = [self stringByAddingLocalDir:filter[@"href"]];
            }
            dict[@"attrs"] = attrs;
        }
        [tagsDicts addObject:dict];
    }

    __weak GrowingJavascriptCore * wself = self;

    void (^executionBlock)() = ^void() {
        GrowingJavascriptCore * sself = wself;
        if (sself == nil)
        {
            return;
        }
        NSString * jsonString = [tagsDicts growingHelper_jsonString];
        NSString * javascriptCall = [NSString stringWithFormat:@"_vds_hybrid.setTags(%@)", jsonString];
        [sself executeJavascript:javascriptCall onFinish:onFinish];
    };
    
    if (!self.isCircleOnlyJavascriptContentLoaded && [GrowingInstance circleType] == GrowingCircleTypeWeb)
    {
        [self executeJavascript:[self hybridJSSDKCircleScriptWeb]
                       onFinish:^() {
                           GrowingJavascriptCore * sself = wself;
                           if (sself == nil)
                           {
                               return;
                           }
                           sself.isCircleOnlyJavascriptContentLoaded = YES;
                           executionBlock();
                       }];
    }else if(!self.isCircleOnlyJavascriptContentLoaded && [GrowingInstance circleType] == GrowingCircleTypeDragView){
        [self executeJavascript:[self hybridJSSDKCircleScript]
                       onFinish:^() {
                           GrowingJavascriptCore * sself = wself;
                           if (sself == nil)
                           {
                               return;
                           }
                           sself.isCircleOnlyJavascriptContentLoaded = YES;
                           executionBlock();
                       }];
    }

    executionBlock();
    
}
@end
