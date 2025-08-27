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


#import <objc/runtime.h>
#import "GrowingLocalCircleWindow.h"
#import "UIView+Growing.h"
#import "GrowingLocalCircleModel.h"
#import "GrowingAddTagMenu.h"
#import "UIView+GrowingHelper.h"
#import "GrowingLineChartView.h"
#import "UIWindow+Growing.h"
#import "UIWindow+GrowingNode.h"
#import "GrowingUserDefaults.h"
#import "GrowingLoginModel.h"
#import "GrowingInstance.h"
#import "GrowingMenu.h"
#import "GrowingStatusBar.h"

#import "GrowingAddTagMenu.h"
#import "GrowingNodeManager.h"
#import "UIWindow+GrowingNode.h"
#import "UIViewController+GrowingNode.h"
#import "GrowingAlertMenu.h"
#import "UIViewController+Growing.h"
#import "UIApplication+GrowingNode.h"
#import "UIApplication+GrowingHelper.h"
#import "GrowingNode.h"
#import "GrowingAttributesConst.h"
#import "GrowingTaggedViews.h"

#import "FoSwizzling.h"
#import "GrowingHelperMenu.h"
#import "GrowingUIConfig.h"
#import "GrowingDeviceInfo.h"
#import "GrowingEventDataBase.h"
#import "UIWindow+Growing.h"
#import "UIWindow+GrowingNode.h"
#import "GrowingJavascriptCore.h"
#import "FoWeakObjectShell.h"
#import "NSString+GrowingHelper.h"
#import "GrowingWebSocket.h"
#import "GrowingHeatMapManager.h"
#import "GrowingGlobal.h"

#define SCREENSHOT_SCALE 2

@interface GrowingCircleNodeManager : GrowingNodeManager

- (instancetype)initWithNodeAndParent:(id<GrowingNode>)aNode;

@end

@implementation GrowingCircleNodeManager

- (instancetype)initWithNodeAndParent:(id<GrowingNode>)aNode
{
    if (!aNode)
    {
        return nil;
    }
    
    static BOOL(^checkBlock)(id<GrowingNode> node) = ^BOOL(id<GrowingNode> node) {
        return ![node growingNodeDonotCircle];
    };
    
    return [self initWithNodeAndParent:aNode checkBlock:checkBlock];
}

@end

@interface _GrowingSettingMenuAlertView : GrowingMenuPageView

@end

@implementation _GrowingSettingMenuAlertView

+ (void)show
{
    _GrowingSettingMenuAlertView *view = [[_GrowingSettingMenuAlertView alloc] initWithType:GrowingMenuShowTypeAlert];
    [view show];
}

