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


#import "GrowingCircleListAddTagViewController.h"
#import "GrowingUIConfig.h"
#import "GrowingChildContentPanel.h"

#import "GrowingEventListAction.h"
#import "NSData+GrowingHelper.h"

typedef NS_ENUM(NSInteger,GCLATVCTableType)
{
    GCLATVCTableTypeLine,
    GCLATVCTableTypeBar,
    GCLATVCTableTypeCount
};

@interface GrowingCircleListAddTagViewController ()
@property (nonatomic, retain) GrowingEventListItem *item;
@property (nonatomic, retain) NSMutableDictionary *tableDict;
@property (nonatomic, retain) UIView *curTableView;
@property (nonatomic, retain) NSArray *typeArray;
@end

@implementation GrowingCircleListAddTagViewController

- (instancetype)initWithItem:(GrowingEventListItem *)item
{
    self = [self init];
    if (self)
    {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.item = item;
        self.tableDict = [[NSMutableDictionary alloc] init];
        self.barColor = [UIColor whiteColor];
        self.barTextColor = [C_R_G_B(141,205,250) colorWithAlpha:0.9 backgroundColor:[UIColor blackColor]];
        [self buildTitleView];
    }
    return self;
}

- (void)buildTitleView
{
    id <GrowingEventListAction> action = GrowingEventListActionForEventType(self.item.eventType);
    BOOL hasBarChart = [action eventlist_item:self.item canShowWithStyle:GrowingChildContentPanelStyleBar];
    
    if (hasBarChart)
    {
        self.typeArray = @[@(GCLATVCTableTypeBar),@(GCLATVCTableTypeLine)];
        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"柱图指标",@"线图指标"]];
        seg.frame = CGRectMake(0, 0, 180, 31);
        self.navigationItem.titleView = seg;
        
        
        seg.tintColor = C_R_G_B(141,205,250);
        [seg setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],
                                      NSForegroundColorAttributeName:[UIColor whiteColor]}
                           forState:UIControlStateSelected];
        
        [seg setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],
                                      NSForegroundColorAttributeName:seg.tintColor}
                           forState:UIControlStateNormal];
        
        
        seg.selectedSegmentIndex = 0;
        [self selectIndex:0];
        [seg addTarget:self action:@selector(selectDidChange:) forControlEvents:UIControlEventValueChanged];
    }
    else
    {
        self.typeArray = @[@(GCLATVCTableTypeLine)];
        [self selectIndex:0];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = C_R_G_B(197,219,234);
}

- (void)selectIndex:(NSInteger)index
{
    GCLATVCTableType type = [self.typeArray[index] integerValue];
    if (self.curTableView)
    {
        self.curTableView.hidden = YES;
        self.curTableView = nil;
    }
    
    NSString *nextViewKey = [[NSString alloc] initWithFormat:@"%d",(int)type];
    
    UIView *nextView = self.tableDict[nextViewKey];
    if (nextView)
    {
        
        nextView.hidden = NO;
    }
    else
    {
        nextView = [self createTableView:type];
        [self.view addSubview:nextView];
        self.tableDict[nextViewKey] = nextView;
    }
    
    self.curTableView = nextView;
}

- (GrowingChildContentPanelStyle)styleForStyle:(GCLATVCTableType)type
{
    if (type == GCLATVCTableTypeLine)
    {
        return GrowingChildContentPanelStyleLine;
    }
    else
    {
        return GrowingChildContentPanelStyleBar;
    }
}

- (void)alertTextBoxWithTitle:(NSString*)title
                         text:(NSString*)text
                  placeHolder:(NSString*)placeHolder
                     onFinish:(void(^)(NSString *text, BOOL succeed))onfinish
{
    __block UITextField *textFiled = nil;
    
    GrowingMenuButton *btnCancel = [GrowingMenuButton buttonWithTitle:@"取消" block:^{
        if (onfinish)
        {
            onfinish(nil, NO);
        }
    }];
    GrowingMenuButton *btnOK = [GrowingMenuButton buttonWithTitle:@"保存" block:^{
        if (onfinish)
        {
            onfinish(textFiled.text,YES);
        }
    }];
    
    GrowingAlertMenu *menu = [GrowingAlertMenu alertWithTitle:title
                                                         text:nil
                                                      buttons:@[btnCancel,btnOK]];
    menu.preferredContentHeight = 60;
    menu.navigationBarColor = [GrowingUIConfig circleListMainColor];
    
    [menu.view growAddViewWithColor:nil block:^(MASG3ConstraintMaker *make, UIView *view) {
        make.left.offset(20);
        make.right.offset(-20);
        make.height.masG3_equalTo(30);
        make.centerY.offset(0);
        
        view.layer.borderWidth = 1;
        view.layer.borderColor = [GrowingUIConfig sublineColor].CGColor;
        view.layer.cornerRadius = 4;
    }];
    
    textFiled =
    [menu.view growAddSubviewClass:[UITextField class]
                             block:^(MASG3ConstraintMaker *make, UITextField *textFiled) {
                                 make.left.offset(30);
                                 make.right.offset(-30);
                                 make.top.offset(0);
                                 make.bottom.offset(0);
                                 textFiled.textAlignment = NSTextAlignmentCenter;
                                 textFiled.text = text;
                                 textFiled.placeholder = placeHolder;
                                 @weakify(textFiled);
                                 [textFiled setGrowingHelper_onTextChange:^{
                                     @strongify(textFiled);
                                     btnOK.userInteractionEnabled = textFiled.text.length != 0;
                                 }];
                             }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [textFiled becomeFirstResponder];
    });
}

