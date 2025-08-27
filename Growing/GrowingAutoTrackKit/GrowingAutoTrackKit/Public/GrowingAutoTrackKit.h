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
#import <GrowingCoreKit/GrowingCoreKit.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface Growing (AutoTrackKit)


+ (NSString*)autoTrackKitVersion;


+ (void)setHybridJSSDKUrlPrefix:(NSString*)urlPrefix;


+ (void)enableAllWebViews:(BOOL)enable;

+ (void)enableHybridHashTag:(BOOL)enable;

+ (BOOL)isTrackingWebView;


+ (void)setImp:(BOOL)imp;


+ (void)setGlobalImpScale:(double)scale;
+ (double)globalImpScale;



+ (void)setPageVariable:(NSDictionary<NSString *, NSObject *> *)variable
       toViewController:(UIViewController *)viewController;

+ (void)setPageVariableWithKey:(NSString *)key
                andStringValue:(NSString *)stringValue
              toViewController:(UIViewController *)viewController;

+ (void)setPageVariableWithKey:(NSString *)key
                andNumberValue:(NSNumber *)numberValue
              toViewController:(UIViewController *)viewController;


+ (void)setAppVariable:(NSDictionary<NSString *, NSObject *> *)variable;
+ (void)setAppVariableWithKey:(NSString *)key andStringValue:(NSString *)stringValue;
+ (void)setAppVariableWithKey:(NSString *)key andNumberValue:(NSNumber *)numberValue;
@end


@interface UIView(GrowingImpression)

#pragma mark - Warning: 请在真机下校验数据





@property (nonatomic, assign) double growingImpScale;




- (void)growingImpTrack:(NSString *)eventId;

- (void)growingImpTrack:(NSString *)eventId withNumber:(NSNumber *)number;

- (void)growingImpTrack:(NSString *)eventId withVariable:(NSDictionary<NSString *, id> *)variable;

- (void)growingImpTrack:(NSString *)eventId withNumber:(NSNumber *)number andVariable:(NSDictionary<NSString *, id> *)variable;




- (void)growingStopImpTrack;

@end



@interface UIView(GrowingAttributes)


@property (nonatomic, assign) BOOL      growingAttributesDonotTrack;


@property (nonatomic, assign) BOOL      growingAttributesDonotTrackImp;


@property (nonatomic, assign) BOOL      growingAttributesDonotTrackValue;


@property (nonatomic, copy)   NSString* growingAttributesValue;


@property (nonatomic, strong) NSArray<NSString *>
* growingSDCycleBannerIds;


@property (nonatomic, copy)   NSString* growingAttributesInfo;





@property (nonatomic, copy)   NSString* growingAttributesUniqueTag;

@end



@interface UIViewController(GrowingAttributes)


@property (nonatomic, copy)   NSString* growingAttributesInfo;


@property (nonatomic, copy)   NSString* growingAttributesPageName;

@end

@interface WKWebView(GrowingAttributes)


@property (nonatomic, assign) BOOL growingAttributesIsTracked;

@end
