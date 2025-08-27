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


#import "GrowingLoginMenu.h"
#import "UIView+GrowingHelperLayout.h"
#import "GrowingUIConfig.h"
#import "GrowingLoginModel.h"
#import "GrowingTaggedViews.h"
#import "GrowingKeyBoardToolBar.h"
#import "GrowingWebSocket.h"


@interface growingLoginTextField : UITextField

@end

#define FONT_SIZE 20
#define LEFT_MARGIN 20

@implementation growingLoginTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.inputAccessoryView = [[GrowingKeyBoardToolBar alloc] initWithView:self];
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectMake(bounds.origin.x + 45,
                      bounds.origin.y + 20,
                      bounds.size.width - 90,
                      bounds.size.height-20);
}
- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:))
        return NO;
    if (action == @selector(select:))
        return NO;
    if (action == @selector(selectAll:))
        return NO;
    return [super canPerformAction:action withSender:sender];
}

@end

@interface GrowingLoginMenu()<UITextFieldDelegate>

@property (nonatomic, retain) UITextField *txtUserId;
@property (nonatomic, retain) UITextField *txtPassword;

@property (nonatomic, assign) BOOL shouldDisplayTaggedViews;

@property (nonatomic, copy) void(^succeedBlock)(void);
@property (nonatomic, copy) void(^failBlock)(void);

@end

@implementation GrowingLoginMenu

