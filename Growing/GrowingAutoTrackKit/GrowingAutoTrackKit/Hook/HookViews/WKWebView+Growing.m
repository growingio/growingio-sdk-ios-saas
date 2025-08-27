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


#import "WKWebView+Growing.h"
#import "WKWebView+GrowingNode.h"
#import "FoDefineProperty.h"
#import "FoSwizzling.h"
#import "FoDelegateSwizzling.h"
#import "GrowingAspect.h"
#import "FoObjectSELObserver.h"
#import "FoAspectBody.h"
#import "GrowingInstance.h"
#import "GrowingGlobal.h"
#import "UIView+GrowingNode.h"
#import <GrowingAutoTrackKit/GrowingAutoTrackKit.h>
#import "WKWebViewHybridJS.h"

@interface GrowingWKWebViewDefaultNavigationDelegate : NSObject<WKNavigationDelegate>

@end

@implementation GrowingWKWebViewDefaultNavigationDelegate

@end


@interface WKPrivateScriptMessageHandler : NSObject<WKScriptMessageHandler>

@end

@implementation WKPrivateScriptMessageHandler

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)userContentController:(id)userContentController didReceiveScriptMessage:(id)message
{
    CALL_INSTANCE_METHOD_RETURNID(NSClassFromString(@"WKScriptMessage"), message, @selector(webView));
    UIView  * wkWebView = returnId;
    [[[self class] wkWebView_growingHook_JavascriptCore:wkWebView] handleWKWebViewCallback:message];
}


+ (GrowingJavascriptCore *)wkWebView_growingHook_JavascriptCore:(UIView * )wkWebView
{
    if ([GrowingJavascriptCore isWKWebView:wkWebView])
    {
        
        CALL_INSTANCE_METHOD_RETURNID([GrowingJavascriptCore WKWebViewClass], wkWebView,
                                      @selector(growingHook_JavascriptCore));
        GrowingJavascriptCore * javascriptCore = returnId;
        return javascriptCore;
        
    }
    return nil;
}

@end

FoPropertyDefine(UIView, GrowingWKWebViewDefaultNavigationDelegate *, growingHook_defaultWKNavDelegate, setGrowingHook_defaultWKNavDelegate)
FoPropertyDefine(UIView, GrowingJavascriptCore *, growingHook_JavascriptCore, setGrowingHook_JavascriptCore)
FoPropertyDefine(UIView, WKPrivateScriptMessageHandler *, growingHook_scriptMessageHandler, setGrowingHook_scriptMessageHandler)

typedef void(^DecisionHandler)(WKNavigationActionPolicy);
typedef void(^CompletionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential *__nullable);

FoSwizzleTempletVoid(@selector(webView:decidePolicyForNavigationAction:decisionHandler:),
                     void,selhookWebViewDecidePolicyForNavigationActionDecisionHandler,
                     WKWebView *, WKNavigationAction *, DecisionHandler)
FoSwizzleTempletVoid(@selector(webView:decidePolicyForNavigationResponse:decisionHandler:),
                     void,selhookWebViewDecidePolicyForNavigationResponseDecisionHandler,
                     WKWebView *, WKNavigationResponse *, DecisionHandler)
FoSwizzleTempletVoid(@selector(webView:didFinishNavigation:),
                     void,selhookWebViewDidFinishNavigation,
                     WKWebView *, WKNavigation *)
FoSwizzleTempletVoid(@selector(webView:didReceiveAuthenticationChallenge:completionHandler:),
                     void,selhookWebViewDidReceiveAuthenticationChallengeCompletionHandler,
                     WKWebView *, NSURLAuthenticationChallenge *, CompletionHandler)

