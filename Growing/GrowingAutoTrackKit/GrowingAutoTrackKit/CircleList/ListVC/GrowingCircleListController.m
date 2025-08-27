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


#import "GrowingCircleListController.h"
#import "GrowingEventListCell.h"
#import "GrowingUIConfig.h"
#import "GrowingEventListMenu.h"
#import "UIView+GrowingHelperLayout.h"
#import "GrowingAddTagMenu.h"

#import "GrowingLocalCircleModel.h"
#import "GrowingRealtimeLineChartView.h"
#import "GrowingDeviceInfo.h"
#import "GrowingBarChart.h"
#import "GrowingDetaiLineChartlView.h"
#import "GrowingChildContentPanel.h"
#import "GrowingRealtimeBarChartView.h"
#import "NSData+GrowingHelper.h"
#import "GrowingCircleListSettingViewController.h"
#import "GrowingCircleListAddTagViewController.h"

@interface GrowingCircleListController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, retain) NSArray<GrowingEventListItem *> *items;


@property (nonatomic, retain) NSIndexSet *showEventSet;
@property (nonatomic, retain) UITableView   *tableView;

@property (nonatomic, assign) NSTimeInterval showTimeinterval;

@end

@implementation GrowingCircleListController


+ (NSMutableIndexSet*)eventTypesSet
{
    static NSMutableIndexSet *eventTypesSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        eventTypesSet = [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, GrowingEventTypeMainEventCount)];
        [eventTypesSet removeIndex:GrowingEventTypeNetWork];
        [eventTypesSet removeIndex:GrowingEventTypeUI];
    });
    return eventTypesSet;
}

+ (void)showEventType:(GrowingEventType)eventType
{
    [[self eventTypesSet] addIndex:eventType];
}

+ (void)hideEventType:(GrowingEventType)eventType
{
    [[self eventTypesSet] removeIndex:eventType];
}

+ (BOOL)isEventShow:(GrowingEventType)eventType
{
    return [[self eventTypesSet] containsIndex:eventType];
}


- (instancetype)initWithItems:(NSArray<GrowingEventListItem *> *)items
{
    self = [super init];
    if (self)
    {
        self.items = items;
        self.title = @"事件列表";
        
        NSDictionary *attr = @{NSForegroundColorAttributeName:self.barTextColor};

        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(close)];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"设置"
                                                                                  style:UIBarButtonItemStylePlain target:self action:@selector(filterClick)];
        
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes:attr forState:0];
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:attr forState:0];
    }
    return self;
}

- (void)filterClick
{
    GrowingCircleListSettingViewController *setting = [[GrowingCircleListSettingViewController alloc] init];
    [self.navigationController pushViewController:setting animated:YES];
}

- (void)close
{
    if(self.onCloseClick)
    {
        self.onCloseClick();
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                          style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.backgroundColor = [GrowingUIConfig eventListBgColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    
    self.showTimeinterval = [[NSDate date] timeIntervalSince1970];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![self.showEventSet isEqualToIndexSet:[[self class] eventTypesSet]])
    {
        self.showEventSet = [[[self class] eventTypesSet] copy];
        [self.tableView reloadData];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GrowingEventListItem *item = self.items[indexPath.row];
    
    if (![self isShowItem:item])
    {
        return 0;
    }
   
    static GrowingEventListCell *sizeCell = nil;
    if (!sizeCell)
    {
        sizeCell = [[GrowingEventListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sizeCell"];
        sizeCell.frame = tableView.bounds;
    }
    [sizeCell prepareForReuse];
    [self fillCell:sizeCell withItem:item];
    [sizeCell layoutIfNeeded];
    return sizeCell.preferredHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (BOOL)isShowType:(GrowingEventType)type
{
    return [[self class] isEventShow:GrowingTypeGetMainType(type)];
}

- (BOOL)isShowItem:(GrowingEventListItem*)item
{
    return [self isShowType:item.eventType];
}

- (BOOL)isShowIndexPath:(NSIndexPath*)indexPath
{
    GrowingEventListItem *item = self.items[indexPath.row];
    return [self isShowItem:item];
}

- (NSString*)showTimeWithNowDate:(NSTimeInterval)now itemDate:(NSTimeInterval)itemDate
{
    NSTimeInterval time = now - itemDate;
    if (time < 60)
    {
        return [[NSString alloc] initWithFormat:@"%d秒前",(int)time];
    }
    else if (time < 3600)
    {
        return [[NSString alloc] initWithFormat:@"%d分钟前",(int)time / 60];
    }
    else
    {
        return [[NSString alloc] initWithFormat:@"%d小时前",(int)time / 60 / 24];
    }
}

- (void)fillCell:(GrowingEventListCell*)cell withItem:(GrowingEventListItem*)item
{
    if (![self isShowItem:item])
    {
        return;
    }
    
    GrowingEventType mainEventType = GrowingTypeGetMainType(item.eventType);
    cell.title = item.title;
    
    cell.screenShotSize = item.cacheImage.imageSize;
    cell.screenShotKey = item.cacheImage.uuid;
    
    [item.cacheImage loadImage:^(UIImage *image) {
        if ([cell.screenShotKey isEqualToString:item.cacheImage.uuid])
        {
            cell.screenShot = image;
        }
    }];
    
    cell.mainColor = [self growingColorWithEventType:mainEventType];
    cell.preTitle =  [self showTimeWithNowDate:self.showTimeinterval
                                      itemDate:item.timeInterval];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GrowingEventListItem *item = self.items[indexPath.row];
    
    GrowingEventListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell)
    {
        cell = [[GrowingEventListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    [self fillCell:cell withItem:item];
    return cell;
}

- (NSString*)growingTypeNameWithEventType:(GrowingEventType)type
{
    NSString *string[] = {  @"未知",
                            @"APP状态",
                            @"页面切换",
                            @"用户行为",
                            @"UI更新",
                            @"网络访问"};
    return string[type];
}

- (UIColor*)growingColorWithEventType:(GrowingEventType)type
{
    return [GrowingUIConfig colorWithEventType:type];
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GrowingEventListItem *item = [self.items objectAtIndex:indexPath.row];
    if (![self isShowItem:item])
    {
        return;
    }
    GrowingCircleListAddTagViewController *vc =
    [[GrowingCircleListAddTagViewController alloc] initWithItem:item];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
