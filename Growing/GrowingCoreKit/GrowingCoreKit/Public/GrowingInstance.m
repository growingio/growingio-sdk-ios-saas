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
#import <UIKit/UIKit.h>
#import "GrowingInstance.h"
#import "GrowingMediator.h"
#import "GrowingDeviceInfo.h"
#import "NSString+GrowingHelper.h"
#import "NSData+GrowingHelper.h"
#import "GrowingGlobal.h"
#import "GrowingCustomField.h"
#import "GrowingNetworkConfig.h"
#import "GrowingMobileDebugger.h"
#import "GrowingDeepLinkModel.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingEBApplicationEvent.h"
#import "NSURL+GrowingHelper.h"
#import "GrowingMediator+GrowingDeepLink.h"
#import "GrowingDispatchManager.h"
#import "GrowingActivateEvent.h"
#import "GrowingCocoaLumberjack.h"
#import "GrowingAsaFetcher.h"
#import "GrowingNetworkPreflight.h"

static BOOL checkUUIDwithSampling(NSUUID *uuid, CGFloat sampling)
{
    
    if (!uuid)
    {
        return YES;
    }

    if (sampling <= 0)
    {
        return NO;
    }
    if (sampling >= 0.9999)
    {
        return YES;
    }

    unsigned char md5[16];
    [[[uuid UUIDString] growingHelper_uft8Data] growingHelper_md5value:md5];

    unsigned long bar = 100000;
    unsigned long rightValue = (sampling + 1.0f / bar) * bar;
    unsigned long value = 1;
    for (int i = 15; i >=0 ; i --)
    {
        unsigned char n = md5[i];
        value = ((value * 256) + n ) % bar;
    }
    if (value < rightValue)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@interface GrowingInstance ()<WKNavigationDelegate>

@property (nonatomic, assign) GrowingCircleType circleType;

@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, copy) NSString *userAgent;


@property (nonatomic, copy) NSString *link_id;
@property (nonatomic, copy) NSString *click_id;
@property (nonatomic, copy) NSString *tm_click;
@property (nonatomic, copy) NSString *cl;

@end


@implementation GrowingInstance

static GrowingCircleType GrowingInstanceCircleType = 0;
+ (GrowingCircleType)circleType
{
    if ([self sharedInstance])
    {
        return [[self sharedInstance] circleType];
    }
    else
    {
        return GrowingInstanceCircleType;
    }
}

+ (void)setCircleType:(GrowingCircleType)type
{
    [self setCircleType:type withParameter:nil];
}

+ (void)setCircleType:(GrowingCircleType)type withParameter:(NSString *)parameter
{
    GrowingInstanceCircleType = type;
    [[self sharedInstance] setCircleType:type withParameter:parameter];
}

static GrowingInstance *instance = nil;
+ (instancetype)sharedInstance
{
    return instance;
}

+ (void)startWithAccountId:(NSString *)accountId withSampling:(CGFloat)sampling
{
    if (!accountId.length || instance)
    {
        return;
    }
    instance = [[self alloc] initWithAccountId:accountId withSampling:sampling];

    [GrowingNetworkPreflight sendPreflight];
    [GrowingVisitEvent send];
}

- (instancetype)initWithAccountId:(NSString *)accountId withSampling:(CGFloat)sampling
{
    self = [self init];
    if (self)
    {
        _accountID = [accountId copy];
        [self updateSampling:sampling];
        
        self.circleType = [[self class] circleType];

        [self runPastedDeeplink];
    }
    return self;
}

static BOOL isGrowingDeeplink = NO;

subscribe
+ (void)didfinishLauching:(GrowingEBApplicationEvent *)event
{
    if (event.lifeType != GrowingApplicationDidFinishLaunching) {
        return;
    }

    if (event.dataDict.count == 0) {
        return;
    }

    isGrowingDeeplink = [self isGrowingDeeplink:event.dataDict[@"data"]];
}

