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


#import "GrowingKeyBoardToolBar.h"
#import "UIControl+GrowingHelper.h"

@interface GrowingKeyBoardToolBar()

@property (nonatomic, unsafe_unretained) UITextField *view;

@end

@implementation GrowingKeyBoardToolBar



- (instancetype)initWithView:(UITextField *)textField
{
    self = [super initWithFrame:CGRectMake(0,0, [UIScreen mainScreen].bounds.size.width, 30)];
    if (self)
    {
        self.view = textField;
        self.backgroundColor = [UIColor whiteColor];
        
        
        
        
        
        @weakify(self);
        NSArray *btnAndBlock =
        @[
          @"全选",^{
              @strongify(self);
              [self.view selectAll:nil];
          },
          @"复制",^{
              @strongify(self);
              [UIPasteboard generalPasteboard].string = self.view.text;
          },
          @"粘贴",^{
              @strongify(self);
              self.view.text = [UIPasteboard generalPasteboard].string;
          }];
        
        CGFloat x = 10;
        for (NSInteger i = 0 ; i < btnAndBlock.count / 2; i++)
        {
            NSString *title = btnAndBlock[i*2];
            void(^block)(void) = [btnAndBlock[i*2 + 1] copy];
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x, 2, 50, 26)];
            [btn setTitle:title forState:0];
            [btn setTitleColor:[UIColor blackColor] forState:0];
            [self addSubview:btn];
            btn.growingHelper_onClick = block;
            x+= 60;
        }
    }
    return self;
}

@end