- (instancetype)initWithType:(GrowingMenuShowType)showType
{
    self = [super initWithType:showType];
    if (self)
    {
        __weak _GrowingSettingMenuAlertView *wself = self;
        NSArray *btns =
        @[
          [GrowingMenuButton buttonWithTitle:@"返回圈选"
                                       block:^{
                                           [wself hide];
                                       }],
          [GrowingMenuButton buttonWithTitle:@"退出圈选"
                                       block:^{
                                           [GrowingTaggedViews shareInstance].shouldDisplayTaggedViews = NO;
                                           [wself hide];
                                           [GrowingInstance setCircleType:GrowingCircleTypeNone];
                                           [[GrowingLoginModel sdkInstance] logout];
                                       }]
          ];
        self.menuButtons = btns;
        self.title = @"圈选";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILongPressGestureRecognizer *longpress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(longPress:)];
    longpress.numberOfTouchesRequired = 3;
    longpress.minimumPressDuration = 5;
    [self.view addGestureRecognizer:longpress];
    
    _GrowingSettingMenuAlertView * wself = self;
    __block UIView * lastView = nil;

    self.preferredContentHeight = 195;

    
#if 0
    UIViewController * currentVC = [[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController];
    NSString * currentPageName = [currentVC GROW_pageTitle];
    if (!currentPageName.length)
    {
        currentPageName = [currentVC GROW_pageName];
    }
    NSString * taggedPageName = [[GrowingLocalCircleModel sdkInstance] getControllerTagedName:currentPageName];
    BOOL isPageTagged = (taggedPageName.length > 0);

    UIView * containerOfPageDefine =
    [self.view growAddViewWithColor:[UIColor clearColor] block:^(MASG3ConstraintMaker *make, UIView *view) {
        make.left.offset(15);
        make.right.offset(-15);
        make.top.offset(14);
        lastView = view;
    }];

    
    __block UIView * lastCirclePageButton = nil;
    [containerOfPageDefine growAddButtonWithTitle:isPageTagged ? @"已定义" : @"定义"
                                            color:isPageTagged ? [GrowingUIConfig textColorDisabled] : [GrowingUIConfig textColor]
                                          onClick:^{
                                              [wself hide];
                                              [GrowingLocalCircleWindow circlePage];
                                          } block:^(MASG3ConstraintMaker *make, UIButton *button) {
                                              make.right.offset(0);
                                              make.width.offset(60);
                                              make.top.offset(0);
                                              make.height.offset(32);
                                              make.bottom.masG3_lessThanOrEqualTo(containerOfPageDefine.masG3_bottom);
                                              button.backgroundColor = (isPageTagged ? [GrowingUIConfig textColorDisabled] : [GrowingUIConfig mainColor]);
                                              button.userInteractionEnabled = !isPageTagged;
                                              button.enabled = !isPageTagged;
                                              button.layer.cornerRadius = 4;
                                              [button setTitleColor:[UIColor whiteColor] forState:0];
                                              lastCirclePageButton = button;
                                          }];
    UILabel * titleOfCirclePageButton =
    [containerOfPageDefine growAddLabelWithFontSize:16
                                              color:[GrowingUIConfig textColorDisabled]
                                              lines:0
                                               text:@"当前页面："
                                              block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                                  make.left.offset(0);
                                                  make.width.offset(80);
                                                  make.height.masG3_equalTo(lastCirclePageButton.masG3_height);
                                                  make.centerY.masG3_equalTo(lastCirclePageButton.masG3_centerY);
                                                  make.bottom.masG3_lessThanOrEqualTo(containerOfPageDefine.masG3_bottom);
                                                  lable.textAlignment = NSTextAlignmentRight;
                                              }];
    [containerOfPageDefine growAddLabelWithFontSize:16
                                              color:[GrowingUIConfig textColor]
                                              lines:0
                                               text:(isPageTagged ? taggedPageName : currentPageName)
                                              block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                                  make.left.masG3_equalTo(titleOfCirclePageButton.masG3_right);
                                                  make.right.masG3_equalTo(lastCirclePageButton.masG3_left).offset(-16);
                                                  make.height.masG3_equalTo(lastCirclePageButton.masG3_height);
                                                  make.centerY.masG3_equalTo(lastCirclePageButton.masG3_centerY);
                                                  make.bottom.masG3_lessThanOrEqualTo(containerOfPageDefine.masG3_bottom);
                                              }];

    NSMutableArray<NSDictionary *> * h5PageArray = [[NSMutableArray alloc] init];
    __block UIImage * screenshot = nil;
    __block int waitingCallbacks = 0;

    GrowingNodeManager * manager = [[GrowingNodeManager alloc] initWithNodeAndParent:[GrowingRootNode rootNode]
                                                                          checkBlock:nil];
    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode, GrowingNodeManagerEnumerateContext *context) {
        id<GrowingNodeAsyncNativeHandler> asyncNativeHandler = [aNode growingNodeAsyncNativeHandler];
        if (asyncNativeHandler != nil)
        {
            waitingCallbacks++;
            [asyncNativeHandler getPageInfoWithCallback:^(NSDictionary *pageData) {
                if (pageData.count > 0)
                {
                    
                    NSString * currentPageName = pageData[@"v"];
                    if (currentPageName.length == 0)
                    {
                        currentPageName = pageData[@"d"];
                    }
                    NSMutableDictionary * jointPageData = [[NSMutableDictionary alloc] initWithCapacity:pageData.count];
                    if ([(NSString *)pageData[@"d"] length] > 0)
                    {
                        jointPageData[@"d"] = [GrowingJavascriptCore jointField:[GrowingDeviceInfo currentDeviceInfo].bundleID
                                                                withField:(NSString *)pageData[@"d"]];
                    }
                    if ([(NSString *)pageData[@"p"] length] > 0)
                    {
                        jointPageData[@"p"] = [GrowingJavascriptCore jointField:currentVC.growingNodeDataDict[@"p"]
                                                                      withField:(NSString *)pageData[@"p"]];
                    }
                    jointPageData[@"q"] = pageData[@"q"];
                    jointPageData[@"v"] = currentPageName;
                    NSString * taggedPageName = [[GrowingLocalCircleModel sdkInstance] getH5TagedName:jointPageData];
                    BOOL isPageTagged = (taggedPageName.length > 0);
                    NSString * displayPageName = ((isPageTagged ? taggedPageName : currentPageName) ?: @"");
                    if (screenshot == nil)
                    {
                        screenshot = [[UIApplication sharedApplication] growingHelper_screenshotWithGrowingWindow:SCREENSHOT_SCALE];
                    }
                    [h5PageArray addObject:@{@"pageData": jointPageData,
                                             @"displayTitle": displayPageName,
                                             @"node": aNode,
                                             @"screenshot": screenshot}];
                }
                waitingCallbacks--;
                if (waitingCallbacks == 0 && h5PageArray.count >= 1)
                {
                    [containerOfPageDefine growAddButtonWithTitle:@"定义"
                                                            color:[GrowingUIConfig textColor]
                                                          onClick:^{
                                                              [wself hide];
                                                              [GrowingLocalCircleWindow circleH5Pages:h5PageArray];
                                                          } block:^(MASG3ConstraintMaker *make, UIButton *button) {
                                                              make.right.offset(0);
                                                              make.width.offset(60);
                                                              make.top.masG3_equalTo(lastCirclePageButton.masG3_bottom).offset(14);
                                                              make.height.offset(32);
                                                              make.bottom.masG3_lessThanOrEqualTo(containerOfPageDefine.masG3_bottom);
                                                              button.backgroundColor = [GrowingUIConfig mainColor];
                                                              button.layer.cornerRadius = 4;
                                                              [button setTitleColor:[UIColor whiteColor] forState:0];
                                                              lastCirclePageButton = button;
                                                          }];
                    UILabel * titleOfCirclePageButton =
                    [containerOfPageDefine growAddLabelWithFontSize:16
                                                              color:[GrowingUIConfig textColorDisabled]
                                                              lines:0
                                                               text:@"H5页面："
                                                              block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                                                  make.left.offset(0);
                                                                  make.width.offset(80);
                                                                  make.height.masG3_equalTo(lastCirclePageButton.masG3_height);
                                                                  make.centerY.masG3_equalTo(lastCirclePageButton.masG3_centerY);
                                                                  make.bottom.masG3_lessThanOrEqualTo(containerOfPageDefine.masG3_bottom);
                                                                  lable.textAlignment = NSTextAlignmentRight;
                                                              }];
                    [containerOfPageDefine growAddLabelWithFontSize:16
                                                              color:[GrowingUIConfig textColor]
                                                              lines:0
                                                               text:(h5PageArray.count == 1 ? h5PageArray.lastObject[@"displayTitle"] : @"多个页面")
                                                              block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                                                  make.left.masG3_equalTo(titleOfCirclePageButton.masG3_right);
                                                                  make.right.masG3_equalTo(lastCirclePageButton.masG3_left).offset(-16);
                                                                  make.height.masG3_equalTo(lastCirclePageButton.masG3_height);
                                                                  make.centerY.masG3_equalTo(lastCirclePageButton.masG3_centerY);
                                                                  make.bottom.masG3_lessThanOrEqualTo(containerOfPageDefine.masG3_bottom);
                                                              }];
                    wself.preferredContentHeight += 32 + 14;
                    [wself.view setNeedsLayout];
                }
            }];
        }
    }];

    
    [self.view growAddViewWithColor:[GrowingUIConfig separatorLineColor]
                              block:^(MASG3ConstraintMaker *make, UIView *view) {
                                  make.top.masG3_equalTo(containerOfPageDefine.masG3_bottom).offset(13);
                                  make.height.offset(1);
                                  make.left.offset(16);
                                  make.right.offset(16);
                                  lastView = view;
                              }];

    
