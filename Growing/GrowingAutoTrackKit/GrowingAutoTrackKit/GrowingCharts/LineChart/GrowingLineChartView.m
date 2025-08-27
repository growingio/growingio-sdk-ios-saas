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


#import "GrowingLineChartView.h"
#import "NSString+GrowingHelper.h"
#import "Growing3rdLibUUChart.h"
#import "GrowingUIHeader.h"
#import "GrowingUIConfig.h"
#import "GrowingInstance.h"


@interface GrowingLineChartView() <Growing3rdLibUUChartDataSource>


@property (nonatomic, retain) GrowingRealTimeData *data;

@property (nonatomic, retain) UIView * accessoryView;

@property (nonatomic, retain) UIActivityIndicatorView * busyIndicatorView;
@property (nonatomic, retain) UILabel *titleLabel;

@property (nonatomic, retain) UIView *chartView;

@end

@implementation GrowingLineChartView

- (void)setText:(NSString *)text
{
    [self resetAccessoryView];
    self.titleLabel =
    [self.accessoryView growAddLabelWithFontSize:12
                                           color:[GrowingUIConfig textColor]
                                           lines:0
                                            text:text
                                           block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                               make.left.offset(0);
                                               make.right.offset(0);
                                               make.top.offset(0);
                                               make.bottom.offset(0);
                                               lable.textAlignment = NSTextAlignmentCenter;
                                           }];
}

- (void)setBusy
{
    [self resetAccessoryView];
    __weak GrowingLineChartView * wself = self;
    [self.accessoryView growAddSubviewClass:[UIActivityIndicatorView class]
                                      block:^(MASG3ConstraintMaker *make, id obj) {
                                          make.width.offset(40);
                                          make.height.offset(40);
                                          make.centerX.masG3_equalTo(wself.accessoryView.masG3_centerX);
                                          make.centerY.masG3_equalTo(wself.accessoryView.masG3_centerY);
                                          UIActivityIndicatorView * indicator = obj;
                                          [indicator setCenter:CGPointMake(20, 20)];
                                          [indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
                                          [indicator startAnimating];
                                      }];
}

- (void)resetAccessoryView
{
    [self removeAllSubviews];
    self.accessoryView =
    [self growAddSubviewClass:[UIView class]
                        block:^(MASG3ConstraintMaker *make, id obj) {
                            make.left.offset(0);
                            make.right.offset(0);
                            make.top.offset(0);
                            make.bottom.offset(0);
                            UIView * view = obj;
                            view.layer.cornerRadius = 10;
                            view.layer.borderColor = [UIColor grayColor].CGColor;
                            view.layer.borderWidth = 1;
                        }];
}

- (void)removeAllSubviews
{
    [self.chartView removeFromSuperview];
    self.chartView = nil;
    self.titleLabel = nil;
    self.busyIndicatorView = nil;
    [self.accessoryView removeFromSuperview];
    self.accessoryView = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [super initWithFrame:frame];
}

- (BOOL)loadData:(GrowingRealTimeData *)realTimeData
{
    if ([realTimeData valueCount] == 0 || [realTimeData lineCount] == 0)
    {
        return NO;
    }
    [self removeAllSubviews];
    
    self.data = realTimeData;
    [self setNeedsLayout];
    return YES;
}

- (void)layoutSubviews
{
    if (self.accessoryView == nil)
    {
        [self removeAllSubviews];
        Growing3rdLibUUChart *chart = [[Growing3rdLibUUChart alloc] initwithGrowing3rdLibUUChartDataFrame:self.bounds
                                                                                               withSource:self
                                                                                                withStyle:Growing3rdLibUUChartLineStyle];
        chart.showRange = YES;
        [chart showInView:self];
        self.chartView = chart;
    }
    [super layoutSubviews]; 
}


- (NSArray *)Growing3rdLibUUChart_xLableArray:(Growing3rdLibUUChart *)chart
{
    NSMutableArray *arr = [[NSMutableArray alloc ] init];
    for (NSInteger i = 0 ; i< [self.data valueCount] ; i ++)
    {
        NSString *timeStr = [self.data titleForValueIndex:i];
        
        double timestamp = timeStr.longLongValue / (double)1000.0f;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MM/dd";
        [arr addObject: [formatter stringFromDate:date]];
    }
    return arr;
}


- (NSArray *)Growing3rdLibUUChart_yValueArray:(Growing3rdLibUUChart *)chart
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (NSInteger i = 0 ; i < [self.data lineCount]; i++)
    {
        NSMutableArray *arr2 = [[NSMutableArray alloc] init];
        for (NSInteger j = 0 ; j < [self.data valueCount] ; j ++)
        {
            [arr2 addObject:[NSNumber numberWithInteger:[self.data valueForValueIndex:j lineIndex:i]]];
        }
        [arr addObject:arr2];
    }
    
    return arr;
}


- (NSArray *)Growing3rdLibUUChart_ColorArray:(Growing3rdLibUUChart *)chart
{
    if ([GrowingInstance circleType] == GrowingCircleTypeEventList)
    {
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0 ; i < [self.data lineCount] ; i++)
        {
            [arr addObject:[self.data colorForLineIndex:i]];
        }
        return arr;
    }
    else
    {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0 ; i < [self.data lineCount] ; i++)
        {
            switch (i) {
                case 0:
                    [arr addObject:[[UIColor blueColor] colorWithAlphaComponent:0.5]];
                    break;
                case 1:
                    [arr addObject:[[UIColor redColor] colorWithAlphaComponent:0.5]];
                    break;
                case 2:
                    [arr addObject:[[UIColor greenColor] colorWithAlphaComponent:0.5]];
                    break;
                case 3:
                    [arr addObject:[[UIColor yellowColor] colorWithAlphaComponent:0.5]];
                    break;

                default:
                    [arr addObject:[[UIColor orangeColor] colorWithAlphaComponent:0.5]];
                    break;
            }
        }

        
        
        
        
        return arr;
    }
}


- (NSArray *)Growing3rdLibUUChart_NameArray:(Growing3rdLibUUChart *)chart
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (NSInteger i = 0 ; i < [self.data lineCount]; i++)
    {
        [arr addObject:[self.data nameForLineIndex:i]];
    }
    return arr;
}


- (BOOL)Growing3rdLibUUChart:(Growing3rdLibUUChart *)chart ShowHorizonLineAtIndex:(NSInteger)index
{
    if ([GrowingInstance circleType] == GrowingCircleTypeEventList)
    {
        
        if (index == 2 || index == 0)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else
    {
        return YES;
    }
}



- (BOOL)Growing3rdLibUUChart:(Growing3rdLibUUChart *)chart ShowMaxMinAtIndex:(NSInteger)index
{
    return YES;
}

@end
