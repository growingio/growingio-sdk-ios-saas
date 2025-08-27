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


#import "GrowingDetaiLineChartlView.h"
#import "UIView+GrowingHelperLayout.h"
#import "GrowingUIConfig.h"

@interface GrowingDetaiLineChartlView()
@property (nonatomic, retain) GrowingRealtimeLineChartView *chartView;
@property (nonatomic, retain) NSMutableArray <UILabel*> * labelNumbers;
@end

@implementation GrowingDetaiLineChartlView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.labelNumbers = [[NSMutableArray alloc] init];
        self.backgroundColor = C_R_G_B(0xF3, 0xF6, 0xFA);
        
        UIView * leftNumberWrapper =
        [self growAddViewWithColor:[UIColor clearColor]
                                               block:^(MASG3ConstraintMaker *make, UIView *view) {
                                                   make.top.offset(20);
                                                   make.height.offset(40);
                                                   make.left.offset(0);
                                               }];
        UIView * middleNumberWrapper =
        [self growAddViewWithColor:[UIColor clearColor]
                                               block:^(MASG3ConstraintMaker *make, UIView *view) {
                                                   make.top.masG3_equalTo(leftNumberWrapper.masG3_top);
                                                   make.height.masG3_equalTo(leftNumberWrapper.masG3_height);
                                                   make.left.masG3_equalTo(leftNumberWrapper.masG3_right);
                                                   make.width.masG3_equalTo(leftNumberWrapper.masG3_width);
                                               }];
        UIView * rightNumberWrapper =
        [self growAddViewWithColor:[UIColor clearColor]
                                               block:^(MASG3ConstraintMaker *make, UIView *view) {
                                                   make.top.masG3_equalTo(middleNumberWrapper.masG3_top);
                                                   make.height.masG3_equalTo(middleNumberWrapper.masG3_height);
                                                   make.left.masG3_equalTo(middleNumberWrapper.masG3_right);
                                                   make.right.offset(0);
                                                   make.width.masG3_equalTo(middleNumberWrapper.masG3_width);
                                               }];
        [leftNumberWrapper growAddViewWithColor:C_R_G_B(0xD0, 0xDC, 0xEB)
                                          block:^(MASG3ConstraintMaker *make, UIView *view) {
                                              make.width.offset(1);
                                              make.right.offset(0);
                                              make.top.offset(0);
                                              make.bottom.offset(0);
                                          }];
        [rightNumberWrapper growAddViewWithColor:C_R_G_B(0xD0, 0xDC, 0xEB)
                                           block:^(MASG3ConstraintMaker *make, UIView *view) {
                                               make.left.offset(0);
                                               make.width.offset(1);
                                               make.top.offset(0);
                                               make.bottom.offset(0);
                                           }];
        NSArray<NSString *> * numberNames = @[@"昨日浏览", @"昨日点击", @"昨日点击率"];
        NSEnumerator * numberNamesEnumerator = numberNames.objectEnumerator;
        for (UIView * v in @[leftNumberWrapper, middleNumberWrapper, rightNumberWrapper])
        {
            UILabel * label =
            [v growAddLabelWithFontSize:21
                                  color:C_R_G_B(0x66, 0x80, 0xA2)
                                  lines:0
                                   text:@""
                                  block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                      make.left.offset(0);
                                      make.right.offset(0);
                                      make.top.offset(0);
                                      make.height.offset(21);
                                      lable.textAlignment = NSTextAlignmentCenter;
                                  }];
            [v growAddLabelWithFontSize:11
                                  color:C_R_G_B(0x98, 0xAD, 0xC9)
                                  lines:0
                                   text:[numberNamesEnumerator nextObject]
                                  block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                      make.left.offset(0);
                                      make.right.offset(0);
                                      make.height.offset(11);
                                      make.bottom.offset(0);
                                      lable.textAlignment = NSTextAlignmentCenter;
                                  }];
            [self.labelNumbers addObject:label];
        }
        self.chartView = [[GrowingRealtimeLineChartView alloc] initWithFrame:CGRectMake(0, 80, frame.size.width, self.bounds.size.height - 80)];
        @weakify(self);
        [self.chartView setOnLoadFinish:^(BOOL succeed) {
            @strongify(self);
            [self updateNumbersWithData:self.chartView.data];
            if (self.onLoadFinish)
            {
                self.onLoadFinish();
            }
        }];
        [self addSubview:self.chartView];
    }
    return self;
}

