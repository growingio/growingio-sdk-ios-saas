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

@interface GrowingBarChart : UIView

@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) CGFloat maxTitleWidth;
@property (nonatomic, assign) CGFloat minTitleWidth;


@property (nonatomic, retain) UIColor *maxBarColor;
@property (nonatomic, retain) UIColor *minBarColor;


- (NSIndexPath*)addTitle:(NSString*)title value:(NSInteger)value;
- (NSIndexPath*)addTitle:(NSString*)title
                   value:(NSInteger)value
                   color:(UIColor*)color
                 onClick:(void(^)(NSIndexPath *index))onClick;

- (NSIndexPath*)addTitle:(NSString*)title
                   value:(NSInteger)value
               valueText:(NSString*)valueText
                   color:(UIColor*)color
                 onClick:(void(^)(NSIndexPath *index))onClick;



- (void)clearAll;

@property (nonatomic, readonly) NSIndexPath *detailIndex;
@property (nonatomic, copy) void(^onDetailIndexChange)(NSIndexPath* index, BOOL animated);
- (void)addDetailView:(UIView*)view forIndexPath:(NSIndexPath*)index animated:(BOOL)animated;
- (void)closeDetailView:(BOOL)animated;


@property (nonatomic , retain) UIView *headerView;

@end