+ (BOOL)isGrowingDeeplink:(NSDictionary *)launchOptions
{
    NSURL *url;
    NSURL *schemeUrl = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if (schemeUrl) {
        url = schemeUrl;
    } else {
        if (@available(iOS 8.0, *)) {
            NSUserActivity *act = [[launchOptions objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey] objectForKey:@"UIApplicationLaunchOptionsUserActivityKey"];
            url = act.webpageURL;
        }
    }

    if (![[GrowingMediator sharedInstance] isGrowingIOUrl:url]) {
        return NO;
    }

    
    BOOL isShortChainUlink = [[GrowingMediator sharedInstance] isShortChainUlink:url];

    if (isShortChainUlink) {
        
        return YES;
    }

    if ([[GrowingMediator sharedInstance] isLongChainDeeplink:url]) {
        
        return YES;
    }

    return NO;
}

- (void)runPastedDeeplink {
    [GrowingAsaFetcher startFetchWithTimeOut:GrowingAsaFetcherDefaultTimeOut];
    
    [self runPastedDeeplink:^{
        if ([GrowingDeviceInfo currentDeviceInfo].isNewInstall) {
            [self _reportInstallSoucre];
        }
    }];
}

- (void)runPastedDeeplink:(void (^)(void))finishBlock
{
    if (SDKDoNotTrack()) {
        return;
    }

    if (![GrowingDeviceInfo currentDeviceInfo].isNewInstall) {
        finishBlock();
        return;
    }

    if ([GrowingDeviceInfo currentDeviceInfo].isPastedDeeplinkCallback) {
        finishBlock();
        return;
    }

    if (isGrowingDeeplink) {
        finishBlock();
        return;
    }
    
    if (!g_readClipBoardEnable) {
        finishBlock();
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDate *startDate = [NSDate date];
        NSString *pasteString = [UIPasteboard generalPasteboard].string;
        NSDictionary *callbackDict = [self convertPastedboardString:pasteString];

        if (callbackDict.count == 0) {
            finishBlock();
            return;
        }

        if (![callbackDict[@"typ"] isEqualToString:@"gads"] || ![callbackDict[@"scheme"] isEqualToString:[GrowingDeviceInfo currentDeviceInfo].urlScheme]) {
            finishBlock();
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([GrowingDeviceInfo currentDeviceInfo].isPastedDeeplinkCallback) {
                finishBlock();
                return;
            }

            self.link_id = callbackDict[@"link_id"];
            self.click_id = callbackDict[@"click_id"];
            self.tm_click = callbackDict[@"tm_click"];
            self.cl = @"defer";

            NSString *jsonStr = [self URLDecodedString:callbackDict[@"v1"][@"custom_params"]?:@""];
            NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
            NSError *cusErr = nil;
            NSDictionary *custom_params = [NSJSONSerialization JSONObjectWithData:data options:0 error:&cusErr];
            NSMutableDictionary *dictInfo = [NSMutableDictionary dictionaryWithDictionary:custom_params];
            if ([dictInfo objectForKey:@"_gio_var"]) {
                [dictInfo removeObjectForKey:@"_gio_var"];
            }

            NSError *err = nil;
            if (custom_params.count == 0) {
                
                err = [NSError errorWithDomain:@"com.growingio.deeplink" code:1 userInfo:@{@"error" : @"no custom_params"}];
            }

            [self loadUserAgentWithCompletion:^(NSString *ua) {
                
                if ([GrowingDeviceInfo currentDeviceInfo].isPastedDeeplinkCallback) {
                    return;
                }
                [self reportReengageWithCustomParams:custom_params
                                                  ua:ua
                                   renngageMechanism:@"universal_link"
                                             link_id:self.link_id
                                            click_id:self.click_id
                                            tm_click:[NSNumber numberWithLongLong:self.tm_click.longLongValue]];
                [[GrowingDeviceInfo currentDeviceInfo] pasteboardDeeplinkReported];
            }];


            NSDate *endDate = [NSDate date];
            NSTimeInterval processTime = [endDate timeIntervalSinceDate:startDate];


            if (GrowingInstance.deeplinkHandler) {
                GrowingInstance.deeplinkHandler(dictInfo, processTime, err);
            }

            if ([[UIPasteboard generalPasteboard].string isEqualToString:pasteString]) {
                [UIPasteboard generalPasteboard].string = @"";
            }

            finishBlock();
        });
    });

}