- (instancetype)initWithType:(GrowingMenuShowType)showType
{
    self = [super initWithType:showType];
    if (self)
    {
        self.title = @"登录";
        __weak GrowingLoginMenu *wself = self;
        self.menuButtons = @[
                             [GrowingMenuButton buttonWithTitle:@"取消" block:^{
                                 void (^failBlock)()  = wself.failBlock;
                                 [wself clearAlertView];
                                 [wself hide];
                                 
                                 if (failBlock)
                                 {
                                     failBlock();
                                 }
                             }],
                             [GrowingMenuButton buttonWithTitle:@"登录" block:^{
                                 [wself loginClick];
                             }]
                             ];
        self.shouldDisplayTaggedViews = [[GrowingTaggedViews shareInstance] shouldDisplayTaggedViews];
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.txtUserId)
    {
        [self.txtPassword becomeFirstResponder];
    }
    else if (textField == self.txtPassword)
    {
        [self.txtPassword resignFirstResponder];
        [self loginClick];
    }
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIFont *font = [UIFont systemFontOfSize:FONT_SIZE];
    self.txtUserId =
    [self.view growAddSubviewClass:[growingLoginTextField class]
                                    block:^(MASG3ConstraintMaker *make, UITextField *obj) {

                                        obj.attributedPlaceholder =
                                        [[NSMutableAttributedString alloc]
                                         initWithString:@"邮箱地址"
                                         attributes:@{NSForegroundColorAttributeName:[GrowingUIConfig placeHolderColor],
                                                      NSFontAttributeName:font}];
                                        obj.delegate = self;
                                        obj.font = font;
                                        make.left.offset(0);
                                        make.top.offset(0);
                                        make.right.offset(0);
                                        make.height.offset(64);
                                        
                                        [obj setAutocorrectionType:UITextAutocorrectionTypeNo];
                                        
                                        [obj setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                                    }];
    self.txtPassword =
    [self.view growAddSubviewClass:[growingLoginTextField class]
                                    block:^(MASG3ConstraintMaker *make, UITextField *obj) {
                                        obj.font = font;
                                        obj.secureTextEntry = YES;
                                        obj.attributedPlaceholder =
                                        [[NSMutableAttributedString alloc]
                                         initWithString:@"密码"
                                         attributes:@{NSForegroundColorAttributeName:[GrowingUIConfig placeHolderColor],
                                                      NSFontAttributeName:font}];
                                        obj.delegate = self;
                                        
                                        make.left.offset(0);
                                        make.top.masG3_equalTo(self.txtUserId.masG3_bottom);
                                        make.right.offset(0);
                                        make.height.offset(64);
                                        
                                    }];

    [self.view growAddViewWithColor:[GrowingUIConfig mainColor]
                                   block:^(MASG3ConstraintMaker *make, UIView *view) {
                                       make.bottom.masG3_equalTo(self.txtUserId.masG3_bottom).offset(0);
                                       make.left.masG3_equalTo(self.txtUserId.masG3_left).offset(LEFT_MARGIN);
                                       make.right.masG3_equalTo(self.txtUserId.masG3_right).offset(-LEFT_MARGIN);
                                       make.height.offset(1);
                                   }];
    [self.view growAddViewWithColor:[GrowingUIConfig mainColor]
                                     block:^(MASG3ConstraintMaker *make, UIView *view) {
                                         make.bottom.masG3_equalTo(self.txtPassword.masG3_bottom).offset(0);
                                         make.left.masG3_equalTo(self.txtPassword.masG3_left).offset(LEFT_MARGIN);
                                         make.right.masG3_equalTo(self.txtPassword.masG3_right).offset(-LEFT_MARGIN);
                                         make.height.offset(1);
                                         
                                     }];
}

- (CGFloat)preferredContentHeight
{
    return 160;
}

- (void)clearAlertView
{
    self.txtPassword.text = nil;
    self.txtUserId.text = nil;
    self.succeedBlock = nil;
    self.failBlock = nil;
}

- (void)loginClick
{
    [self loginById:self.txtUserId.text
                pwd:self.txtPassword.text];
}

- (void)loginById:(NSString*)aId pwd:(NSString*)pwd
{
    
    GrowingAlertMenu *loadingMenu = [GrowingAlertMenu alertWithTitle:@"登录GrowingIO"
                                                                text:@"正在登录..."
                                                             buttons:nil];
    
    [loadingMenu show];
    
    [self hide];
    
    
    void (^succeedBlock)(void) = ^{
        void (^succeedBlock)(void) = self.succeedBlock;
        [GrowingTaggedViews shareInstance].shouldDisplayTaggedViews = self.shouldDisplayTaggedViews;
        [self clearAlertView];
        if (succeedBlock)
        {
            succeedBlock();
        }
        [loadingMenu hide];
    };
    
    
    void(^faileBlock)(NSString *msg) = ^(NSString *msg){
        [GrowingAlertMenu alertWithTitle:@"登录GrowingIO"
                                    text:msg
                                 buttons:@[[GrowingMenuButton buttonWithTitle:@"确定"
                                                                        block:^{
                                                                            [self show];
                                                                        }]]];
        [loadingMenu hide];
    };
    
    
    [[GrowingLoginModel sdkInstance] loginByUserId:aId
                                            password:pwd
                                             succeed:succeedBlock
                                                fail:faileBlock];
}

static GrowingLoginMenu *loginMenu = nil;
static NSMutableArray<void (^)(void)> *succeedBlocks = nil;
static NSMutableArray<void (^)(void)> *failBlocks = nil;
+ (void)showWithSucceed:(void (^)(void))succeedBlock
                   fail:(void (^)(void))failBlock
{
    if ([GrowingWebSocket isRunning])
    {
        failBlock();
        return;
    }

    if (!succeedBlocks)
    {
        succeedBlocks = [[NSMutableArray alloc] init];
    }
    if (succeedBlock)
    {
        [succeedBlocks addObject:succeedBlock];
    }
    
    if (!failBlocks)
    {
        failBlocks = [[NSMutableArray alloc] init];
    }
    if (failBlock)
    {
        [failBlocks addObject:failBlock];
    }
    
    
    if (loginMenu)
    {
        return;
    }
    loginMenu = [[GrowingLoginMenu alloc] init];
    loginMenu.succeedBlock = ^{
        [succeedBlocks enumerateObjectsUsingBlock:^(void (^ _Nonnull obj)(), NSUInteger idx, BOOL * _Nonnull stop) {
            obj();
        }];
        [self clearGrowingLoginMenu];
    };
    loginMenu.failBlock = ^{
        [failBlocks enumerateObjectsUsingBlock:^(void (^ _Nonnull obj)(), NSUInteger idx, BOOL * _Nonnull stop) {
            obj();
        }];
        
        [self clearGrowingLoginMenu];
    };
    [loginMenu show];
}

+ (void)showIfNeededSucceed:(void (^)(void))succeedBlock fail:(void (^)(void))failBlock
{
    if ([GrowingLoginModel sdkInstance].token.length)
    {
        succeedBlock();
    }
    else
    {
        [self showWithSucceed:succeedBlock fail:failBlock];
    }
}

+ (void)clearGrowingLoginMenu
{
    [loginMenu hide];
    loginMenu = nil;
    [succeedBlocks removeAllObjects];
    succeedBlocks = nil;
    [failBlocks removeAllObjects];
    failBlocks = nil;
}

@end
