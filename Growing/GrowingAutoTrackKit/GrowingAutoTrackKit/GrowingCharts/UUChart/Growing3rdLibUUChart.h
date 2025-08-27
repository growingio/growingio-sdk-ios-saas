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
#import "Growing3rdLibUUChart.h"
#import "Growing3rdLibUUColor.h"
#import "Growing3rdLibUULineChart.h"
#import "Growing3rdLibUUBarChart.h"

typedef enum {
	Growing3rdLibUUChartLineStyle,
	Growing3rdLibUUChartBarStyle
} Growing3rdLibUUChartStyle;


@class Growing3rdLibUUChart;
@protocol Growing3rdLibUUChartDataSource <NSObject>

@required

- (NSArray *)Growing3rdLibUUChart_xLableArray:(Growing3rdLibUUChart *)chart;


- (NSArray *)Growing3rdLibUUChart_yValueArray:(Growing3rdLibUUChart *)chart;

@optional

- (NSArray *)Growing3rdLibUUChart_ColorArray:(Growing3rdLibUUChart *)chart;


- (NSArray *)Growing3rdLibUUChart_NameArray:(Growing3rdLibUUChart *)chart;


- (CGRange)Growing3rdLibUUChartChooseRangeInLineChart:(Growing3rdLibUUChart *)chart;

#pragma mark 折线图专享功能

- (CGRange)Growing3rdLibUUChartMarkRangeInLineChart:(Growing3rdLibUUChart *)chart;


- (BOOL)Growing3rdLibUUChart:(Growing3rdLibUUChart *)chart ShowHorizonLineAtIndex:(NSInteger)index;


- (BOOL)Growing3rdLibUUChart:(Growing3rdLibUUChart *)chart ShowMaxMinAtIndex:(NSInteger)index;
@end


@interface Growing3rdLibUUChart : UIView


@property (nonatomic, assign) BOOL showRange;

@property (assign) Growing3rdLibUUChartStyle chartStyle;

-(id)initwithGrowing3rdLibUUChartDataFrame:(CGRect)rect withSource:(id<Growing3rdLibUUChartDataSource>)dataSource withStyle:(Growing3rdLibUUChartStyle)style;

- (void)showInView:(UIView *)view;

-(void)strokeChart;

@end