- (NSDictionary *)convertPastedboardString:(NSString *)clipboardString
{
    if (clipboardString.length > 2000 * 16) {
        return nil;
    }

    NSString *binaryList = @"";

    for (int i = 0; i < clipboardString.length; i++) {
        char a = [clipboardString characterAtIndex:i];
        NSString *charString = @"";
        if (a == (char)020014) {
            charString = @"0";
        } else {
            charString = @"1";
        }
        binaryList = [binaryList stringByAppendingString:charString];
    }

    NSInteger binaryListLength = binaryList.length;

    NSInteger SINGLE_CHAR_LENGTH = 16;

    if (binaryListLength % SINGLE_CHAR_LENGTH != 0) {
        return nil;
    }

    NSMutableArray *bs = [NSMutableArray array];

    int i = 0;
    while (i < binaryListLength) {
        [bs addObject:[binaryList substringWithRange:NSMakeRange(i, SINGLE_CHAR_LENGTH)]];
        i += SINGLE_CHAR_LENGTH;
    }

    NSString *listString = @"";

    for (int i = 0; i < bs.count; i++) {
        NSString *partString = bs[i];
        long long part = [partString longLongValue];
        int partInt = [self convertBinaryToDecimal:part];
        listString = [listString stringByAppendingString:[NSString stringWithFormat:@"%C", (unichar)partInt]];
    }
    NSDictionary *dict = listString.growingHelper_jsonObject;
    return [dict isKindOfClass:[NSDictionary class]] ? dict : nil;
}

- (int)convertBinaryToDecimal:(long long)n
{
    int decimalNumber = 0, i = 0, remainder;
    while (n!=0)
    {
        remainder = n%10;
        n /= 10;
        decimalNumber += remainder*pow(2,i);
        ++i;
    }
    return decimalNumber;
}

- (void)_reportInstallSoucre
{
    if (SDKDoNotTrack()) {
        return;
    }

    [self loadUserAgentWithCompletion:^(NSString *ua) {
        
        if (![GrowingDeviceInfo currentDeviceInfo].isNewInstall) {
            return;
        }

        NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];

        if (self.link_id.length) { queryDict[@"link_id"] = [self encodedString:self.link_id]; }
        if (self.click_id.length) { queryDict[@"click_id"] = [self encodedString:self.click_id]; }
        if (self.tm_click.length) { queryDict[@"tm_click"] = [self encodedString:self.tm_click]; }
        if (self.cl.length) { queryDict[@"cl"] = self.cl; }
        if (ua.length) { queryDict[@"ua"] = ua; }

        [GrowingActivateEvent sendEventQueryDict:queryDict];
        [[GrowingDeviceInfo currentDeviceInfo] deviceInfoReported];
    }];
}

+ (void)reportGIODeeplink:(NSURL *)linkURL {
    [[self sharedInstance] reportGIODeeplink:linkURL];
}

+ (void)reportShortChainDeeplink:(NSURL *)linkURL
{
    [[self sharedInstance] reportShortChainDeeplink:linkURL isManual:NO callback:nil];
}

static GrowingDeeplinkHandler deeplinkHandler;
+ (void)setDeeplinkHandler:(GrowingDeeplinkHandler)handler
{
    deeplinkHandler = handler;
}
+ (GrowingDeeplinkHandler)deeplinkHandler
{
    return deeplinkHandler;
}

