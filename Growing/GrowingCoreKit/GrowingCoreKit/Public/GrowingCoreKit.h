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
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <Security/Security.h>
#import <CFNetwork/CFNetwork.h>
#import <CoreLocation/CoreLocation.h>
#import <WebKit/WebKit.h>


typedef NS_ENUM(NSInteger, GrowingAspectMode)
{
    
    
    
    
    
    GrowingAspectModeSubClass           ,
    
    
    GrowingAspectModeDynamicSwizzling   ,
};

@interface Growing : NSObject


+ (NSString*)sdkVersion;






+ (BOOL)handleUrl:(NSURL*)url;







+ (void)startWithAccountId:(NSString *)accountId withSampling:(CGFloat)sampling;


+ (void)startWithAccountId:(NSString *)accountId;


+ (void)setEnableLog:(BOOL)enableLog;
+ (BOOL)getEnableLog;


+ (void)setEncryptStringBlock:(NSString *(^)(NSString *string))block;


+ (void)disablePushTrack:(BOOL)disable;
+ (BOOL)getDisablePushTrack;



+ (void)setEnableLocationTrack:(BOOL)enable;
+ (BOOL)getEnableLocationTrack;



+ (void)setLocation:(CLLocation *)location;


+ (void)cleanLocation;







+ (void)setDeviceIDModeToCustomBlock:(NSString*(^)(void))customBlock;


+ (void)registerDeeplinkHandler:(void(^)(NSDictionary *params, NSTimeInterval processTime, NSError *error))handler;



+ (BOOL)isDeeplinkUrl:(NSURL *)url;


+ (BOOL)doDeeplinkByUrl:(NSURL *)url callback:(void(^)(NSDictionary *params, NSTimeInterval processTime, NSError *error))callback;


+ (void)registerRealtimeReportHandler:(void(^)(NSDictionary *eventObject))handler;


+ (void)setAspectMode:(GrowingAspectMode)aspectMode;
+ (GrowingAspectMode)getAspectMode;


+ (void)setBundleId:(NSString *)bundleId;
+ (NSString *)getBundleId; 


+ (void)setUrlScheme:(NSString *)urlScheme;
+ (NSString *)getUrlScheme; 


+ (void)setEnableDiagnose:(BOOL)enable;


+ (void)disable;


+ (void)setFlushInterval:(NSTimeInterval)interval;
+ (NSTimeInterval)getFlushInterval;


+ (void)setSessionInterval:(NSTimeInterval)interval;
+ (NSTimeInterval)getSessionInterval;


+ (void)setDailyDataLimit:(NSUInteger)numberOfKiloByte;
+ (NSUInteger)getDailyDataLimit;


+ (void)setTrackerHost:(NSString *)host;


+ (void)setReportHost:(NSString *)host;


+ (void)setDataHost:(NSString*)host;


+ (void)setAssetsHost:(NSString*)host;


+ (void)setGtaHost:(NSString*)host;


+ (void)setWsHost:(NSString*)host;


+ (void)setZone:(NSString *)zone;


+ (void)disableDataCollect;

+ (void)enableDataCollect;


+ (void)setReadClipBoardEnable:(BOOL)enabled;


+ (void)setAsaEnabled:(BOOL)asaEnabled;


+ (NSString *)getDeviceId;

+ (NSString *)getVisitUserId;

+ (NSString *)getSessionId;




+ (void)setUserId:(NSString *)userId;

+ (void)clearUserId;

+ (void)setEvar:(NSDictionary<NSString *, NSObject *> *)variable;

+ (void)setEvarWithKey:(NSString *)key andStringValue:(NSString *)stringValue;

+ (void)setEvarWithKey:(NSString *)key andNumberValue:(NSNumber *)numberValue;


+ (void)setPeopleVariable:(NSDictionary<NSString *, NSObject *> *)variable;

+ (void)setPeopleVariableWithKey:(NSString *)key andStringValue:(NSString *)stringValue;

+ (void)setPeopleVariableWithKey:(NSString *)key andNumberValue:(NSNumber *)numberValue;


+ (void)track:(NSString *)eventId;


+ (void)track:(NSString *)eventId withNumber:(NSNumber *)number;


+ (void)track:(NSString *)eventId withNumber:(NSNumber *)number andVariable:(NSDictionary<NSString *, id> *)variable;


+ (void)track:(NSString *)eventId withVariable:(NSDictionary<NSString *, id> *)variable;


+ (void)setVisitor:(NSDictionary<NSString *, NSObject *> *)variable;


+ (void)setUploadExceptionEnable:(BOOL)uploadExceptionEnable;

+ (void)bridgeForWKWebView:(WKWebView *)webView;
@end
