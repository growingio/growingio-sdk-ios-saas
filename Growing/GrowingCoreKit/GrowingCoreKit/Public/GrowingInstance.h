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


#import <GrowingCoreKit/GrowingCoreKit.h>

typedef NS_ENUM(NSInteger, GrowingCircleType)
{
    GrowingCircleTypeNone       = 0,
    GrowingCircleTypeEventList  = 1 << 0,
    GrowingCircleTypeDragView   = 1 << 1,
    GrowingCircleTypeWeb        = 1 << 2,
    GrowingCircleTypeReplay     = 1 << 3,
    GrowingCircleTypeHeatMap    = 1 << 4,
};

@interface GrowingInstance: NSObject

+ (void)setCircleType:(GrowingCircleType)type withParameter:(NSString *)parameter;
+ (void)setCircleType:(GrowingCircleType)type;
+ (GrowingCircleType)circleType;

+ (void)setAspectMode:(GrowingAspectMode)mode;
+ (GrowingAspectMode)aspectMode;

+ (void)setFreezeAspectMode;
+ (BOOL)isFreezeAspectMode;

+ (void)updateSampling:(CGFloat)sampling;

+ (instancetype)sharedInstance;
+ (void)startWithAccountId:(NSString *)accountId withSampling:(CGFloat)sampling;
- (void)runPastedDeeplink;

+ (BOOL)doDeeplinkByUrl:(NSURL *)url callback:(void(^)(NSDictionary *params, NSTimeInterval processTime, NSError *error))callback;

+ (void)reportGIODeeplink:(NSURL *)linkURL;
+ (void)reportShortChainDeeplink:(NSURL *)linkURL;

typedef void (^GrowingDeeplinkHandler) (NSDictionary *params, NSTimeInterval processTime, NSError *error);
+ (void)setDeeplinkHandler:(GrowingDeeplinkHandler)handler;
+ (GrowingDeeplinkHandler)deeplinkHandler;

+ (void)setLocation:(CLLocation *)location;
+ (void)cleanLocation;
+ (CLLocation *)getLocation;

@property (nonatomic, copy,   readonly) NSString *      accountID;

@end

NS_INLINE NSNumber *GROWGetTimestampFromTimeInterval(NSTimeInterval timeInterval) {
    return [NSNumber numberWithUnsignedLongLong:timeInterval * 1000.0];
}

NS_INLINE NSNumber *GROWGetTimestamp() {
    return GROWGetTimestampFromTimeInterval([[NSDate date] timeIntervalSince1970]);
}

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)	([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define IOS6_PLUS SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")
#define IOS7_PLUS SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")
#define IOS8_PLUS SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")
#define IOS10_PLUS SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")
#define IOS14_PLUS SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"14.0")