- (NSString *)URLDecode:(NSString *)source {
    if (!source || source.length == 0) {
        
        return source;
    }

    NSString *resultString = [source stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    resultString = [resultString stringByReplacingOccurrencesOfString:@"&apos;" withString:@"\'"];
    resultString = [resultString stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    resultString = [resultString stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    resultString = [resultString stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];

    return resultString;
}

- (NSString *)encodedString:(NSString *)urlString {
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                    (CFStringRef)urlString,
                                                                                                    (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                                                                    NULL,
                                                                                                    kCFStringEncodingUTF8));
    return encodedString;
}

- (NSString *)URLDecodedString:(NSString *)urlString {
    urlString = [urlString
    stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    NSString *decodedString = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                                    (__bridge CFStringRef)urlString,
                                                                                                                    CFSTR(""),
                                                                                                                    CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return decodedString;
}

+ (BOOL)doDeeplinkByUrl:(NSURL *)url callback:(void(^)(NSDictionary *params, NSTimeInterval processTime, NSError *error))callback
{
    BOOL isShortChainUlink = [[GrowingMediator sharedInstance] isShortChainUlink:url];

    if (isShortChainUlink) {
        [GrowingDispatchManager dispatchInMainThread:^{
            [[self sharedInstance] reportShortChainDeeplink:url isManual:YES callback:callback];
        }];
    }

    return isShortChainUlink;
}

- (void)reportGIODeeplink:(NSURL *)linkURL {
    if (SDKDoNotTrack()) {
        return;
    }
    NSString *renngageMechanism;

    if ([linkURL.scheme hasPrefix:@"growing."] ) {
        renngageMechanism = @"url_scheme";
    } else {
        renngageMechanism = @"universal_link";
    }

    [self loadUserAgentWithCompletion:^(NSString *ua) {

        NSMutableDictionary *queryParams = [NSMutableDictionary dictionaryWithDictionary:linkURL.growingHelper_queryDict];

        __block NSString *cstm_params = nil ;

        [[[self URLDecode:linkURL.query] componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj hasPrefix:@"custom_params"]) {
                NSArray *pair = [obj componentsSeparatedByString:@"="];
                if (pair.count > 1) {
                    cstm_params = pair[1];
                    [queryParams removeObjectForKey:@"custom_params"];
                }
            }
        }];

        queryParams[@"rngg_mch"] = renngageMechanism;
        queryParams[@"ua"] = ua;

        NSString *jsonCustomStr = [self URLDecodedString:cstm_params];
        NSDictionary *customParams = [jsonCustomStr growingHelper_dictionaryObject];

        [GrowingReengageEvent sendEventWithQueryDict:queryParams andVariable:customParams];

    }];

    if (!GrowingInstance.deeplinkHandler) {
        return;
    }

    
    NSString *encodeQuery = linkURL.query;
    NSString *query = [self URLDecode:encodeQuery];
    NSArray *items = [query componentsSeparatedByString:@"&"];
    __block NSDictionary *info = nil;
    __block NSError *err = nil;
    [items enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj hasPrefix:@"custom_params"]) {
            NSArray *pair = [obj componentsSeparatedByString:@"="];
            if (pair.count > 1) {
                NSString *encodeJsonStr = pair[1];
                if (encodeJsonStr.length > 0) {
                    NSString *jsonStr = [self URLDecodedString:encodeJsonStr];
                    NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                    info = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
                    NSMutableDictionary *dicInfo  = [NSMutableDictionary dictionaryWithDictionary:info] ;
                    if ([dicInfo objectForKey:@"_gio_var"]) {
                        [dicInfo removeObjectForKey:@"_gio_var"];
                    }
                    if (![dicInfo objectForKey:@"+deeplink_mechanism"]) {
                        [dicInfo setObject:renngageMechanism forKey:@"+deeplink_mechanism"];
                    }
                    info = dicInfo ;
                    if (!info) {
                        GIOLogError(@"error:%@", err);
                    }
                }
            }
            *stop = YES;
        }
    }];

    if (!info && !err) {
        
        err = [NSError errorWithDomain:@"com.growingio.deeplink" code:1 userInfo:@{@"error" : @"no custom_params"}];
    }

    if (GrowingInstance.deeplinkHandler) {
        GrowingInstance.deeplinkHandler(info, 0.0, err);
    }
}

