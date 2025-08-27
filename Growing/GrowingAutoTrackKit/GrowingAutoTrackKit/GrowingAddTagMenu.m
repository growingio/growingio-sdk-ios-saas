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


#import "GrowingAddTagMenu.h"
#import "GrowingMenuView.h"
#import "GrowingAlertMenu.h"
#import "UIView+GrowingHelperLayout.h"
#import "GrowingLoginModel.h"
#import "GrowingInstance.h"
#import "GrowingDeviceInfo.h"
#import "UIImage+GrowingHelper.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingWebSocket.h"
#import "GrowingDeviceInfo.h"
#import "GrowingJavascriptCore.h"
#import "NSString+GrowingHelper.h"

@interface GrowingSelectViewMenuItem ()
@property (nonatomic, retain) NSMutableArray<GrowingSelectViewMenuItem*> *childItems;
@property (nonatomic, retain) GrowingElement *growingElement;
@end

@implementation GrowingSelectViewMenuItem

- (instancetype)initWithElement:(GrowingElement *)element
{
    if (!element)
    {
        return nil;
    }
    self = [super init];
    if (self)
    {
        self.growingElement = element;
        _childItems = [[NSMutableArray alloc] init];
        self.visiableIndex = [GrowingNodeItemComponent indexNotDefine];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithElement:nil];
}

- (void)addChildItem:(GrowingSelectViewMenuItem *)childItem
{
    [self.childItems addObject:childItem];
}

- (NSArray<GrowingSelectViewMenuItem*>*)childMenuItems
{
    return self.childItems;
}

- (void)sortChildItemsAccordingToFontSize
{
    [self.childItems sortWithOptions:NSSortStable
                     usingComparator:^NSComparisonResult(GrowingSelectViewMenuItem * _Nonnull obj1,
                                                         GrowingSelectViewMenuItem * _Nonnull obj2) {
                         CGFloat fs1 = obj1.fontSize;
                         CGFloat fs2 = obj2.fontSize;
                         if (fs1 == fs2)
                         {
                             return NSOrderedSame;
                         }
                         else if (fs1 > fs2)
                         {
                             return NSOrderedAscending;
                         }
                         else
                         {
                             return NSOrderedDescending;
                         }
                     }];
}

@end

@interface _GrowingLocalCircleSelectView : GrowingMenuPageView <UITextFieldDelegate, WKNavigationDelegate>

@property (nonatomic, retain) WKWebView * theOnlyWebview;
@property (nonatomic, retain) NSDictionary * dataDict;

@end

@implementation _GrowingLocalCircleSelectView

- (instancetype)initWithType:(GrowingMenuShowType)showType
{
    self = [super initWithType:GrowingMenuShowTypePresent];
    if (self)
    {
        self.theOnlyWebview = [GrowingAddTagMenu sharedWebViewSingleton];
        self.theOnlyWebview.navigationDelegate = self;
        super.navigationBarHidden = YES;
        super.alwaysBounceVertical = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self inflatViews];
}

- (void)inflatViews
{
    super.preferredContentHeight = [UIScreen mainScreen].bounds.size.height;
    [self.view growAddSubviewInstance:self.theOnlyWebview block:^(MASG3ConstraintMaker *make, id obj) {
        make.top.offset(0);
        make.bottom.offset(0);
        make.left.offset(0);
        make.right.offset(0);
    }];
    
    
    NSString *tagURL = kGrowingAddTagPage;
    [self.theOnlyWebview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:tagURL]
                                                      cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                  timeoutInterval:10]];
    
    
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([navigationAction.request.URL.absoluteString isEqualToString:@"growing.internal://close-web-view"]) {
        [self hide];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSError *JSONError = nil;
    if (self.dataDict.count == 0)
    {
        [self reportError:@"数据为空"];
        return;
    }
    
    NSString * dataDictString = [self.dataDict growingHelper_jsonString];
    if (dataDictString.length == 0)
    {
        [self reportError:@"JSON 转换失败"];
        return;
    }
    
    if (dataDictString.length == 0 || JSONError != nil)
    {
        [self reportError:[JSONError localizedDescription]];
        return;
    }
    NSString * javascript = [NSString stringWithFormat:@"_setGrowingIOHybridCircleData(%@);", dataDictString];
    if ([GrowingJavascriptCore enableTryCatchBlock])
    {
        javascript = [NSString stringWithFormat:@"try { %@ } catch (e) { }", javascript];
    }
    [webView evaluateJavaScript:javascript completionHandler:^(id _Nullable object, NSError * _Nullable error) {
        webView;
    }];

    [GrowingWebSocket retrieveAllElementsAsync:^(NSString * dictString) {
        if (dictString.length > 0)
        {
            NSString * javascript = [NSString stringWithFormat:@"_setGrowingIOFullHybridCircleData(%@);", dictString];
            if ([GrowingJavascriptCore enableTryCatchBlock])
            {
                javascript = [NSString stringWithFormat:@"try { %@ } catch (e) { }", javascript];
            }
            [webView evaluateJavaScript:javascript completionHandler:^(id _Nullable object, NSError * _Nullable error) {
                webView;
            }];
        }
    }];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self handleError:error];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self handleError:error];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    [self reportError:@"（WKWebView）进程崩溃"];
}