FoHookWKWebViewDelegate(WKWebView, @selector(setNavigationDelegate:), void, NSObject<WKNavigationDelegate>*, navigationDelegate)

    GrowingAspectBefore(navigationDelegate,
                        selhookWebViewDecidePolicyForNavigationActionDecisionHandler,
                        void, @selector(webView:decidePolicyForNavigationAction:decisionHandler:),
                        (WKWebView *)webView, (WKNavigation *)navigation, (DecisionHandler) decisionHandler, {
                            if (wself == webView && originInstance == webView.navigationDelegate) {
                                SEL originSEL = @selector(webView:decidePolicyForNavigationAction:decisionHandler:);
                                if (![originInstance restoreOriginResultOfRespondsToSelector:originSEL]){
                                    if (decisionHandler != nil) {
                                        decisionHandler(WKNavigationActionPolicyAllow);
                                    }
                                    if (p_shouldEarlyReturn != nil) {
                                        *p_shouldEarlyReturn = YES;
                                    }
                                }
                        }
                        }),

    GrowingAspectBefore(navigationDelegate,
                        selhookWebViewDecidePolicyForNavigationResponseDecisionHandler,
                        void, @selector(webView:decidePolicyForNavigationResponse:decisionHandler:), (WKWebView *)webView, (WKNavigationResponse *)navigationResponse, (DecisionHandler) decisionHandler, {
                            if (wself == webView && originInstance == webView.navigationDelegate)
                            {
                                if (p_shouldEarlyReturn != nil) {
                                    *p_shouldEarlyReturn = YES;
                                }
                                SEL originSEL = @selector(webView:decidePolicyForNavigationResponse:decisionHandler:);

                                if (![originInstance restoreOriginResultOfRespondsToSelector:originSEL]){
                                    if (decisionHandler != nil) {
                                        decisionHandler(WKNavigationActionPolicyAllow);
                                    }
                                } else {
                                    __block BOOL dynamicSwizzlSuperImp = NO;
                                    DecisionHandler hookDecisionHandler = ^(WKNavigationActionPolicy policy) {
                                        if (policy == WKNavigationResponsePolicyAllow)
                                        {
                                            GrowingJavascriptCore * javascriptCore = webView.growingHook_JavascriptCore;
                                            javascriptCore.responsive = NO;
                                        }
                                        if (!dynamicSwizzlSuperImp && decisionHandler != nil)
                                        {
                                            decisionHandler(policy);
                                        }
                                    };
                                    void (*tempImp)(id,SEL,WKWebView *webView, WKNavigationResponse *navigationResponse, DecisionHandler handler) = nil;
                                    if([GrowingInstance aspectMode] == GrowingAspectModeSubClass) {
                                        
                                        Class superClass = class_getSuperclass(object_getClass(originInstance));
                                        
                                        Method method = class_getInstanceMethod(superClass, @selector(webView:decidePolicyForNavigationResponse:decisionHandler:));
                                        if(method) {
                                            tempImp = (void*)method_getImplementation(method);
                                        } else {
                                            tempImp = (void*)class_getMethodImplementation(superClass, originSEL);
                                        }
                                        
                                        if (tempImp) {
                                            tempImp(originInstance, originSEL, wself, navigationResponse, hookDecisionHandler);
                                        }
                                    } else {
                                        foAspectIMPItem *impItem = objc_getAssociatedObject([originInstance class], @selector(foAspectIMPItem_webView:decidePolicyForNavigationResponse:decisionHandler:));
                                        if(impItem.oldIMP) {
                                            tempImp = (void*)impItem.oldIMP;
                                        } else if (class_respondsToSelector([originInstance superclass], originSEL)){
                                            tempImp = (void*)class_getMethodImplementation([originInstance superclass], originSEL);
                                            if (tempImp && decisionHandler != nil) {
                                                dynamicSwizzlSuperImp = YES;
                                                decisionHandler(WKNavigationActionPolicyAllow);
                                            }
                                        }
                                        if (tempImp) {
                                            tempImp(originInstance, originSEL, wself, navigationResponse, hookDecisionHandler);
                                        }
                                    }
                                }
                            }
                        }),

    GrowingAspectBefore(navigationDelegate,
                        selhookWebViewDidFinishNavigation,
                        void, @selector(webView:didFinishNavigation:),
                        (WKWebView *)webView, (WKNavigation *)navigation, {
                            if (wself == webView && originInstance == webView.navigationDelegate)
                            {
                                [webView.growingHook_JavascriptCore onPageLoaded];
                            }
                        }),

    GrowingAspectBefore(navigationDelegate,
                        selhookWebViewDidReceiveAuthenticationChallengeCompletionHandler,
                        void, @selector(webView:didReceiveAuthenticationChallenge:completionHandler:),
                        (WKWebView *)webView, (NSURLAuthenticationChallenge *)challenge,(CompletionHandler) handler, {
                            if (wself == webView && originInstance == webView.navigationDelegate)
                            {
                                SEL originSEL = @selector(webView:didReceiveAuthenticationChallenge:completionHandler:);
                                if (![originInstance restoreOriginResultOfRespondsToSelector:originSEL]){
                                    if (handler != nil)
                                    {
                                        handler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
                                    }
                                    if (p_shouldEarlyReturn != nil) {
                                        *p_shouldEarlyReturn = YES;
                                    }
                                }
                            }
                        }),
FoHookDelegateEnd



@implementation UIView (FakeWKWebView)

@end

static BOOL growingCheckWebviewIsInternalUsage(UIView *webView) {
    if (NSClassFromString(@"GrowingTouchPopupManager") &&
        [NSStringFromClass(webView.class) isEqualToString:@"GrowingTouchPopupWebView"]) {
        return YES;
    }
    return NO;
}