- (void)reportShortChainDeeplink:(NSURL *)linkURL isManual:(BOOL)isManual callback:(void(^)(NSDictionary *params, NSTimeInterval processTime, NSError *error))callback
{
    if (SDKDoNotTrack()) {
        return;
    }

    NSDate *startData = [NSDate date];
    NSString *renngageMechanism = @"universal_link";
    NSString *hashId = [linkURL.path componentsSeparatedByString:@"/"].lastObject;

    [self loadUserAgentWithCompletion:^(NSString * ua) {

        GrowingDeepLinkModel *deepLinkModel = [[GrowingDeepLinkModel alloc] init];

        [deepLinkModel getParamByHashId:hashId query:linkURL.query
                                     ua:ua
                                 manual:isManual
                                succeed:^(NSHTTPURLResponse *httpResponse, NSData *data) {

            NSDictionary *responseDict = [data growingHelper_dictionaryObject];
            NSNumber *statusNumber = responseDict[@"code"];
            NSString *message = responseDict[@"msg"] ? : @"";

            NSDictionary *dataDict = responseDict[@"data"];

            if (statusNumber.intValue != 200) {
                NSError *err = [NSError errorWithDomain:@"com.growingio.deeplink" code:statusNumber.integerValue userInfo:@{@"error" : message}];
                NSDate *endTime = [NSDate date];
                NSTimeInterval processTime = [endTime timeIntervalSinceDate:startData];
                if (callback) {
                    callback(nil, processTime, err);
                } else if (GrowingInstance.deeplinkHandler) {
                    GrowingInstance.deeplinkHandler(nil, processTime, err);
                }
                return;
            }

            NSString *link_id = [dataDict objectForKey:@"link_id"];
            NSString *click_id = [dataDict objectForKey:@"click_id"];
            NSNumber *tm_click = [dataDict objectForKey:@"tm_click"];
            NSDictionary *custom_params = [dataDict objectForKey:@"custom_params"];

            if (!isManual) {
                [self reportReengageWithCustomParams:custom_params
                                                  ua:ua
                                   renngageMechanism:renngageMechanism
                                             link_id:link_id
                                            click_id:click_id
                                            tm_click:tm_click];
            }

            if (!GrowingInstance.deeplinkHandler && !callback) {
                return;
            }

            
            NSMutableDictionary *dictInfo = [NSMutableDictionary dictionaryWithDictionary:custom_params];
            if ([dictInfo objectForKey:@"_gio_var"]) {
                [dictInfo removeObjectForKey:@"_gio_var"];
            }
            if (![dictInfo objectForKey:@"+deeplink_mechanism"]) {
                [dictInfo setObject:renngageMechanism forKey:@"+deeplink_mechanism"];
            }

            NSError *err = nil;
            if (custom_params.count == 0) {
                
                err = [NSError errorWithDomain:@"com.growingio.deeplink" code:1 userInfo:@{@"error" : @"no custom_params"}];
            }

            NSDate *endDate = [NSDate date];
            NSTimeInterval processTime = [endDate timeIntervalSinceDate:startData];

            if (callback) {
                callback(dictInfo, processTime, err);
            } else if (GrowingInstance.deeplinkHandler) {
                GrowingInstance.deeplinkHandler(dictInfo, processTime, err);
            }

        } fail:^(NSHTTPURLResponse *httpResponse, NSData *data, NSError *error) {

            NSDate *endTime = [NSDate date];
            NSTimeInterval processTime = [endTime timeIntervalSinceDate:startData];

            if (callback) {
                callback(nil, processTime, error);
            } else if (GrowingInstance.deeplinkHandler) {
                GrowingInstance.deeplinkHandler(nil, processTime, error);
            }
        }];

    }];
}

