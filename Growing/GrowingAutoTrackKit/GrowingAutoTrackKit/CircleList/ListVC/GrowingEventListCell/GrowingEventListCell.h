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
#import "GrowingEventListBaseCell.h"

typedef NS_ENUM(NSInteger ,GrowingEventListCellButtonType)
{
    GrowingEventListCellButtonTypeBottom,
    GrowingEventListCellButtonTypeRight,
    GrowingEventListCellButtonTypeTag,
};

@interface GrowingEventListCell : GrowingEventListBaseCell

@property (nonatomic, retain) NSString  *preTitle;
@property (nonatomic, copy) NSString    *title;
@property (nonatomic, copy) NSString    *subtitle;

@property (nonatomic, assign) CGSize    screenShotSize;
@property (nonatomic, retain) UIImage   *screenShot;
@property (nonatomic, copy) NSString    *screenShotKey;


@property (nonatomic, readonly) CGFloat preferredHeight;

- (void)addButtonTitle:(NSString*)title
                  type:(GrowingEventListCellButtonType)type
               onClick:(void(^)(void))onClick;

@end