static void growing_webView_addScriptMessageHandler(WKUserContentController *contentController, id <WKScriptMessageHandler>scriptMessageHandler) {
    if (!contentController || ![contentController isKindOfClass:[WKUserContentController class]] || !scriptMessageHandler) {
        return;
    }
    
    NSArray *array = @[WKScriptMessagePredefinedName, webCircleHybridEvent, onDOMChanged];
    for (NSString *name in array) {
        [contentController removeScriptMessageHandlerForName:name];
        [contentController addScriptMessageHandler:scriptMessageHandler name:name];
    }
}

static void growing_webView_addUserScripts(WKUserContentController *contentController) {
    if (!contentController || ![contentController isKindOfClass:[WKUserContentController class]]) {
        return;
    }
    
    @try {
        NSArray<WKUserScript *> *userScripts = contentController.userScripts;
        __block BOOL isContainJavaScriptBridge = NO;
        [userScripts enumerateObjectsUsingBlock:^(WKUserScript *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj.source containsString:@"_vds_ios"]
                || [obj.source containsString:@"_vds_hybrid_config"]
                || [obj.source containsString:@"gio_hybrid.min.js"]) {
                isContainJavaScriptBridge = YES;
                *stop = YES;
            }
        }];

        if (!isContainJavaScriptBridge) {
            [contentController addUserScript:[[WKUserScript alloc] initWithSource:@"window._vds_ios = true;"
                                                                    injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                                 forMainFrameOnly:NO]];
            
            [contentController addUserScript:[[WKUserScript alloc] initWithSource:[WKWebViewHybridJS configHybridScript]
                                                                    injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                                 forMainFrameOnly:NO]];
            
            [contentController addUserScript:[[WKUserScript alloc] initWithSource:[WKWebViewHybridJS hybridJS]
                                                                    injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                                 forMainFrameOnly:NO]];
        }
    } @catch (NSException *exception) {

    }
}

static void growing_webView_addBridge(WKWebView *webView) {
    if (![webView isKindOfClass:[WKWebView class]]) {
        return;
    }
    
    if (growingCheckWebviewIsInternalUsage(webView)) {
        return;
    }
    
    if (webView.growingAttributesDonotTrack || (g_allWebViewsDisabled && !webView.growingAttributesIsTracked)) {
        return;
    }
    
    WKUserContentController *contentController = webView.configuration.userContentController;
    WKPrivateScriptMessageHandler *scriptMessageHandler = webView.growingHook_scriptMessageHandler;
    growing_webView_addScriptMessageHandler(contentController, scriptMessageHandler);
    growing_webView_addUserScripts(contentController);
}

FoHookInstancePlus(Growing_WKWebViewClassNameUTF8, UIView *, @selector(initWithFrame:configuration:),
                   id , CGRect frame, id  configuration)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loadAllWKWebViewMethod();
    });
    
    UIView * wkWebView = FoHookOrgin(frame, configuration);
    
    if (growingCheckWebviewIsInternalUsage(wkWebView)) {
        return wkWebView;
    }
    
    wkWebView.growingHook_defaultWKNavDelegate = [[GrowingWKWebViewDefaultNavigationDelegate alloc] init];
    
    CALL_INSTANCE_METHOD_RETURNVOID_ID([GrowingJavascriptCore WKWebViewClass], wkWebView,
                                       @selector(setNavigationDelegate:),
                                       nil);

    
    wkWebView.growingHook_JavascriptCore = [[GrowingJavascriptCore alloc] initWithWKWebView:wkWebView];

    
    wkWebView.growingHook_scriptMessageHandler = WKPrivateScriptMessageHandler.sharedInstance;

    return wkWebView;
}
FoHookEnd

FoHookInstance(WKWebView, @selector(loadRequest:), WKNavigation *, NSURLRequest *request)
{
    growing_webView_addBridge(self);
    return FoHookOrgin(request);
}
FoHookEnd

FoHookInstance(WKWebView, @selector(loadHTMLString:baseURL:), WKNavigation *, NSString *string, NSURL *baseURL)
{
    growing_webView_addBridge(self);
    return FoHookOrgin(string, baseURL);
}
FoHookEnd

FoHookInstance(WKWebView, @selector(loadFileURL:allowingReadAccessToURL:), WKNavigation *, NSURL *URL, NSURL *readAccessURL)
{
    growing_webView_addBridge(self);
    return FoHookOrgin(URL, readAccessURL);
}
FoHookEnd

FoHookInstance(WKWebView, @selector(loadData:MIMEType:characterEncodingName:baseURL:), WKNavigation *, NSData *data, NSString *MIMEType, NSString *characterEncodingName, NSURL *baseURL)
{
    growing_webView_addBridge(self);
    return FoHookOrgin(data, MIMEType, characterEncodingName, baseURL);
}
FoHookEnd