- (void)reportReengageWithCustomParams:(NSDictionary *)customParams
                                    ua:(NSString *)ua
                     renngageMechanism:(NSString *)renngageMechanism
                               link_id:(NSString *)link_id
                              click_id:(NSString *)click_id
                              tm_click:(NSNumber *)tm_click
{

    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    if (ua.length) { queryParams[@"ua"] = ua; }
    if (renngageMechanism.length) { queryParams[@"rngg_mch"] = renngageMechanism; }
    if (link_id.length) { queryParams[@"link_id"] = [self encodedString:link_id]; }
    if (click_id.length) { queryParams[@"click_id"] = [self encodedString:click_id]; }
    if (tm_click) { queryParams[@"tm_click"] = [self encodedString:tm_click.stringValue]; }

    [GrowingReengageEvent sendEventWithQueryDict:queryParams andVariable:customParams];
}

- (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    if (self.userAgent) {
        return completion(self.userAgent);
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        @try {
            self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
            [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                if (error || !response) {
                    GIOLogError(@"WKWebView evaluateJavaScript load UA error:%@", error);
                    completion(nil);
                } else {
                    weakSelf.userAgent = response;
                    completion(weakSelf.userAgent);
                }
                weakSelf.wkWebView = nil;
            }];
        } @catch (NSException *exception) {
            GIOLogDebug(@"loadUserAgentWithCompletion crash :%@",exception);
            completion(nil);
        }

    });
}

+ (void)updateSampling:(CGFloat)sampling
{
    [[self sharedInstance] updateSampling:sampling];
}

- (void)updateSampling:(CGFloat)sampling
{
    NSUUID *idfv = [[UIDevice currentDevice] identifierForVendor];
    g_doNotTrack = !checkUUIDwithSampling(idfv, sampling);
}

#define GrowingCircleTypeIsOpen(TYPE)   (!(oldType & TYPE) &&  (circleType & TYPE))
#define GrowingCircleTypeIsClose(TYPE)  ( (oldType & TYPE) && !(circleType & TYPE))


- (GrowingCircleType)circleType
{
    GrowingCircleType type = GrowingCircleTypeNone;
    NSNumber *isRunningNumber = [[GrowingMediator sharedInstance] performClass:@"GrowingWebSocket" action:@"isRunning" params:nil];
    if (isRunningNumber.boolValue)
    {
        type |= GrowingCircleTypeWeb;
    }
    NSNumber *listMenuIsStart = [[GrowingMediator sharedInstance] performClass:@"GrowingEventListMenu" action:@"isStart" params:nil];
    if (listMenuIsStart.boolValue)
    {
        NSNumber *listMenuIsReplay = [[GrowingMediator sharedInstance] performClass:@"GrowingEventListMenu" action:@"isReplay" params:nil];
        if (listMenuIsReplay.boolValue)
        {
            type |= GrowingCircleTypeReplay;
        }
        else
        {
            type |= GrowingCircleTypeEventList;
        }
    }
    NSNumber *hasStartCircle = [[GrowingMediator sharedInstance] performClass:@"GrowingLocalCircleWindow" action:@"hasStartCircle" params:nil];
    if (hasStartCircle.boolValue)
    {
        type |= GrowingCircleTypeDragView;
    }

    NSNumber *heatMapIsStart = [[GrowingMediator sharedInstance] performClass:@"GrowingHeatMapManager" action:@"isStart" params:nil];

    if (heatMapIsStart.boolValue)
    {
        type |= GrowingCircleTypeHeatMap;
    }

    return type;
}