#endif 

    
    UISwitch * switchShouldDisplayTaggedView =
    [self.view growAddSubviewClass:[UISwitch class]
                             block:^(MASG3ConstraintMaker *make, id obj) {
                                 make.right.offset(-15);
                                 make.top.offset(14);
                                 UISwitch * s = obj;
                                 s.tintColor = [GrowingUIConfig mainColor];
                                 s.onTintColor = [GrowingUIConfig mainColor];
                                 [s addTarget:wself
                                       action:@selector(actionForSwitchShouldDisplayTaggedView:)
                             forControlEvents:UIControlEventValueChanged];
                                 s.on = [GrowingHeatMapManager isStart];
                                 lastView = obj;
                             }];
    [self.view growAddLabelWithFontSize:16
                                  color:[GrowingUIConfig textColor]
                                  lines:0
                                   text:@"显示热图"
                                  block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                      make.left.offset(15);
                                      make.right.masG3_equalTo(switchShouldDisplayTaggedView.masG3_left).offset(-16);
                                      make.height.masG3_equalTo(switchShouldDisplayTaggedView.masG3_height);
                                      make.centerY.masG3_equalTo(switchShouldDisplayTaggedView.masG3_centerY);
                                      lastView = lable;
                                  }];

    
    UIView *topLineView =
    [self.view growAddViewWithColor:[GrowingUIConfig separatorLineColor]
                              block:^(MASG3ConstraintMaker *make, UIView *view) {
                                  make.top.masG3_equalTo(switchShouldDisplayTaggedView.masG3_bottom).offset(14);
                                  make.height.offset(1);
                                  make.left.offset(16);
                                  make.right.offset(16);
                                  lastView = view;
                              }];
    
    
    UISwitch * switchShouldShowTaggedView =
    [self.view growAddSubviewClass:[UISwitch class]
                             block:^(MASG3ConstraintMaker *make, id obj) {
                                 make.right.offset(-15);
                                 make.top.masG3_equalTo(topLineView.masG3_bottom).offset(14);
                                 UISwitch * s = obj;
                                 s.tintColor = [GrowingUIConfig mainColor];
                                 s.onTintColor = [GrowingUIConfig mainColor];
                                 [s addTarget:wself
                                       action:@selector(actionForSwitchShouldShowTaggedView:)
                             forControlEvents:UIControlEventValueChanged];
                                 s.on = [GrowingTaggedViews shareInstance].shouldDisplayTaggedViews;
;
                                 lastView = obj;
                             }];
    
    [self.view growAddLabelWithFontSize:16
                                  color:[GrowingUIConfig textColor]
                                  lines:0
                                   text:@"显示已圈选"
                                  block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                      make.left.offset(15);
                                      make.right.masG3_equalTo(switchShouldShowTaggedView.masG3_left).offset(-16);
                                      make.height.masG3_equalTo(switchShouldShowTaggedView.masG3_height);
                                      make.centerY.masG3_equalTo(switchShouldShowTaggedView.masG3_centerY);
                                      lastView = lable;
                                  }];
    
    
    [self.view growAddViewWithColor:[GrowingUIConfig separatorLineColor]
                              block:^(MASG3ConstraintMaker *make, UIView *view) {
                                  make.top.masG3_equalTo(switchShouldShowTaggedView.masG3_bottom).offset(14);
                                  make.height.offset(1);
                                  make.left.offset(16);
                                  make.right.offset(16);
                                  lastView = view;
                              }];

    
    NSString * prompt = @"提示：拖动小红点进行圈选";
    CGSize promptSize = [prompt sizeWithFont:[UIFont systemFontOfSize:11] constrainedToSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    UIView * leftPaddingView =
    [self.view growAddViewWithColor:[UIColor clearColor]
                              block:^(MASG3ConstraintMaker *make, UIView *view) {
                                  make.left.offset(0);
                              }];
    UIView * rightPaddingView =
    [self.view growAddViewWithColor:[UIColor clearColor]
                              block:^(MASG3ConstraintMaker *make, UIView *view) {
                                  make.right.offset(0);
                                  make.width.masG3_equalTo(leftPaddingView.masG3_width);
                              }];
    [self.view growAddLabelWithFontSize:11
                                  color:[GrowingUIConfig textColorDisabled]
                                  lines:1
                                   text:prompt
                                  block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                      make.top.masG3_equalTo(lastView.masG3_bottom).offset(23);
                                      make.height.masG3_equalTo(promptSize.height);
                                      make.left.masG3_equalTo(leftPaddingView.masG3_right);
                                      make.width.masG3_equalTo(promptSize.width);
                                      make.right.masG3_equalTo(rightPaddingView.masG3_left);
                                      lastView = lable;
                                  }];
    [self.view growAddLabelWithFontSize:11
                                  color:[GrowingUIConfig textColorDisabled]
                                  lines:1
                                   text:[NSString stringWithFormat:@"版本：%@", [Growing sdkVersion]]
                                  block:^(MASG3ConstraintMaker *make, UILabel *lable) {
                                      make.top.masG3_equalTo(lastView.masG3_bottom).offset(6);
                                      make.height.masG3_equalTo(lastView.masG3_height);
                                      make.left.masG3_equalTo(lastView.masG3_left);
                                      make.right.offset(0);
                                      lastView = lable;
                                  }];
}

- (void)longPress:(UILongPressGestureRecognizer*)gest
{
    if (gest.state == UIGestureRecognizerStateBegan)
    {
        GrowingDeviceInfo *info = [GrowingDeviceInfo currentDeviceInfo];
        NSMutableString *str = [[NSMutableString alloc] init];
        [str appendFormat:@"AI:\n%@\n",[GrowingInstance sharedInstance].accountID];
        [str appendFormat:@"BundleID:\n%@\n",info.bundleID];
        [str appendFormat:@"DeviceID:\n%@\n",info.deviceIDString];
        [str appendFormat:@"SDKVer:\n%@\n",[Growing sdkVersion]];
        
        [GrowingAlertMenu alertWithTitle:@"设备信息"
                                    text:str
                                 buttons:@[[GrowingMenuButton buttonWithTitle:@"复制"
                                                                        block:^{
                                                                            [UIPasteboard generalPasteboard].string = str;
                                                                        }] ,
                                           [GrowingMenuButton buttonWithTitle:@"取消"
                                                                        block:nil]
                                           ]];
        [self hide];
    }
}

- (void)actionForSwitchShouldDisplayTaggedView:(UISwitch*)sender
{
    if (sender.on)
    {
        [GrowingHeatMapManager start];
    }
    else
    {
        [GrowingHeatMapManager stop];
    }
}


- (void)actionForSwitchShouldShowTaggedView:(UISwitch *)sender
{
    if (sender.on) {
        [GrowingTaggedViews shareInstance].shouldDisplayTaggedViews = YES;
    } else {
        [GrowingTaggedViews shareInstance].shouldDisplayTaggedViews = NO;
    }
}

@end

#define PressAndHoldTimeThreshold 3
#define PressAndHoldVelocityThreshold 3

typedef NS_ENUM(NSUInteger, GrowingMultipleSelectionState)
{
    GrowingMultipleSelectionStateNone                 = 1,
    GrowingMultipleSelectionStateNotAList             = 2,
    GrowingMultipleSelectionStateListItemPreparation  = 3,
    GrowingMultipleSelectionStateListItem             = 4,
    GrowingMultipleSelectionStateListItemFinalize     = 5,
};

@interface GrowingLocalCircleItem : NSObject

@property (nonatomic, weak) id<GrowingNode> node;
@property (nonatomic, retain) NSMutableArray *childNodes;
@property (nonatomic, assign) BOOL doNotTrack;

@end

@implementation GrowingLocalCircleItem

@end

@interface GrowingLocalCircleWindow ()

@property (nonatomic, retain) UIPanGestureRecognizer *panGest;
@property (nonatomic, retain) NSArray<GrowingLocalCircleItem*> *lastItems;
@property (nonatomic, retain) NSMutableArray<GrowingLocalCircleItem*> *lastItemsMutable;

@property (nonatomic, retain) UITapGestureRecognizer *tapGest;

@property (nonatomic, assign) BOOL isStart;

@property (nonatomic, retain) UIView *buttonView;

@property (nonatomic, assign) NSInteger showCount;

@property (nonatomic, assign) BOOL isShow;

@property (nonatomic, retain) NSArray<GrowingTagItem*> *allTagItems;

@property (nonatomic, assign) CGRect keyboardBounds;

@property (nonatomic, retain) GrowingHelperMenu *helperMenu;

@property (nonatomic, weak) GrowingTaggedViews * growingTaggedViews;

@property (nonatomic, retain) NSMapTable<NSValue *, UIView *> * allMaskViews;

- (void)updateSelectedMask:(NSArray<id<GrowingNode>> *)nodes doNotTrack:(BOOL)doNotTrack;

@property (nonatomic, retain) GROMagnifierView *magnifierViewForSmallItem;

@property (nonatomic, weak) UIWindow *growingKeyWindow;

@end


#define MOVE_ALPHA  0.2
#define DEFAULT_ALPHA 1
#define ICON_SIZE 60
#define BORDER_WIDTH 6

@implementation GrowingLocalCircleWindow

+ (void)show
{
    [self shareInstance].isShow = YES;
}

+ (BOOL)isShow
{
    return [self lookUpShareInstance].isShow;
}

+ (void)hidden
{
    [self lookUpShareInstance].isShow = NO;
}

+ (void)startCircle
{
    if ([self shareInstance].isStart)
    {
        return;
    }
    [self shareInstance].isStart = YES;
    
    [GrowingAddTagMenu sharedWebViewSingleton];
    
    
    [GrowingJavascriptCore startWebViewCircle];
}

+ (void)stopCircle
{
    [self lookUpShareInstance].isStart = NO;
}

+ (BOOL)hasStartCircle
{
    return [self lookUpShareInstance].isStart;
}