- (void)handleError:(NSError *)error
{
    if (error != nil)
    {
        if (error.code != NSURLErrorCancelled)
        {
            [self reportError:[error localizedDescription]];
        }
        
    }
    else
    {
        [self reportError:@"未知错误（WKWebView）"];
    }
}

- (void)reportError:(NSString *)errorString
{
    if (errorString.length == 0)
    {
        errorString = @"未知错误";
    }
    @weakify(self);
    [GrowingAlertMenu alertWithTitle:@"错误"
                                text:errorString
                             buttons:@[[GrowingMenuButton buttonWithTitle:@"关闭"
                                                                    block:^{
                                                                        @strongify(self);
                                                                        [self hide];
                                                                    }]]];
}

- (void)hide
{
    [self.theOnlyWebview removeFromSuperview];
    self.theOnlyWebview.navigationDelegate = nil;
    self.theOnlyWebview = nil;
    [super hide];
}

- (void)dealloc
{
    [self.theOnlyWebview removeFromSuperview];
    self.theOnlyWebview.navigationDelegate = nil;
    self.theOnlyWebview = nil;
}

@end


@implementation GrowingAddTagMenu

+ (void)showFirstOfAllViewMenuItems:(NSArray<GrowingSelectViewMenuItem *> *)allItems
                     andWindowImage:(UIImage *)windowImage
{
    
    for (GrowingSelectViewMenuItem * item in allItems)
    {
        [item sortChildItemsAccordingToFontSize];
    }

    
    

    NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] init];
    CGFloat scale = [GrowingWebSocket impressScale];

    dataDict[@"userId"] = [GrowingLoginModel sdkInstance].userId;
    dataDict[@"sdkVersion"] = [Growing sdkVersion];
    dataDict[@"projectId"] = [GrowingInstance sharedInstance].accountID;
    dataDict[@"accessToken"] = [GrowingLoginModel sdkInstance].token;
    dataDict[@"appVersion"] = [GrowingDeviceInfo currentDeviceInfo].appShortVersion;
    dataDict[@"platform"] = @"iOS";
    NSMutableArray * pageDictArray = [[NSMutableArray alloc] init];
    dataDict[@"pages"] = pageDictArray;

    NSMutableArray * mutableAllItems = [NSMutableArray arrayWithArray:allItems];
    NSString * screenSnapshotBinaryString = (windowImage ? [windowImage growingHelper_Base64JPEG:0.8] : @"MQ==");
    while (mutableAllItems.count > 0)
    {
        GrowingSelectViewMenuItem * lastObject = mutableAllItems.lastObject;
        NSString * d = (lastObject.isH5Page ? lastObject.pageDomainH5 : lastObject.growingElement.domain);
        NSString * p = lastObject.growingElement.page;
        NSString * pg = lastObject.growingElement.pageGroup;
        NSString * q = (lastObject.growingElement.query ?: lastObject.pageQuery);
        NSString * v = lastObject.pageTitle;
        NSMutableDictionary * pageDict = [[NSMutableDictionary alloc] init];
        pageDict[@"domain"] = d;
        pageDict[@"page"] = p;
        pageDict[@"pg"] = pg;
        pageDict[@"query"] = (q.length == 0 ? nil : q);
        pageDict[@"title"] = v;
        if (lastObject.isPage || lastObject.isH5Page)
        {
            NSString * snapshotBinaryString = (lastObject.snapshot ? [lastObject.snapshot growingHelper_Base64JPEG:0.8] : @"MQ==");
            pageDict[@"snapshot"] = [@"data:image/jpeg;base64," stringByAppendingString:snapshotBinaryString];
            [mutableAllItems removeLastObject];
        }
        else
        {
            pageDict[@"snapshot"] = [@"data:image/jpeg;base64," stringByAppendingString:screenSnapshotBinaryString];
            NSMutableArray * eventDictArray = [[NSMutableArray alloc] init];
            pageDict[@"e"] = eventDictArray;
            for (NSInteger i = mutableAllItems.count - 1; i >= 0; i--)
            {
                
                {
                    GrowingSelectViewMenuItem * item = mutableAllItems[i];
                    GrowingElement * e = item.growingElement;
                    if ([e.domain isEqualToString:d] && (e.page == p || [e.page isEqualToString:p]))
                    {
                        ; 
                    }
                    else
                    {
                        continue; 
                    }
                }
                NSMutableArray<GrowingSelectViewMenuItem *> * itemList = [NSMutableArray arrayWithObject:mutableAllItems[i]]; 
                [itemList addObjectsFromArray:[mutableAllItems[i] childMenuItems]];
                for (GrowingSelectViewMenuItem * item in itemList)
                {
                    GrowingElement * e = item.growingElement;
                    NSMutableDictionary * eventDict = [[NSMutableDictionary alloc] init];
                    eventDict[@"xpath"] = e.xpath;
                    eventDict[@"index"] = (e.index >= 0 ? @(e.index) : nil);
                    eventDict[@"content"] = [e.content.growingHelper_encryptString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                    eventDict[@"isContentEncoded"] = [NSNumber numberWithBool:YES];
                    eventDict[@"isTabBar"] = @(item.isIgnorePage); 
                    eventDict[@"isTrackingEditText"] = @(item.isTextInput);
                    eventDict[@"href"] = e.href;
                    eventDict[@"left"] = [NSNumber numberWithInt:(int)(item.frame.origin.x * scale)];
                    eventDict[@"top"] = [NSNumber numberWithInt:(int)(item.frame.origin.y * scale)];
                    eventDict[@"width"] = [NSNumber numberWithInt:(int)(item.frame.size.width * scale)];
                    eventDict[@"height"] = [NSNumber numberWithInt:(int)(item.frame.size.height * scale)];
                    eventDict[@"nodeType"] = item.name;
                    eventDict[@"isContainer"] = @(item.isContainer);
                    eventDict[@"parentXPath"] = item.parentXPath; 
                    eventDict[@"patternXPath"] = e.patternXPath;
                    NSString * elementSnapshotBinaryString = (item.snapshot ? [item.snapshot growingHelper_Base64JPEG:0.8] : @"MQ==");
                    eventDict[@"snapshot"] = [@"data:image/jpeg;base64," stringByAppendingString:elementSnapshotBinaryString];
                    [eventDictArray addObject:eventDict];
                }
                [mutableAllItems removeObjectAtIndex:i];
            }
        }
        [pageDictArray addObject:pageDict];
    }

    _GrowingLocalCircleSelectView *trueView = [[_GrowingLocalCircleSelectView alloc] initWithType:GrowingMenuShowTypePresent];
    trueView.dataDict = dataDict;

    [trueView show];
}

static WKWebView * webViewSingleton = nil;

+ (WKWebView *)sharedWebViewSingleton
{
    if (webViewSingleton == nil)
    {
        webViewSingleton = [[WKWebView alloc] init];
        webViewSingleton.growingAttributesDonotTrack = YES;
        
        NSString *tagURL = kGrowingAddTagPage;
        [webViewSingleton loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:tagURL]
                                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                   timeoutInterval:10]];
    }
    return webViewSingleton;
}

@end
