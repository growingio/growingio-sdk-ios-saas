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
@class FoWeakObjectShell;

@interface UIWindow (Growing)

- (NSNumber*)GROW_timestamp;

@property (nonatomic, readonly) NSArray<FoWeakObjectShell *>          *growingHook_curViewControllers;
@property (nonatomic, readonly) UIViewController *growingHook_curViewController;

- (void)growingHook_addVisiableController:(UIViewController*)aVC;
- (void)growingHook_removeVisiableController:(UIViewController*)aVC;

- (void)growingHook_setNeedUpdateCurViewControllers;






@end