static id shareInstance = nil;
+ (GrowingLocalCircleWindow*)lookUpShareInstance
{
    return shareInstance;
}

+ (GrowingLocalCircleWindow*)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
        [shareInstance setGrowingViewLevel:3];
    });
    return shareInstance;
}

- (void)setIsShow:(BOOL)isShow
{
    if (_isShow == isShow)
    {
        return;
    }
    _isShow = isShow;
    if (isShow)
    {
        [self showButton];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didlogout)
                                                     name:GrowingDidLogout
                                                   object:[GrowingLoginModel sdkInstance]];
        
        __weak GrowingLocalCircleWindow *wself = self;
        [[GrowingLocalCircleModel sdkInstance] requestAllTagItemsSucceed:^(NSArray<GrowingTagItem *> *items) {
            wself.allTagItems = items;
        } fail:^(NSString *errorMsg) {
            
        }];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:GrowingDidLogout
                                                      object:[GrowingLoginModel sdkInstance]];
        [self hideButton];
    }
}

- (void)didlogout
{
    self.isStart = NO;;
}






- (BOOL)growingNodeDonotCircle
{
    return YES;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                UIViewAutoresizingFlexibleLeftMargin |
                                UIViewAutoresizingFlexibleRightMargin |
                                UIViewAutoresizingFlexibleBottomMargin;
        self.backgroundColor = [UIColor clearColor];
        self.frame = [UIScreen mainScreen].bounds;
        self.buttonView = [[UIView alloc] initWithFrame:CGRectMake(0,0,ICON_SIZE,ICON_SIZE)];
        self.buttonView.alpha = DEFAULT_ALPHA;
        self.buttonView.layer.cornerRadius = ICON_SIZE / 2;
        self.buttonView.layer.borderWidth = BORDER_WIDTH;
        self.buttonView.layer.borderColor = [GrowingUIConfig circleLightColor].CGColor;
        self.buttonView.backgroundColor = [UIColor clearColor];
        self.growingKeyWindow = [UIApplication sharedApplication].keyWindow;
        UIView * centerView = [[UIView alloc] initWithFrame:CGRectMake(BORDER_WIDTH, BORDER_WIDTH, ICON_SIZE - BORDER_WIDTH * 2, ICON_SIZE - BORDER_WIDTH * 2)];
        centerView.layer.backgroundColor = [GrowingUIConfig circleColor].CGColor;
        centerView.layer.cornerRadius = ICON_SIZE / 2 - BORDER_WIDTH;
        [self.buttonView addSubview:centerView];
        [self addSubview:self.buttonView];
        
        NSString *pointStr = [[GrowingUserDefaults shareInstance] valueForKey:@"GrowingLocalCircleCenter"];
        CGPoint centerPoint = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        if (pointStr.length)
        {
            centerPoint = CGPointFromString(pointStr);
        }
        [self setButtonCenter:centerPoint];
        
        self.panGest = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGest:)];
        [self.buttonView addGestureRecognizer:self.panGest];
        
        self.tapGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGest:)];
        [self.buttonView addGestureRecognizer:self.tapGest];
        
        self.isStart = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide:)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        self.keyboardBounds = CGRectMake(0, screenRect.size.height, screenRect.size.width, 0);

        self.growingTaggedViews = [GrowingTaggedViews shareInstance];

        self.allMaskViews = [[NSMapTable alloc] initWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory capacity:10];

        [self resetWindowFrame];
    }
    return self;
}

- (void)updateKeyboardFrame:(NSNotification *)notification
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
#endif
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2
        NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
#else
        NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
#endif
        [keyboardBoundsValue getValue:&_keyboardBounds];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
    }
#endif
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    [self updateKeyboardFrame:notification];
    [self resetWindowFrame];
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    if (self.growingKeyWindow) {
        [self.growingKeyWindow makeKeyWindow];
    }
    
    [self updateKeyboardFrame:notification];
    [self resetWindowFrame];
}

- (void)resetWindowFrame
{
    CGRect origFrame = self.frame;
    CGRect frame = self.buttonView.frame;
    frame.origin.x = MAX(origFrame.origin.x + 10, frame.origin.x);
    frame.origin.y = MAX(origFrame.origin.y + 50, frame.origin.y);
    frame.origin.x = MIN(origFrame.origin.x + origFrame.size.width - 10 - ICON_SIZE, frame.origin.x);
    frame.origin.y = MIN(origFrame.origin.y + origFrame.size.height - 10 - ICON_SIZE , frame.origin.y);

    
    if (frame.origin.y + frame.size.height + 10 > self.keyboardBounds.origin.y)
    {
        frame.origin.y = self.keyboardBounds.origin.y - 10 - ICON_SIZE;
    }

    [UIView animateWithDuration:0.25
                     animations:^{
                         self.buttonView.frame = frame;
                     }];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    self.frame = self.frame;
}

- (void)setButtonCenter:(CGPoint)center
{






    [self.buttonView setCenter:center];
}

- (void)checkView:(UIView *)view withHitPoint:(CGPoint)point andResult:(NSMutableArray<FoWeakObjectShell *> *)allHitViews
{
    if (view == nil)
    {
        return;
    }
    if ([view growingNodeDonotCircle])
    {
        return;
    }
    CGRect frame = [view growingNodeFrame];
    if (CGRectContainsPoint(frame, point))
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        if (   [[view growingNodeContent] length] > 0
            || [view growingNodeUserInteraction])
#pragma clang diagnostic pop
        {
            
            [allHitViews addObject:[FoWeakObjectShell weakObject:view]];
            return;
        }
        UIResponder * nextResponder = view.nextResponder;
        if ([view.nextResponder isKindOfClass:[UIViewController class]])
        {
            [allHitViews addObject:[FoWeakObjectShell weakObject:nextResponder]];
            return;
        }
    }
    
    for (UIView * sv in view.subviews)
    {
        [self checkView:sv withHitPoint:point andResult:allHitViews];
    }
}

