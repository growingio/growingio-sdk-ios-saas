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

@interface UIView (ReactNative_Growing)

@property (nonatomic, retain, getter=growingRnIsClickable, setter=growingRnSetClickable:) NSNumber * growingRnClickable;
@property (nonatomic, copy, getter=growingRnPageId, setter=growingRnSetPageId:) NSString * growingRnPageId;
@property (nonatomic, retain, getter=growingRnParameters, setter=growingRnSetParameters:) NSDictionary * growingRnParameters;

@end

@interface GrowingReactNativeEnvironment : NSObject

+ (NSString *)currentPageName;
+ (NSString *)currentWillFocusPageId;
+ (NSString *)currentDidFocusPageId;
+ (BOOL)isTransitioning;

@end

@interface GrowingReactNativeTrack :NSObject

+ (void)onPagePrepare:(NSString *)page;

+ (void)onPageShow:(NSString *)page;

+ (void)setPageVariable:(NSString *)page pageLevelVariables:(NSDictionary *)pageLevelVariables;

@end

@interface GrowingReactNativeAutoTrack : NSObject

+ (void)prepareView:(NSDictionary *)tagClickDict parameters:(NSDictionary *)parameters;

+ (void)onClick:(NSNumber *)tag;

+ (void)onPagePrepare:(NSString *)page;

+ (void)onPageShow:(NSString *)page;

@end
