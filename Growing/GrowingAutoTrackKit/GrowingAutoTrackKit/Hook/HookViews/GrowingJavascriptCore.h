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
#import "GrowingNode.h"
#import <objc/message.h>

#define FIELD_SEPARATOR @"::"

#define Growing_WKWebViewClassNameUTF8 "WKWebView"

typedef void (^JavascriptCallbackType)(NSDictionary * callbackData);
extern NSString * WKScriptMessagePredefinedName;
extern NSString * webCircleHybridEvent;
extern NSString * onDOMChanged;
@protocol WebScoketDelegate <NSObject>
@optional
-(void)didRecieveWkWebivewMesage:(WKScriptMessage *)scriptMessage andWebview:(WKWebView *)wkWeb API_AVAILABLE(ios(8.0));
-(void)onDomChangeWkWebivew API_AVAILABLE(ios(8.0));
@end
@interface GrowingJavascriptCore : NSObject<GrowingNodeAsyncNativeHandler>
+ (BOOL)enableTryCatchBlock;

+ (NSString *)nativeInfo;

+ (void)allWebViewExecuteJavascriptMethod:(NSString*)methodName
                            andParameters:(NSArray*)methodParameters;

+ (void)startWebViewCircle;

+ (Class)WKWebViewClass;
+ (BOOL)isWKWebView:(UIView *)wkWebView;
+ (NSString *)jointField:(NSString *)fieldA withField:(NSString *)fieldB;
+ (BOOL)parseJointField:(NSString *)jointField toFieldA:(NSMutableString *)fieldA toFieldB:(NSMutableString *)fieldB;

@property (nonatomic, weak, readonly) UIView * wkWebView; 
@property (nonatomic, weak, readonly) UIView * webView;

@property (nonatomic, weak, readonly) UIViewController * hostViewController;
@property (nonatomic, copy, readonly) NSString * xPathInHost;
@property (nonatomic, assign, readonly) NSInteger keyIndexInHost;
@property (nonatomic, retain, readonly) NSDictionary * pageData;
@property (nonatomic, retain) id<WebScoketDelegate>  webScoketDelegate;
@property (nonatomic, assign) CGPoint lastPoint;

@property (nonatomic, assign, getter=isResponsive) BOOL responsive; 
@property (nonatomic, assign) BOOL shouldDisplayTaggedViews;


- (instancetype)initWithWKWebView:(UIView *)wkWebView;

- (void)refreshContext;

- (void)onPageLoaded;

- (void)executeBuiltInJavascript;
- (void)executeJavascript:(NSString *)javascript;
- (void)executeJavascriptMethod:(NSString *)methodName
                  andParameters:(NSArray *)methodParameters
                   withCallback:(JavascriptCallbackType)javascriptCallback;

- (BOOL)handleWKWebViewCallback:(id)scriptMessage; 

- (NSString *)stringByRemovingLocalDir:(NSString *)string;
@end

#define CALL_INSTANCE_METHOD_RETURNID(CLASS, SELF, SELECTOR)                    \
    id returnId = nil;                                                          \
    if (CLASS != nil)                                                           \
    {                                                                           \
        typedef id (*method_type)(id, SEL);                                     \
        IMP methodInstance = [CLASS instanceMethodForSelector:SELECTOR];        \
        returnId = ((method_type)methodInstance)(SELF, SELECTOR);               \
    }                                                                           \

#define CALL_INSTANCE_METHOD_RETURNVOID_ID_ID(CLASS, SELF, SELECTOR, ID1, ID2)  \
    if (CLASS != nil)                                                           \
    {                                                                           \
        typedef void (*method_type)(id, SEL, id, id);                           \
        IMP methodInstance = [CLASS instanceMethodForSelector:SELECTOR];        \
        ((method_type)methodInstance)(SELF, SELECTOR, ID1, ID2);                \
    }                                                                           \

#define CALL_INSTANCE_METHOD_RETURNVOID_ID(CLASS, SELF, SELECTOR, ID)           \
    if (CLASS != nil)                                                           \
    {                                                                           \
        typedef void (*method_type)(id, SEL, id);                               \
        IMP methodInstance = [CLASS instanceMethodForSelector:SELECTOR];        \
        ((method_type)methodInstance)(SELF, SELECTOR, ID);                      \
    }                                                                           \