- (NSArray<GrowingLocalCircleItem*>*)nodesForPoint:(CGPoint)point
{
    NSMutableArray<GrowingLocalCircleItem*> *lastNodeItems = [[NSMutableArray alloc] init];
    
    
    NSMutableArray<FoWeakObjectShell *> * allHitViews = [[NSMutableArray alloc] init];
    for (UIWindow * window in [[UIApplication sharedApplication] growingHelper_allWindowsSortedByWindowLevel])
    {
        [self checkView:window withHitPoint:point andResult:allHitViews];
    }
    
    for (NSInteger i = 0; i < allHitViews.count; i++)
    {
        id<GrowingNode> viewNode = allHitViews[i].obj;
        if (viewNode == nil)
        {
            continue;
        }

        NSMutableArray<GrowingLocalCircleItem*> *allButtonItems = [[NSMutableArray alloc] init];
        
        GrowingNodeManager *nodeManager = [[GrowingCircleNodeManager alloc] initWithNodeAndParent:viewNode];
        __block NSInteger doNotTrackCount = 0;
        [nodeManager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode,
                                                   GrowingNodeManagerEnumerateContext *context) {
            
            id<GrowingNodeAsyncNativeHandler> asyncNativeHandler = [aNode growingNodeAsyncNativeHandler];
            if (asyncNativeHandler != nil)
            {
                if (![aNode growingNodeDonotTrack] && [asyncNativeHandler isResponsive])
                {
                    if (CGRectContainsPoint([aNode growingNodeFrame], point))
                    {
                        [asyncNativeHandler setLastPoint:point];
                        GrowingLocalCircleItem *circleItem = [[GrowingLocalCircleItem alloc] init];
                        circleItem.node = aNode;
                        circleItem.doNotTrack = [aNode growingNodeDonotTrack];
                        [lastNodeItems insertObject:circleItem atIndex:0];
                    }
                }
                return;
            }
            CGRect frame = [aNode growingNodeFrame];
            int canClick = [aNode growingNodeUserInteraction] ? 1 : 0  ;
            int hasContent = [aNode growingNodeContent].length != 0  ? 2 : 0;
            if (hasContent == 0 &&
                ([aNode isKindOfClass:[UITextField class]]
                 || [aNode isKindOfClass:[UISearchBar class]]
                 || [aNode isKindOfClass:[UITextView class]])) {
                hasContent = 2;
            }
            int hitItem = CGRectContainsPoint(frame, point) ?  1 : 0 ;
            int hasButton = allButtonItems.count != 0  ? 2 : 0;
            
            int nodeState = canClick + hasContent;
            int addState = hitItem + hasButton;
            if (nodeState == 0 || addState == 0)
            {
                return;
            }
            
            static const int __unused nothing = 0;
            static const int button = 1 << 1;
            static const int child  = 1 << 2;
            static const int node   = 1 << 3;
            
            static const int actions[3][3] = {
                       
             { button|node ,       node,        button|node},
           { button ,            child,       button},
                { button|node ,       child,       button|node},
            };
            
            int action = actions[addState - 1][nodeState - 1];
            
            
            
            if ([aNode growingNodeDonotTrack])
            {
                doNotTrackCount ++;
                [context onNodeFinish:^(id<GrowingNode> node) {
                    doNotTrackCount --;
                }];
            }
            
            GrowingLocalCircleItem *item = [[GrowingLocalCircleItem alloc] init];
            item.node = aNode;
            item.doNotTrack = doNotTrackCount != 0;
        
            
            if (action & child)
            {
                NSMutableArray *childArr = allButtonItems.lastObject.childNodes;
                if (!childArr)
                {
                    childArr = [[NSMutableArray alloc] init];
                    allButtonItems.lastObject.childNodes = childArr;
                }
                GrowingLocalCircleItem *circleItem = [[GrowingLocalCircleItem alloc] init];
                circleItem.node = aNode;
                circleItem.doNotTrack = doNotTrackCount != 0;
                
                [childArr addObject:circleItem];
            }
            
            if (action & button)
            {
                [allButtonItems addObject:item];
                [context onNodeFinish:^(id<GrowingNode> node) {
                    [allButtonItems removeObject:item];
                }];
            }
            if (action & node)
            {
                [lastNodeItems insertObject:item atIndex:0];
            }
            
        }];
    }
    return lastNodeItems;
}

- (BOOL)thisNodeIsOneRowOfTableView:(id<GrowingNode>)node
{
    return [GrowingCircleNodeManager recursiveAttributeValueOfNode:node
                                                            forKey:GrowingAttributeIsWithinRowOfTableKey]
           == GrowingAttributeReturnYESKey;
}

- (void)panGest:(UIPanGestureRecognizer*)gest
{
    switch (gest.state)
    {
        case UIGestureRecognizerStateChanged:
        {
            [self setButtonCenter:[gest locationInView:self]];
            
            CGPoint point = [gest locationInView:[[UIApplication sharedApplication] growingMainWindow]];
            self.lastItems = [self nodesForPoint:point];
            
            
            if ([self.lastItems count] > 0) {
                id firstNode = [[self.lastItems firstObject] node];
                if ([firstNode isKindOfClass: [UIView class]]) {
                    UIView *view = (UIView *)firstNode;
                    CGSize viewSize = view.bounds.size;
                    
                    if ((view.frame.origin.x == INFINITY || view.frame.origin.y == INFINITY)
                        && CGSizeEqualToSize(view.frame.size, CGSizeZero)) {
                        return;
                    }
                    if ( viewSize.width < g_dimentionOfSmallItem
                        || viewSize.height < g_dimentionOfSmallItem) {
                        [self addMagnifierViewForSmallView:view withTouchPoint:point];
                    }
                    else
                    {
                        [self removeMagnifier];
                    }
                }
            }
            else
            {
                [self removeMagnifier];
            }
        }
            break;
        case UIGestureRecognizerStateBegan:
            [self hideHelper];
            self.growingTaggedViews.isPaused = YES;
            self.buttonView.alpha = MOVE_ALPHA;
            break;
        case UIGestureRecognizerStateEnded:
        {
            CGPoint point = self.buttonView.center;
            [[GrowingUserDefaults shareInstance] setValue:NSStringFromCGPoint(point)
                                                   forKey:@"GrowingLocalCircleCenter"];
            [self resetWindowFrame];
            self.buttonView.alpha = DEFAULT_ALPHA;

            self.lastItems = nil;
            [self removeMagnifier];

            CGPoint vel = [gest velocityInView:gest.view];
            if (hypotf(vel.x, vel.y) < 500)
            {
                [self performSelector:@selector(delayCirclePoint:)
                           withObject:[NSValue valueWithCGPoint:point]
                           afterDelay:0.01];
                
            }
            else
            {
                self.growingTaggedViews.isPaused = NO;
            }
        }
            break;
            
        default:
            self.lastItems = nil;
            break;
    }
}

- (void)addMagnifierViewForSmallView:(UIView *)smallItemView withTouchPoint: (CGPoint) touchPoint
{
    
    
    UIImage *snapshotImage = [self takeSnapshotOfMainWindowForTouchPoint: touchPoint];
    
    GROMagnifierPosition magnifierPosition;
    CGFloat smallItemViewTopSpace = [smallItemView convertPoint: smallItemView.frame.origin toView: self].y;
    CGFloat smallItemViewCenterToLeft = [smallItemView.superview convertPoint: smallItemView.center toView: self].x;
    CGFloat smallItemViewCenterToRight = self.frame.size.width - [smallItemView.superview convertPoint: smallItemView.center toView: self].x;
    if (smallItemViewTopSpace < g_magnifierHeight * 1.2)
    {
        magnifierPosition = smallItemView.frame.origin.x < g_magnifierWidth * 1.2 ? Right : Left;
    }
    else if (smallItemViewCenterToLeft < g_magnifierWidth / 2)
    {
        magnifierPosition = Right;
    }
    else if (smallItemViewCenterToRight < g_magnifierWidth / 2)
    {
        magnifierPosition = Left;
    }
    else {
        magnifierPosition = Above;
    }
    
    UIColor *magnifierBorderColor = [UIColor colorWithRed:0.87 green:0.87 blue:0.87 alpha:1.00];
    if (!self.magnifierViewForSmallItem)
    {
        self.magnifierViewForSmallItem = [GROMagnifierView magnifierViewWithSnapshotImage:snapshotImage position:magnifierPosition borderColro:magnifierBorderColor];
    }
    else
    {
        [self.magnifierViewForSmallItem refreshWithSnapshotImage:snapshotImage position:magnifierPosition];
    }
    
    CGPoint centerOfSmallItemView = [smallItemView.superview convertPoint: smallItemView.center toView: self];
    CGFloat smallItemViewWidth = smallItemView.bounds.size.width;
    CGFloat smallItemViewHeight = smallItemView.bounds.size.height;
    CGFloat magnifierViewWidth = self.magnifierViewForSmallItem.bounds.size.width;
    CGFloat magnifierViewHeight = self.magnifierViewForSmallItem.bounds.size.height;
    
    
    switch (magnifierPosition) {
        case Above:
            [self.magnifierViewForSmallItem setCenter:
             CGPointMake(centerOfSmallItemView.x,
                         centerOfSmallItemView.y - (smallItemViewHeight + magnifierViewHeight ) / 2)];
            break;
        case Right:
            [self.magnifierViewForSmallItem setCenter:
             CGPointMake(centerOfSmallItemView.x + (smallItemViewWidth + magnifierViewWidth ) / 2,
                         centerOfSmallItemView.y )];
            break;
        case Left:
            [self.magnifierViewForSmallItem setCenter:
             CGPointMake(centerOfSmallItemView.x - (smallItemViewWidth + magnifierViewWidth ) / 2,
                         centerOfSmallItemView.y )];
            break;
        default:
            break;
    }
    
    if (![self.subviews containsObject: self.magnifierViewForSmallItem]) {
        [self addSubview: self.magnifierViewForSmallItem];
    }
    
}

