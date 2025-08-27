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


#import "GrowingCircleListBaseViewController.h"
#import "GrowingUIConfig.h"

@interface GrowingCircleListBaseViewController ()

@end

@implementation GrowingCircleListBaseViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.barColor = [UIColor whiteColor];
        self.barTextColor = C_R_G_B(107,125,142);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = self.barColor;
    
    self.navigationController.navigationBar.tintColor = self.barTextColor;
    NSDictionary * dict = @{NSForegroundColorAttributeName :self.barTextColor ,
                            NSFontAttributeName :[UIFont systemFontOfSize:20]};
    [self.navigationController.navigationBar setTitleTextAttributes:dict];
}

@end
