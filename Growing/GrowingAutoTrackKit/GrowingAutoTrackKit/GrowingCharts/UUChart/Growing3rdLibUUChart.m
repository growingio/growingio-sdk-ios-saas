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


#import "Growing3rdLibUUChart.h"

@interface Growing3rdLibUUChart ()

@property (strong, nonatomic) Growing3rdLibUULineChart * lineChart;

@property (strong, nonatomic) Growing3rdLibUUBarChart * barChart;

@property (assign, nonatomic) id<Growing3rdLibUUChartDataSource> dataSource;

@end

@implementation Growing3rdLibUUChart

-(id)initwithGrowing3rdLibUUChartDataFrame:(CGRect)rect withSource:(id<Growing3rdLibUUChartDataSource>)dataSource withStyle:(Growing3rdLibUUChartStyle)style{
    self.dataSource = dataSource;
    self.chartStyle = style;
    return [self initWithFrame:rect];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        

        self.clipsToBounds = NO;
    }
    return self;
}

-(void)setUpChart{
	if (self.chartStyle == Growing3rdLibUUChartLineStyle) {
        if(!_lineChart){
            _lineChart = [[Growing3rdLibUULineChart alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
            [self addSubview:_lineChart];
        }
        
        if ([self.dataSource respondsToSelector:@selector(Growing3rdLibUUChartMarkRangeInLineChart:)]) {
            [_lineChart setMarkRange:[self.dataSource Growing3rdLibUUChartMarkRangeInLineChart:self]];
        }
        
        if ([self.dataSource respondsToSelector:@selector(Growing3rdLibUUChartChooseRangeInLineChart:)]) {
            [_lineChart setChooseRange:[self.dataSource Growing3rdLibUUChartChooseRangeInLineChart:self]];
        }
        
        if ([self.dataSource respondsToSelector:@selector(Growing3rdLibUUChart_ColorArray:)]) {
            [_lineChart setColors:[self.dataSource Growing3rdLibUUChart_ColorArray:self]];
        }
        
        if ([self.dataSource respondsToSelector:@selector(Growing3rdLibUUChart_NameArray:)]) {
            [_lineChart setLineNames:[self.dataSource Growing3rdLibUUChart_NameArray:self]];
        }
        
        if ([self.dataSource respondsToSelector:@selector(Growing3rdLibUUChart:ShowHorizonLineAtIndex:)]) {
            NSMutableArray *showHorizonArray = [[NSMutableArray alloc]init];
            for (int i=0; i<5; i++) {
                if ([self.dataSource Growing3rdLibUUChart:self ShowHorizonLineAtIndex:i]) {
                    [showHorizonArray addObject:@"1"];
                }else{
                    [showHorizonArray addObject:@"0"];
                }
            }
            [_lineChart setShowHorizonLine:showHorizonArray];

        }
        
        if ([self.dataSource respondsToSelector:@selector(Growing3rdLibUUChart:ShowMaxMinAtIndex:)]) {
            NSMutableArray *showMaxMinArray = [[NSMutableArray alloc]init];
            NSArray *y_values = [self.dataSource Growing3rdLibUUChart_yValueArray:self];
            if (y_values.count>0){
                for (int i=0; i<y_values.count; i++) {
                    if ([self.dataSource Growing3rdLibUUChart:self ShowMaxMinAtIndex:i]) {
                        [showMaxMinArray addObject:@"1"];
                    }else{
                        [showMaxMinArray addObject:@"0"];
                    }
                }
                _lineChart.ShowMaxMinArray = showMaxMinArray;
            }
        }
        
		[_lineChart setYValues:[self.dataSource Growing3rdLibUUChart_yValueArray:self]];
		[_lineChart setXLabels:[self.dataSource Growing3rdLibUUChart_xLableArray:self]];
        
		[_lineChart strokeChart];

		[_lineChart drawLegend];
	}else if (self.chartStyle == Growing3rdLibUUChartBarStyle)
	{
        if (!_barChart) {
            _barChart = [[Growing3rdLibUUBarChart alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
            [self addSubview:_barChart];
        }
        if ([self.dataSource respondsToSelector:@selector(Growing3rdLibUUChartChooseRangeInLineChart:)]) {
            [_barChart setChooseRange:[self.dataSource Growing3rdLibUUChartChooseRangeInLineChart:self]];
        }
        if ([self.dataSource respondsToSelector:@selector(Growing3rdLibUUChart_ColorArray:)]) {
            [_barChart setColors:[self.dataSource Growing3rdLibUUChart_ColorArray:self]];
        }
		[_barChart setYValues:[self.dataSource Growing3rdLibUUChart_yValueArray:self]];
		[_barChart setXLabels:[self.dataSource Growing3rdLibUUChart_xLableArray:self]];
        
        [_barChart strokeChart];
	}
}

- (void)showInView:(UIView *)view
{
    [self setUpChart];
    [view addSubview:self];
}

-(void)strokeChart
{
	[self setUpChart];
	
}



@end
