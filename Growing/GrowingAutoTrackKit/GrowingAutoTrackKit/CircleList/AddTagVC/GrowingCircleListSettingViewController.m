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


#import "GrowingCircleListSettingViewController.h"
#import "GrowingUIConfig.h"
#import "GrowingEventListMenu.h"
#import "GrowingCircleListController.h"


@interface GCLSVCCell : UITableViewCell

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) BOOL showSwitch;
@property (nonatomic, assign) BOOL switchOn;

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *subTitleLabel;
@property (nonatomic, retain) UISwitch *switchView;

@property (nonatomic, weak) UITableView *tableView;
@end

@implementation GCLSVCCell

- (void)setSubtitle:(NSString *)subtitle
{
    self.subTitleLabel.text = subtitle;
}

- (NSString*)subtitle
{
    return self.subTitleLabel.text;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (NSString*)title
{
    return self.titleLabel.text;
}

- (void)setSwitchOn:(BOOL)switchOn animated:(BOOL)animated
{
    [self.switchView setOn:switchOn animated:animated];
}

- (void)setSwitchOn:(BOOL)switchOn
{
    [self setSwitchOn:switchOn animated:NO];
}

- (BOOL)switchOn
{
    return self.switchView.on;
}

- (void)setShowSwitch:(BOOL)showSwitch
{
    self.switchView.hidden = !showSwitch;
}

- (BOOL)showSwitch
{
    return self.switchView.hidden;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UILabel *lbl = [[UILabel alloc] init];
        lbl.font = [UIFont systemFontOfSize:13];
        self.titleLabel = lbl;
        lbl.textColor = C_R_G_B(36,48,69);
        [self.contentView addSubview:lbl];
        
        
        UILabel *lbl2 = [[UILabel alloc] init];
        lbl2.font = [UIFont systemFontOfSize:13];
        lbl2.textColor = C_R_G_B(110, 127, 143);
        self.subTitleLabel = lbl2;
        [self.contentView addSubview:lbl2];
        
        UIView *subLine= [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1)];
        [self.contentView addSubview:subLine];
        subLine.backgroundColor = C_R_G_B(234, 234, 234);
        subLine.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        UISwitch *sw = [[UISwitch alloc] init];
        sw.tintColor = sw.onTintColor = [GrowingUIConfig mainColor];
        self.switchView = sw;
        self.switchView.userInteractionEnabled = NO;
        [self.contentView addSubview:sw];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(15, 19, self.bounds.size.width - 30, 20);
    self.titleLabel.center = CGPointMake(self.bounds.size.width / 2, 19);
    
    self.subTitleLabel.frame = CGRectMake(15, 19, self.bounds.size.width - 30, 20);
    self.subTitleLabel.center = CGPointMake(self.bounds.size.width / 2, 47);
    
    self.switchView.center = CGPointMake(self.bounds.size.width - 38, 20);
}

@end


@interface GrowingCircleListSettingViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, retain) NSArray *items;
@end

@implementation GrowingCircleListSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    self.view.backgroundColor = [UIColor whiteColor];
    UITableView *t = [[UITableView alloc] initWithFrame:self.view.bounds];
    t.backgroundColor = C_R_G_B(234, 234, 234);
    t.separatorStyle = UITableViewCellSeparatorStyleNone;
    t.delegate = self;
    t.dataSource = self;
    [self.view addSubview:t];
    [t registerClass:[GCLSVCCell class] forCellReuseIdentifier:@"cell"];
    
    self.items = @[
                   
                   @[
                       
                       @[@"APP状态",@"是否展示APP启动/APP进入后台等信息",@(GrowingEventTypeAppLifeCycle)],
                       
                       
                       @[@"页面切换",@"是否展示页面显示信息(PV)",@(GrowingEventTypePage)],
                       
                       
                       @[@"用户行为",@"是否展示用户的点击/长按等操作",@(GrowingEventTypeUserInteraction)],
                       
                       
                       @[@"界面更新",@"是否展示文本的显示/隐藏/更改等信息",@(GrowingEventTypeUI)]
                       
                    ]
                   ,
                   
                   @[
                       
                       @[@"清空事件列表",@"重置现在有的事件列表,并根据您的操作重新收集",@(GrowingEventTypeNotInit),^{
                           
                           NSArray *actions =
                           @[@"确认", ^{
                               [GrowingEventListMenu clearAllEvent];
                               [GrowingEventListMenu hide];
                               [self.navigationController popViewControllerAnimated:NO];
                           },@"取消",^{
                           }];
                           [GrowingAlertMenu alertWithActionArray:actions
                                                           config:^(GrowingAlertMenu *menu) {
                                                               menu.text = @"要清空本地的事件记录吗?";
                                                               menu.navigationBarHidden = YES;
                                                               menu.view.backgroundColor = C_R_G_B(240, 240, 240);
                                                           }];
                           
                       }]
                    ]
                   ];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.items[section] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GCLSVCCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.tableView = tableView;
    NSArray *item = [self.items[indexPath.section] objectAtIndex:indexPath.row];
    cell.title = item[0];
    cell.subtitle = item[1];
    
    NSInteger event = [item[2] integerValue];
    
    if (event != 0)
    {
        cell.showSwitch = YES;
        cell.switchOn = [GrowingCircleListController isEventShow:event];
    }
    else
    {
        cell.showSwitch = NO;
        cell.switchOn = NO;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GCLSVCCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSArray *item = [self.items[indexPath.section] objectAtIndex:indexPath.row];
    
    NSInteger event = [item[2] integerValue];
    if (event != 0)
    {
        BOOL on = !cell.switchOn;
        [cell setSwitchOn:on animated:YES];
        if (on)
        {
            [GrowingCircleListController showEventType:event];
        }
        else
        {
            [GrowingCircleListController hideEventType:event];
        }
    }
    
    if (item.count >= 4 )
    {
        void (^block)() = item[3];
        block();
    }
}



@end
