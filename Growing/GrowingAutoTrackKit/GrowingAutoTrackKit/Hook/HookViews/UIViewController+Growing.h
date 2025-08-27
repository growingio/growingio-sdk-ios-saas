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

typedef NS_ENUM(NSInteger, GrowingAppearState)
{
    GrowingAppearStateDidHide   = 0 ,
    GrowingAppearStateDidShow       ,
    GrowingAppearStateWillHide      ,
    GrowingAppearStateWillShow      ,
    GrowingAppearStateCancelHide    ,
    GrowingAppearStateCancelShow    ,
    GrowingAppearStateCount
};

@interface UIViewController (Growing)

- (GrowingAppearState)growingHook_appearState;

- (BOOL)growingHook_isCustomAddVC;
- (void)GROW_outOfLifetimeShow;

- (BOOL)GROW_isShow;

- (NSString*)GROW_pageName;
- (NSString*)GROW_pageTitle;





- (NSNumber*)GROW_createTimestamp;
- (NSNumber*)GROW_lastShowTimestamp;
- (NSNumber*)GROW_lastHideTimestamp;

- (void)setGROW_lastShowTimestamp:(NSNumber *)t;

- (void)setGROW_pvarCacheTimestamp:(NSNumber *)t;
- (NSNumber *)GROW_pvarCacheTimestamp;



- (BOOL)growingCanBecomeMainPage;
- (void)growingTrackSelfPage;
- (void)growingTrackSelfResendPage;
- (void)growingTrackSelfSendNewPage;
- (void)growingTrackSelfPageOnPSChange;


- (void)setSubPageName:(NSString *)subPageName;

-(void)getElementInView:(UIView * )aNode ;
@end