- (UIImage *)takeSnapshotOfMainWindowForTouchPoint: (CGPoint) touchPoint
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(g_magnifierWidth / g_magnifierScaleFactor,
                                                   g_magnifierHeight / g_magnifierScaleFactor),
                                           NO, 
                                           0);
    
    for (UIWindow* window in [[UIApplication sharedApplication] growingHelper_allWindowsWithoutGrowingWindowSortedByWindowLevel]){
        [window drawViewHierarchyInRect:CGRectMake( - touchPoint.x + g_magnifierWidth / g_magnifierScaleFactor / 2,
                                                   - touchPoint.y + g_magnifierHeight / g_magnifierScaleFactor / 2,
                                                   self.bounds.size.width,
                                                   self.bounds.size.height)
                     afterScreenUpdates: NO];
    }

    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *scaledSnapshot = [UIImage imageWithCGImage:snapshot.CGImage
                                                  scale: snapshot.scale / g_magnifierScaleFactor
                                            orientation: snapshot.imageOrientation];
    UIGraphicsEndImageContext();
    return scaledSnapshot;
}


- (void)removeMagnifier
{
    [self.magnifierViewForSmallItem removeFromSuperview];
    self.magnifierViewForSmallItem = nil;
}

- (void)delayCirclePoint:(NSValue*)pointValue
{
    NSArray<GrowingLocalCircleItem*>* circledItems = [self nodesForPoint:pointValue.CGPointValue];
    NSMutableArray<NSDictionary*> * parametersOfItems = [[NSMutableArray alloc] initWithCapacity:circledItems.count];

    if (circledItems.firstObject.doNotTrack)
    {
        [GrowingAlertMenu alertWithTitle:@"提示"
                                    text:@"该元素已被代码标记禁止收集"
                                 buttons:@[[GrowingMenuButton buttonWithTitle:@"知道了" block:nil]]];
        self.growingTaggedViews.isPaused = NO;
        return;
    }

    __weak GrowingLocalCircleWindow * wself = self;
    void (^finalBlock)() = ^() {
        GrowingLocalCircleWindow * sself = wself;
        if (sself == nil)
        {
            return;
        }
        if (parametersOfItems.count > 0)
        {
            NSMutableArray<GrowingSelectViewMenuItem*> * items = [[NSMutableArray alloc] initWithCapacity:circledItems.count];
            
            UIImage * windowImage = [[UIApplication sharedApplication] growingHelper_screenshotWithGrowingWindow:SCREENSHOT_SCALE];
            
            [parametersOfItems sortWithOptions:NSSortStable
                               usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                                   NSDictionary * p1 = obj1;
                                   NSDictionary * p2 = obj2;
                                   NSNumber * i1 = p1[@"index"];
                                   NSNumber * i2 = p2[@"index"];
                                   if (i1 == nil)
                                   {
                                       return i2 == nil ? NSOrderedSame : NSOrderedDescending;
                                   }
                                   else if (i2 == nil)
                                   {
                                       return NSOrderedAscending;
                                   }
                                   else
                                   {
                                       return [i1 compare:i2];
                                   }
                               }];
            
            for (NSUInteger i = 0; i < parametersOfItems.count; i++)
            {
                NSDictionary * parameter = parametersOfItems[i];
                NSString * type = parameter[@"type"];
                if ([type isEqualToString:@"native"])
                {
                    GrowingLocalCircleItem * item = parameter[@"item"];
                    GrowingSelectViewMenuItem *menuItem = [sself createMenuItemByCircleItem:item
                                                                                windowImage:windowImage];
                    menuItem.isH5Tag = NO;
                    [items addObject:menuItem];
                }
                else if ([type isEqualToString:@"async"])
                {
                    GrowingDullNode * node = parameter[@"node"];
                    GrowingElement * element = parameter[@"element"];
                    GrowingSelectViewMenuItem *menuItem = [sself createMenuItemByNode:node
                                                                           doNotTrack:NO
                                                                              element:element
                                                                          windowImage:windowImage
                                                                              isH5Tag:YES];
                    [items addObject:menuItem];
                }
            }
            
            for (NSInteger i = items.count - 1; i >= 0; i--)
            {
                id item = items[i];
                if ([item isKindOfClass:[NSNull class]])
                {
                    [items removeObjectAtIndex:i];
                }
            }
            
            BOOL needToAppendNativePage = YES;
            for (GrowingSelectViewMenuItem * item in items)
            {
                if (!item.isH5Tag && !item.isH5Page)
                {
                    
                    needToAppendNativePage = NO;
                }
            }
            if (needToAppendNativePage)
            {
                GrowingSelectViewMenuItem * nativePageItem = [self getNativePageItem:windowImage];
                if (nativePageItem != nil)
                {
                    [items addObject:nativePageItem];
                }
            }
            [sself showSelectedViewWithWindowImage:windowImage items:items];
        }
        sself.growingTaggedViews.isPaused = NO;
    };

    __block int waitingCallbacks = 0; 
    for (NSUInteger i = 0; i < circledItems.count; i++)
    {
        GrowingLocalCircleItem * item = circledItems[i];
        if (item.doNotTrack)
        {
            continue;
        }
        id<GrowingNodeAsyncNativeHandler> asyncNativeHandler = [item.node growingNodeAsyncNativeHandler];
        if (asyncNativeHandler != nil)
        {
            waitingCallbacks++;
            [asyncNativeHandler findNodeAtPoint:pointValue.CGPointValue
                                   withCallback:^(NSArray<GrowingDullNode *> * nodes, NSDictionary * pageData) {
                                       if (nodes.count > 0)
                                       {
                                           for (GrowingDullNode * node in nodes)
                                           {
                                               UIViewController * currentVC = [[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController];
                                               NSDictionary * pageDict = [currentVC growingNodeDataDict];
                                               NSString * domain = [GrowingDeviceInfo currentDeviceInfo].bundleID;
                                               NSString * mergedDomain = [GrowingJavascriptCore jointField:domain withField:pageData[@"d"]];
                                               NSString * mergePageName = [GrowingJavascriptCore jointField:pageDict[@"p"] withField:pageData[@"p"]];
                                               
                                               NSString * pageGroup = pageDict[@"pg"];
                                               NSString * pageQuery = pageData[@"q"];

                                               GrowingElement *element = [[GrowingElement alloc] init];
                                               element.page = mergePageName;
                                               element.pageGroup = pageGroup;
                                               element.domain = mergedDomain;
                                               element.xpath = node.growingNodeXPath;
                                               element.patternXPath = node.growingNodePatternXPath;
                                               element.index = node.growingNodeKeyIndex;
                                               element.content = node.growingNodeContent;
                                               element.query = pageQuery;
                                               element.href = node.growingNodeHyperlink;
                                               element.isHybridTrackingEditText = node.isHybridTrackingEditText;
                                               
                                               NSDictionary * parameter = @{@"type": @"async", @"index": @(i), @"node": node, @"element": element};
                                               [parametersOfItems addObject:parameter];
                                           }
                                       }
                                       waitingCallbacks--;
                                       if (waitingCallbacks == 0)
                                       {
                                           finalBlock();
                                       }
                                   }];
        }
        else
        {
            NSDictionary * parameter = @{@"type": @"native", @"index": @(i), @"item": item};
            [parametersOfItems addObject:parameter];
        }
    }

    if (waitingCallbacks == 0)
    {
        finalBlock();
    }
}