- (void)setCircleType:(GrowingCircleType)circleType withParameter:(NSString *)parameter
{
    if (parameter.length == 0) {
        parameter = @"";
    }

    GrowingCircleType oldType = self.circleType;
    if (GrowingCircleTypeIsOpen(GrowingCircleTypeWeb))
    {
        [[GrowingMediator sharedInstance] performClass:@"GrowingWebSocket" action:@"runWithCircleRoomNumber:ReadyBlock:finishBlock:" params:@{@"0":parameter}];
    }
    else if (GrowingCircleTypeIsClose(GrowingCircleTypeWeb))
    {
        [[GrowingMediator sharedInstance] performClass:@"GrowingWebSocket" action:@"stop" params:nil];
    }

    if (GrowingCircleTypeIsOpen(GrowingCircleTypeHeatMap))
    {
        [[GrowingMediator sharedInstance] performClass:@"GrowingHeatMapManager" action:@"start" params:nil];
    }
    else if (GrowingCircleTypeIsClose(GrowingCircleTypeHeatMap))
    {
        [[GrowingMediator sharedInstance] performClass:@"GrowingHeatMapManager" action:@"stop" params:nil];
    }

    if (GrowingCircleTypeIsOpen(GrowingCircleTypeEventList)
        ||  GrowingCircleTypeIsOpen(GrowingCircleTypeReplay))
    {
        [[GrowingMediator sharedInstance] performClass:@"GrowingEventListMenu" action:@"startTrack" params:nil];
        if (GrowingCircleTypeIsOpen(GrowingCircleTypeReplay))
        {
            [[GrowingMediator sharedInstance] performClass:@"GrowingEventListMenu" action:@"setIsReplay:" params:@{@"0":@YES}];
        }
        else
        {
            [[GrowingMediator sharedInstance] performClass:@"GrowingEventListMenu" action:@"setIsReplay:" params:@{@"0":@NO}];
        }
    }
    else if (GrowingCircleTypeIsClose(GrowingCircleTypeEventList))
    {
        [[GrowingMediator sharedInstance] performClass:@"GrowingEventListMenu" action:@"stopTrack" params:nil];
    }

    if (GrowingCircleTypeIsOpen(GrowingCircleTypeDragView))
    {
        [[GrowingMediator sharedInstance] performClass:@"GrowingLocalCircleWindow" action:@"startCircle" params:nil];
    }
    else if (GrowingCircleTypeIsClose(GrowingCircleTypeDragView))
    {
        [[GrowingMediator sharedInstance] performClass:@"GrowingLocalCircleWindow" action:@"stopCircle" params:nil];
    }
}

static GrowingAspectMode growingAspectMode = GrowingAspectModeSubClass;
+ (void)setAspectMode:(GrowingAspectMode)mode
{
    if (![self isFreezeAspectMode])
    {
        growingAspectMode = mode;
    }
    else
    {
        GIOLogWarn(@"setAspectMode失败 程序监控已经开始 请在main函数第一行设置GrowingAspectMode");
    }
}

+ (GrowingAspectMode)aspectMode
{
    return growingAspectMode;
}

static BOOL isFreezeAspectMode = NO;
+ (void)setFreezeAspectMode
{
    isFreezeAspectMode = YES;
}

+ (BOOL)isFreezeAspectMode
{
    return isFreezeAspectMode;
}

static const CLLocationDistance kFiveKM = 5 * 1000;
static const NSTimeInterval kFiveMinutes = 5 * 60;
static CLLocation *growingLocation = nil;
+ (void)setLocation:(CLLocation *)location {
    if (location == nil) {
        return;
    }
    
    if (![GrowingInstance sharedInstance]) {
        
        growingLocation = location;
        return;
    }
    
    [GrowingDispatchManager dispatchInMainThread:^{
        CLLocation *oldLocation = growingLocation;
        CLLocationDistance distance = [location distanceFromLocation:oldLocation];
        NSTimeInterval timeInterval = [location.timestamp timeIntervalSinceDate:oldLocation.timestamp];
        
        
        if (oldLocation == nil || distance >= kFiveKM || (timeInterval >= kFiveMinutes && distance > 1))
        {
            growingLocation = location;
            [GrowingVisitEvent onGpsLocationChanged:location];
        }
    }];
}

+ (void)cleanLocation {
    growingLocation = nil;
}

+ (CLLocation *)getLocation {
    return growingLocation;
}

@end