- (void)savePane:(GrowingChildContentPanel*)thePanel
            name:(NSString *)name
     origElement:(GrowingElement*)orig
   filterElement:(GrowingElement*)filter
{
    void (^onFinish)(NSString*,BOOL) =
    ^(NSString *text, BOOL succeed) {
        if (!succeed)
        {
            return;
        }
        else
        {
            GrowingAlertMenu *alertMenu = [GrowingAlertMenu alertWithTitle:@"正在保存" text:nil buttons:nil];
            @weakify(alertMenu)
            GROWNetworkSuccessBlock succeedBlock = ^(NSHTTPURLResponse *httpResponse, NSData *responseData) {
                GrowingEventDataBase *db = [GrowingEventDataBase databaseWithName:@"TagWasSavedSuccessfully"];
                NSString *flag = [db valueForKey:@"displayed"];
                if (!flag.length)
                {
                    GrowingMenuButton * button =
                    [GrowingMenuButton buttonWithTitle:@"知道了"
                                                 block:^() {
                                                     [db setValue:@"YES"
                                                           forKey:@"displayed"];
                                                     @strongify(alertMenu)
                                                     [alertMenu hide];
                                                 }];
                    GrowingAlertMenu * alert =
                    [GrowingAlertMenu alertWithTitle:@"标签保存成功"
                                                text:@"请在GrowingIO网站的\n“标签管理”中查看"
                                             buttons:@[button]];
                    [alert show];
                }
                else
                {
                    @strongify(alertMenu)
                    [alertMenu hide];
                }
            };
            
            GROWNetworkFailureBlock failBlock = ^(NSHTTPURLResponse *httpResponse,
                                                  NSData *responseData,
                                                  NSError *error) {
                
                @strongify(alertMenu);
                [alertMenu hide];
                NSString *errmess = error.localizedDescription;
                if (!errmess)
                {
                    errmess = error.description;
                }
                if (!errmess)
                {
                    NSDictionary *dict = [responseData growingHelper_jsonObject];
                    if ([dict isKindOfClass:[NSDictionary class]])
                    {
                        errmess = dict[@"error"];
                    }
                }
                if(!errmess)
                {
                    errmess = httpResponse.statusCode != 200
                    ? [NSString stringWithFormat:@"httperror:%d",(int)httpResponse.statusCode]
                    :nil;
                }
                
                if (errmess.length == 0)
                {
                    errmess = @"该标签保存失败，请稍后重试";
                }
                
                GrowingMenuButton * button = [GrowingMenuButton buttonWithTitle:@"知道了" block:nil];
                GrowingAlertMenu * alert = [GrowingAlertMenu alertWithTitle:@"标签保存失败" text:errmess buttons:@[button]];
                [alert show];
            };
            
            [[GrowingLocalCircleModel sdkInstance] addOrUpdateTagById:nil
                                                                 name:text
                                                          origElement:orig
                                                        filterElement:filter
                                                            viewImage:nil
                                                          screenImage:nil
                                                             viewRect:CGRectZero
                                                              succeed:succeedBlock
                                                                 fail:failBlock];
        }
    };
    
    [self alertTextBoxWithTitle:@"请输入标签名"
                           text:nil
                    placeHolder:[NSString stringWithFormat:@"例:%@",name]
                       onFinish:onFinish];
    
}

- (UIView*)createTableView:(GCLATVCTableType)type
{
    @weakify(self);
    GrowingChildContentPanel *panel = [[GrowingChildContentPanel alloc] initWithFrame:self.view.bounds];
    [panel setOnSaveElement:^(GrowingChildContentPanel *panel,
                              NSString *name,
                              GrowingElement *origElement,
                              GrowingElement *filterElement)
     {
         @strongify(self);
         [self savePane:panel
                   name:name
            origElement:origElement
          filterElement:filterElement];
     }];
    id <GrowingEventListAction> action = GrowingEventListActionForEventType(self.item.eventType);
    GrowingChildContentPanelStyle style = [self styleForStyle:type];
    if ([action eventlist_item:self.item canShowWithStyle:style])
    {
        [action eventlist_addElementFromItem:self.item
                        chartStyle:style
                          forPanel:panel];
    }
    
    return panel;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.curTableView.frame = CGRectMake(0,
                                         self.topLayoutGuide.length,
                                         self.view.bounds.size.width,
                                         self.view.bounds.size.height - self.topLayoutGuide.length);
}

- (void)selectDidChange:(UISegmentedControl*)seg
{
    [self selectIndex:seg.selectedSegmentIndex];
}

@end