- (GrowingSelectViewMenuItem*)createMenuItemByNode:(id<GrowingNode>)aNode
                                        doNotTrack:(BOOL)doNotTrack
                                           element:(GrowingElement*)element
                                       windowImage:(UIImage*)windowImage
                                           isH5Tag:(BOOL)isH5Tag
{
    GrowingSelectViewMenuItem *menuitem = [[GrowingSelectViewMenuItem alloc] initWithElement:element];
    menuitem.frame = [aNode growingNodeFrame];
    menuitem.doNotTrack = doNotTrack;
    menuitem.name = [aNode growingNodeName];
    menuitem.snapshot = [aNode growingNodeScreenShot:windowImage];
    
    
    if ([aNode isKindOfClass:[UILabel class]])
    {
        UILabel *lbl = (UILabel*)aNode;
        menuitem.fontSize = lbl.font.pointSize;
    }
    else
    {
        menuitem.fontSize = 0;
    }
    
    
    if ([GrowingCircleNodeManager recursiveAttributeValueOfNode:aNode
                                                         forKey:GrowingAttributeIsHorizontalTableKey]
        == GrowingAttributeReturnYESKey)
    {
        menuitem.isInHorizontalTableView = YES;
    }
    else
    {
        menuitem.isInHorizontalTableView = NO;
    }
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGSize controlSize = [aNode growingNodeFrame].size;
    menuitem.isWideEnough = ((menuitem.isInHorizontalTableView ? controlSize.height:controlSize.width) > screenSize.width/2);
    
    
    if ([GrowingCircleNodeManager recursiveAttributeValueOfNode:aNode
                                                         forKey:GrowingAttributeIsTabbarInTabbarControllerKey]
        == GrowingAttributeReturnYESKey)
    {
        menuitem.isIgnorePage = YES;
    }
    else
    {
        menuitem.isIgnorePage = NO;
    }
    
    
    if ([aNode isKindOfClass:[UITextField class]]
        || [aNode isKindOfClass:[UISearchBar class]]
        || [aNode isKindOfClass:[UITextView class]])
    {
        menuitem.isTextInput = YES;
    }
    
    if (isH5Tag) {
        menuitem.isTextInput = element.isHybridTrackingEditText;
    }
    
    
    menuitem.visiableIndex = element.index;

    
    menuitem.isContainer = [GrowingWebSocket isContainer:aNode];

    
    menuitem.parentXPath = menuitem.growingElement.xpath;

    menuitem.isH5Tag = isH5Tag;
    if (isH5Tag)
    {
        NSString * defaultName = @"当前页面";
        NSString * domain = menuitem.growingElement.domain;
        NSString * page = menuitem.growingElement.page;
        NSString * query = nil; 
        if (page.length > 0)
        {
            NSMutableArray<GrowingTagItem *> * pageCandidates = [[NSMutableArray alloc] init];

            GrowingTagItem * currentPageTag = [[GrowingTagItem alloc] initPageTagWithName:defaultName andPage:page andQuery:query];
            [pageCandidates addObject:currentPageTag];

            NSArray<GrowingTagItem *> * tags = [[GrowingLocalCircleModel sdkInstance] cacheTagItems];
            [tags enumerateObjectsUsingBlock:^(GrowingTagItem * _Nonnull tag, NSUInteger idx, BOOL * _Nonnull stop) {
                if (tag.isPageTag)
                {
                    if (tag.domain.length == 0 || [domain isEqualToString:tag.domain])
                    {
                        if (tag.page.length == 0 || [page growingHelper_matchWildly:tag.page])
                        {
                            if (tag.query.length == 0 || [query growingHelper_matchWildly:tag.query])
                            {
                                [pageCandidates addObject:tag];
                            }
                        }
                    }
                }
            }];
            menuitem.h5PageCandidates = pageCandidates;
        }
        menuitem.href = menuitem.growingElement.href;
    }

    return menuitem;
}

- (GrowingSelectViewMenuItem*)createMenuItemByCircleItem:(GrowingLocalCircleItem*)circleItem windowImage:(UIImage*)windowImage
{
    GrowingElement *element = [self getElementFromNode:circleItem.node];
    GrowingSelectViewMenuItem *menuItem = [self createMenuItemByNode:circleItem.node
                                                          doNotTrack:circleItem.doNotTrack
                                                             element:element
                                                         windowImage:windowImage
                                                             isH5Tag:NO];
    if (menuItem.visiableIndex != [GrowingNodeItemComponent indexNotDefine])
    {
        menuItem.visiableIndex += 1;
    }
    
    for (GrowingLocalCircleItem *childCircleItem in circleItem.childNodes)
    {
        GrowingSelectViewMenuItem * item = [self createMenuItemByCircleItem:childCircleItem windowImage:windowImage];
        item.parentXPath = menuItem.growingElement.xpath; 
        [menuItem addChildItem:item];
    }
    return menuItem;
}

- (GrowingElement*)getElementFromNode:(id<GrowingNode>)v
{
    GrowingElement *element = [[GrowingElement alloc] init];
    if ([v isKindOfClass:[UIViewController class]])
    {
        element.page = [(UIViewController*)v GROW_pageName];
        element.pageGroup = ((UIViewController*)v).growingAttributesPageGroup;
    }
    else
    {
        GrowingCircleNodeManager *manager = [[GrowingCircleNodeManager alloc] initWithNodeAndParent:v];
        UIViewController *curPage = [[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController];
        element.page = [curPage GROW_pageName];
        element.pageGroup = curPage.growingAttributesPageGroup;
        if (manager)
        {
            [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode,
                                                   GrowingNodeManagerEnumerateContext *context) {
                NSInteger keyIndex = [context nodeKeyIndex];
                if (keyIndex >= 0)
                {
                    element.index = keyIndex;
                }
                element.xpath = [context xpath];
                element.content = [aNode growingNodeContent];
                
                [context stop];
            }];
        }
    }
    return element;
}

+ (void)increaseHiddenCount
{
    [[self shareInstance] hideButton];
}

+ (void)decreaseHiddenCount
{
    [[self shareInstance] showButton];
}

- (void)showButton
{
    BOOL needShow = self.showCount == 0;
    self.showCount++;
    if (needShow)
    {
        self.buttonView.alpha = DEFAULT_ALPHA;
        self.hidden = NO;
        self.userInteractionEnabled = YES;
        [self showHelper];
    }
}

- (void)hideButton
{
    self.showCount--;
    if (self.showCount == 0)
    {
        self.userInteractionEnabled = NO;
        self.buttonView.alpha = 0;
        self.hidden = YES;
    }
}