- (NSArray *)humanReadableNumberComponents:(NSUInteger)n
{
    double number = 0.0;
    NSString * digits = nil;
    NSString * unit = nil;
    double K = 1000.0;
    double M = K * K;
    double G = K * K * K;
    if (n < K)
    {
        digits = [NSString stringWithFormat:@"%ld", (long)n];
    }
    else if (n < M)
    {
        number = n / K;
        unit = @"k";
    }
    else if (n < G)
    {
        number = n / M;
        unit = @"m";
    }
    else
    {
        number = n / G;
        unit = @"g";
    }
    if (digits == nil)
    {
        NSString * format = nil;
        if (number < 10)
        {
            format = @"%1.2lf";
        }
        else if (number < 100)
        {
            format = @"%2.1lf";
        }
        else if (number < 1000)
        {
            format = @"%3.0lf";
        }
        else
        {
            format = @"%.0lf";
        }
        digits = [NSString stringWithFormat:format, number];
    }
    if (unit == nil)
    {
        return @[digits];
    }
    else
    {
        return @[digits, unit];
    }
}

- (void)loadElement:(GrowingElement *)element
{
    [self.chartView loadElement:element];
}

- (void)updateNumbersWithData:(GrowingRealTimeData*)data
{
    NSNumber * impressionCount = nil;
    NSNumber * clickCount = nil;
    if ([data lineCount] >= 2)
    {
        if ([data valueCount] >= 2) 
        {
            NSInteger count1 = [data valueForValueIndex:[data valueCount] - 2
                                             lineIndex:1];
            NSInteger count0 = [data valueForValueIndex:[data valueCount] - 2
                                              lineIndex:0];
            clickCount = [NSNumber numberWithInteger:count1];
            impressionCount = [NSNumber numberWithInteger:count0];
        }
    }
    else if ([data lineCount] == 1)
    {
        if ([data valueCount] >= 2) 
        {
            NSInteger count0 = [data valueForValueIndex:[data valueCount] - 2
                                              lineIndex:0];
            impressionCount = [NSNumber numberWithInteger:count0];
        }
    }
    NSMutableAttributedString * (^formatNumberComponents)(NSArray<NSString *> * numberComponents)
    = ^NSMutableAttributedString*(NSArray<NSString *> * numberComponents)
    {
        NSMutableAttributedString * s = [[NSMutableAttributedString alloc] initWithString:[numberComponents componentsJoinedByString:@""]];
        if (numberComponents.count >= 1)
        {
            [s addAttribute:NSFontAttributeName
                      value:[UIFont systemFontOfSize:21]
                      range:NSMakeRange(0, numberComponents.firstObject.length)];
        }
        if (numberComponents.count >= 2)
        {
            [s addAttribute:NSFontAttributeName
                      value:[UIFont systemFontOfSize:14]
                      range:NSMakeRange(numberComponents.firstObject.length, numberComponents.lastObject.length)];
        }
        NSMutableParagraphStyle *paragrapStyle = [[NSMutableParagraphStyle alloc] init];
        paragrapStyle.alignment = NSTextAlignmentCenter;
        [s addAttribute:NSParagraphStyleAttributeName value:paragrapStyle range:NSMakeRange(0, s.length)];
        return s;
    };
    NSMutableAttributedString * (^formatNumber)(NSUInteger n)
    = ^NSMutableAttributedString*(NSUInteger n)
    {
        return formatNumberComponents([self humanReadableNumberComponents:n]);
    };
    
    if (impressionCount != nil)
    {
        self.labelNumbers[0].attributedText = formatNumber([impressionCount unsignedIntegerValue]);
    }
    else
    {
        self.labelNumbers[0].text = @"--";
    }
    if (clickCount != nil)
    {
        self.labelNumbers[1].attributedText = formatNumber([clickCount unsignedIntegerValue]);
    }
    else
    {
        self.labelNumbers[1].text = @"--";
    }
    if (impressionCount != nil && clickCount != nil && [impressionCount unsignedIntegerValue] != 0)
    {
        double ratio = (double)[clickCount unsignedIntegerValue] / (double)[impressionCount unsignedIntegerValue];
        NSString * format = nil;
        if (ratio < 0.1)
        {
            format = @"%1.2lf";
        }
        else if (ratio < 1)
        {
            format = @"%2.1lf";
        }
        else
        {
            format = @"%.0lf";
        }
        NSString * digits = [NSString stringWithFormat:format, 100 * ratio];
        NSString * unit = @"%";
        self.labelNumbers[2].attributedText = formatNumberComponents(@[digits, unit]);
    }
    else
    {
        self.labelNumbers[2].text = @"--";
    }
}


@end
