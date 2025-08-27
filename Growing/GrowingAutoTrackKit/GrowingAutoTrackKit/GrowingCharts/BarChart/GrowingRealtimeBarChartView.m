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


#import "GrowingRealtimeBarChartView.h"
#import "NSData+GrowingHelper.h"
#import "GrowingDetaiLineChartlView.h"
#import "GrowingUIConfig.h"

@interface GrowingRealtimeBarChartView ()

@property (nonatomic, retain) GrowingElement *element;
@property (nonatomic, retain) NSArray<GrowingLocalCircleValueCountItem*>* items;

@property (nonatomic, retain) UIView *singleBarLineChartView;

@property (nonatomic, assign) BOOL canClickBar;
@property (nonatomic, assign) BOOL autoRequestLineChartWhenBarChartOnlyOneBar;

@end

@implementation GrowingRealtimeBarChartView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.maxBarColor = C_R_G_B(98, 155, 237);
        self.minBarColor = C_R_G_B(172, 220, 254);
        self.canClickBar = NO;
        self.autoRequestLineChartWhenBarChartOnlyOneBar = NO;
    }
    return self;
}


- (BOOL)supportClickBarIndex
{
    return NO;
}

- (void)onClickIndex:(NSIndexPath*)index animated:(BOOL)animated
{
    if (!self.canClickBar)
    {
        return;
    }
    NSIndexPath *oldIndex = self.detailIndex;
    if (self.detailIndex)
    {
        [self closeDetailView:animated];
    }
    
    if ([oldIndex isEqual:index])
    {
        return;
    }
    
    UIView *detailView = nil;
    if (self.singleBarLineChartView)
    {
        detailView = self.singleBarLineChartView;
    }
    else
    {
        detailView = [self getLinecharByElement:self.element
                                     andContent:self.items[index.row].value
                                       onFinish:nil];
    }
    [self addDetailView:detailView forIndexPath:index animated:animated];
}

- (UIView*)getLinecharByElement:(GrowingElement*)element
                                         andContent:(NSString*)content
                       onFinish:(void(^)(void))onFinish
{
    
    GrowingElement *newElement = [element copy];
    newElement.content = content;
    
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.bounds.size.width,280)];
    
    CGFloat buttonViewHeight = 40;
    
    
    GrowingDetaiLineChartlView *chartView = [[GrowingDetaiLineChartlView alloc] initWithFrame:CGRectMake(0,0,view.bounds.size.width, view.bounds.size.height - buttonViewHeight)];
    chartView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [chartView loadElement:newElement];
    [chartView setOnLoadFinish:onFinish];
    [view addSubview:chartView];
    
    CGFloat buttonHeight = 25;
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(view.bounds.size.width / 8 * 3,
                                                                view.bounds.size.height - buttonViewHeight / 2 - buttonHeight / 2,
                                                                view.bounds.size.width / 4,
                                                                buttonHeight)];
    [btn2 setTitle:@"保存指标" forState:0];
    @weakify(self);
    btn2.growingHelper_onClick = ^{
        @strongify(self);
        if (self.onSaveElement)
        {
            self.onSaveElement(newElement);
        }
    };
    [btn2 setTitleColor:[GrowingUIConfig eventListTextColor] forState:0];
    btn2.layer.cornerRadius = 3;
    btn2.layer.borderWidth = 1;
    btn2.layer.borderColor = [GrowingUIConfig mainColor].CGColor;
    [view addSubview:btn2];
    view.backgroundColor = [chartView backgroundColor];
    
    return view;
}


- (NSIndexPath*)addTitle:(NSString *)title value:(NSInteger)value
{
    return [self addTitle:title
                    value:value
                    color:nil
                  onClick:nil];
}

- (NSIndexPath*)addTitle:(NSString *)title
                   value:(NSInteger)value
               valueText:(NSString *)valueText
                   color:(UIColor *)color
                 onClick:(void (^)(NSIndexPath *))onClick
{
    
    if (!valueText)
    {
        NSString *valueFormat = self.valueFormatString;
        if (!valueFormat.length)
        {
            valueFormat = @"%d次";
        }
        valueText = [[NSString alloc] initWithFormat:valueFormat,value];
    }
    
    if (!color)
    {
        color = [title isEqualToString:self.element.content] ? C_R_G_B(244, 167, 54) : nil;
    }
    
    @weakify(self);
    return [super addTitle:title
                     value:value
                 valueText:valueText
                     color:color
                   onClick:^(NSIndexPath* index) {
                       @strongify(self);
                       [self onClickIndex:index animated:YES];
                       if (onClick)
                       {
                           onClick(index);
                       }
                   }];
}

- (void)clearAll
{
    [super clearAll];
    self.singleBarLineChartView = nil;
    self.items = nil;
}

- (BOOL)loadValueIfItemCountOnlyOne
{
    return NO;
}

- (void)loadValueCountItems:(NSArray<GrowingLocalCircleValueCountItem*>*)items
{
    self.items = items;
    if (items.count == 1 && self.autoRequestLineChartWhenBarChartOnlyOneBar)
    {
        GrowingLocalCircleValueCountItem *item = items.firstObject;
        @weakify(self);
        UIView *lineChart = [self getLinecharByElement:self.element
                                            andContent:item.value
                                              onFinish:^{
                                                  @strongify(self);
                                                  NSIndexPath *index =
                                                  [self addTitle:item.value
                                                           value:item.count];
                                                  [self onClickIndex:index animated:NO];
                                              }];
        self.singleBarLineChartView = lineChart;
    }
    else
    {
        [items enumerateObjectsUsingBlock:^(GrowingLocalCircleValueCountItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addTitle:obj.value
                     value:obj.count];
        }];
    }
}

- (void)loadElement:(GrowingElement *)element
{
    
    @weakify(self);
    self.element = element;
    [self clearAll];
    
    void(^succeedBlock)(NSArray<GrowingLocalCircleValueCountItem*>* item) = ^(NSArray<GrowingLocalCircleValueCountItem*>* items)
    {
        @strongify(self);
        if (self.element != element)
        {
            return ;
        }
        [self onLoadFinish:YES];
        
        [self loadValueCountItems:items];
    };
    
    GROWNetworkFailureBlock failBlock = ^(NSHTTPURLResponse *response, NSData *data ,NSError *error) {
        @strongify(self);
        [self onLoadFinish:YES];
        
        GrowingLocalCircleValueCountItem *item = [[GrowingLocalCircleValueCountItem alloc] init];
        item.value = self.element.content;
        item.count = 0;
        [self loadValueCountItems:@[item]];
        
    };
    
    [[GrowingLocalCircleModel sdkInstance] requestValueCountsByElement:element
                                                               succeed:succeedBlock
                                                                  fail:failBlock];
}

- (void)onLoadFinish:(BOOL)succeed
{
    if (self.onLoadFinish)
    {
        self.onLoadFinish(succeed);
    }
}

@end