- (void)showSelectedViewWithWindowImage:(UIImage*)windowImage
                                  items:(NSArray<GrowingSelectViewMenuItem*>*)aItems
{
    [GrowingAddTagMenu showFirstOfAllViewMenuItems:aItems
                                    andWindowImage:windowImage];
}

- (void)setLastItems:(NSArray<GrowingLocalCircleItem *> *)lastItems
{
    if (!self.lastItemsMutable)
    {
        self.lastItemsMutable = [[NSMutableArray alloc] init];
    }
    id<GrowingNode> oldNode = self.lastItemsMutable.firstObject.node;
    id<GrowingNode> newNode = lastItems.firstObject.node;
    
    if (oldNode != newNode)
    {
        [self updateSelectedMask:(newNode == nil ? @[] : @[newNode]) doNotTrack:lastItems.firstObject.doNotTrack];
        if ([oldNode growingNodeAsyncNativeHandler] != nil)
        {
            
            [oldNode growingNodeHighLight:NO withBorderColor:nil andBackgroundColor:nil];
        }
    }
    else if ([newNode growingNodeAsyncNativeHandler] != nil)
    {
        
        [newNode growingNodeHighLight:YES
                      withBorderColor:[GrowingUIConfig circlingItemBorderColor]
                   andBackgroundColor:[GrowingUIConfig circlingItemBackgroundColor]];
    }
    
    [self.lastItemsMutable removeAllObjects];
    [self.lastItemsMutable addObjectsFromArray:lastItems];
}

- (void)updateSelectedMask:(NSArray<id<GrowingNode>> *)nodes doNotTrack:(BOOL)doNotTrack
{
    UIColor * borderColor = [GrowingUIConfig circlingItemBorderColor];
    UIColor * backgroundColor = (doNotTrack ? [GrowingUIConfig circlErrorItemBackgroundColor]
                                 : [GrowingUIConfig circlingItemBackgroundColor]);
    NSArray<NSValue *> * keys = [[self.allMaskViews keyEnumerator] allObjects];
    NSInteger i;
    for (NSValue * key in keys)
    {
        void * node = (key != nil ? [key pointerValue] : nil);
        for (i = 0; i < [nodes count]; i++)
        {
            if ((__bridge void *)nodes[i] == node)
            {
                break;
            }
        }
        if (i == [nodes count])
        {
            [[self.allMaskViews objectForKey:key] removeFromSuperview];
            [self.allMaskViews removeObjectForKey:key];
        }
    }
    keys = [[self.allMaskViews keyEnumerator] allObjects];
    for (i = 0; i < [nodes count]; i++)
    {
        id<GrowingNode> node = nodes[i];
        if ([node growingNodeAsyncNativeHandler] != nil)
        {
            
            [node growingNodeHighLight:YES withBorderColor:borderColor andBackgroundColor:backgroundColor];
            continue;
        }
        BOOL found = NO;
        for (NSValue * key in keys)
        {
            if ([key pointerValue] == (__bridge void *)node)
            {
                found = YES;
                break;
            }
        }
        if (!found)
        {
            CGRect frame = [node growingNodeFrame];
            if (CGRectEqualToRect(frame, CGRectZero))
            {
                continue;
            }
            UIView *maskView = [[UIView alloc] initWithFrame:frame];
            maskView.layer.borderWidth = 1;
            maskView.layer.borderColor = borderColor.CGColor;
            maskView.backgroundColor = backgroundColor;
            maskView.layer.cornerRadius = MIN(10, MIN(self.bounds.size.width,self.bounds.size.height) / 4);
            maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            maskView.growingAttributesDonotTrack = YES;
            [self addSubview:maskView];
            [self.allMaskViews setObject:maskView forKey:[NSValue valueWithPointer:(__bridge void *)node]];
        }
    }
}

- (NSArray<GrowingLocalCircleItem*>*)lastItems
{
    return self.lastItemsMutable;
}

+ (void)circlePage
{
    [[self shareInstance] circlePage];
}

- (void)circlePage
{
    UIImage * windowImage = [[UIApplication sharedApplication] growingHelper_screenshotWithGrowingWindow:SCREENSHOT_SCALE];
    GrowingSelectViewMenuItem * item = [self getNativePageItem:windowImage];
    if (item != nil)
    {
        [self showSelectedViewWithWindowImage:windowImage items:@[item]];
    }
}

- (GrowingSelectViewMenuItem *)getNativePageItem:(UIImage *)windowImage
{
    UIViewController *vc = [[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController];
    if (vc)
    {
        GrowingElement *element = [self getElementFromNode:vc];
        GrowingSelectViewMenuItem *item = [[GrowingSelectViewMenuItem alloc] initWithElement:element];
        item.frame = [vc growingNodeFrame];
        item.snapshot = [vc growingNodeScreenShot:windowImage];
        item.isPage = YES;
        item.isH5Page = NO;
        item.pageTitle = [vc GROW_pageTitle];
        item.name = [vc growingNodeName];
        return item;
    }
    return nil;
}

+ (void)circleH5Pages:(NSArray<NSDictionary *> *)pageDictArray
{
    [[self shareInstance] circleH5Pages:pageDictArray];
}

- (void)circleH5Pages:(NSArray<NSDictionary *> *)pageDictArray
{
    NSMutableArray<GrowingSelectViewMenuItem *> * itemArray = [[NSMutableArray alloc] init];
    UIImage * windowImage = [[UIApplication sharedApplication] growingHelper_screenshotWithGrowingWindow:SCREENSHOT_SCALE];
    for (NSDictionary * pageDict in pageDictArray)
    {
        NSDictionary * pageData = pageDict[@"pageData"];
        GrowingDullNode * h5Node = pageDict[@"node"];
        if (pageData.count > 0 && h5Node != nil)
        {
            GrowingElement *element = [[GrowingElement alloc] init];
            element.page = pageData[@"p"];
            element.pageGroup = pageData[@"pg"];
            GrowingSelectViewMenuItem *item = [[GrowingSelectViewMenuItem alloc] initWithElement:element];
            item.frame = [h5Node growingNodeFrame];
            item.snapshot = [h5Node growingNodeScreenShot:windowImage];
            item.isPage = YES;
            item.isH5Page = YES;
            item.pageDomainH5 = pageData[@"d"];
            item.pageTitle = pageData[@"v"];
            item.name = pageData[@"v"];
            item.pageQuery = pageData[@"q"];
            [itemArray addObject:item];
        }
    }
    [self showSelectedViewWithWindowImage:windowImage items:itemArray];
}

- (void)hideHelper
{
    if (self.helperMenu)
    {
        [self.helperMenu hideWithFinishBlock:^{
            [self hideButton];
            self.helperMenu = nil;
        }];
    }
}

- (void)showHelper
{
    return;
    
}

- (void)tapGest:(UITapGestureRecognizer*)gest
{
    if (gest.state == UIGestureRecognizerStateEnded && !self.helperMenu && [[[UIApplication sharedApplication] growingMainWindow] growingHook_curViewController])
    {
        [_GrowingSettingMenuAlertView show];
    }
}

- (void)setIsStart:(BOOL)isStart
{
    if (_isStart == isStart)
    {
        return;
    }
    
    _isStart = isStart;
    
    if (isStart)
    {
        self.isShow = YES;
    }
    else
    {
        self.isShow = NO;
    }
}


- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView * hit = [super hitTest:point withEvent:event];
    if (hit == self)
    {
        return nil;
    }
    else
    {
        return hit;
    }
}

@end
