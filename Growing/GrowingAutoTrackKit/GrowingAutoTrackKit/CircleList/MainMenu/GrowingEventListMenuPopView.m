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


#import "GrowingEventListMenuPopView.h"
#import "GrowingUIConfig.h"

@interface GrowingEventListMenuPopView ()
@property (nonatomic, retain) NSMutableArray *tipButtons;


@property (nonatomic, assign) NSInteger  showButtonCountWithoutAnimated;
@property (nonatomic, retain) UIButton *clickHere;
@property (nonatomic, assign) BOOL showClickHere;

@end

@implementation GrowingEventListMenuPopView

#define BTN_HEIGHT 20
#define BTN_SIZE 12

#define CLICK_HERE_WIDTH 100
#define CLICK_HERE_HEIGHT 20
#define CLICK_HERE_FONT_SIZE   12

- (void)popButtonDidClick
{
    if (self.onClick)
    {
        self.onClick();
    }
}

- (void)popTitle:(NSString *)title withColor:(UIColor *)color
{
    UIButton *btn = [[UIButton alloc] init];
    [btn addTarget:self action:@selector(popButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = color;
    btn.titleLabel.font = [UIFont systemFontOfSize:BTN_SIZE];
    [btn setTitle:title forState:0];
    CGSize size = [btn sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    size.width += 6;
    btn.frame = CGRectMake(self.bounds.size.width - size.width,
                           -BTN_HEIGHT,
                           size.width,
                           BTN_HEIGHT);
    [self insertSubview:btn atIndex:0];
    
    
    
    if (!self.tipButtons)
    {
        self.tipButtons = [[NSMutableArray alloc] init];
    }
    
    [self.tipButtons insertObject:btn atIndex:0];
    UIButton *firstButton = self.tipButtons.firstObject;
    
    self.showButtonCountWithoutAnimated ++;
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGFloat y = 0;
                         CGRect frame = CGRectZero;
                         for (NSInteger i = 0; i < self.tipButtons.count ; i++)
                         {
                             UIButton *moveBtn = self.tipButtons[i];
                             y = i * (BTN_HEIGHT + 1);
                             frame = moveBtn.frame;
                             frame.origin.y = y;
                             moveBtn.frame = frame;
                         }
                     }
                     completion:^(BOOL finished) {
                     }];
    [self performSelector:@selector(hiddenTipView:) withObject:firstButton afterDelay:2];
}

- (void)setShowButtonCountWithoutAnimated:(NSInteger)showButtonCountWithoutAnimated
{
    _showButtonCountWithoutAnimated = showButtonCountWithoutAnimated;
    self.showClickHere = self.showButtonCountWithoutAnimated == 0 ;
}


- (void)setShowClickHere:(BOOL)showClickHere
{
    _showClickHere = showClickHere;
    
    CGRect frame = CGRectZero;
    if (showClickHere)
    {
        if (!self.clickHere)
        {
            self.clickHere = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - CLICK_HERE_WIDTH,
                                                                        0,
                                                                        CLICK_HERE_WIDTH,
                                                                        CLICK_HERE_HEIGHT)];
            [self.clickHere addTarget:self
                               action:@selector(popButtonDidClick)
                     forControlEvents:UIControlEventTouchUpInside];
            
            NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:@"点此查看所有事件"];
            [title addAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],
                                   NSFontAttributeName : [UIFont systemFontOfSize:CLICK_HERE_FONT_SIZE]}
                           range:NSMakeRange(0, title.length)];
            
            
            [self.clickHere setAttributedTitle:title forState:0];
            self.clickHere.backgroundColor = [GrowingUIConfig circleListMainColor];
            [self addSubview:self.clickHere];
        }
        frame = CGRectMake(self.bounds.size.width - CLICK_HERE_WIDTH,
                           0,
                           CLICK_HERE_WIDTH,
                           CLICK_HERE_HEIGHT);
    }
    else
    {
        frame =
        CGRectMake(self.bounds.size.width - CLICK_HERE_WIDTH,
                   -CLICK_HERE_HEIGHT,
                   CLICK_HERE_WIDTH,
                   CLICK_HERE_HEIGHT);
    }
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.clickHere.frame = frame;
                     }];
    
}

- (void)hiddenTipView:(UIView*)tipView
{
    self.showButtonCountWithoutAnimated --;
    
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         tipView.alpha = 0;
                     } completion:^(BOOL finished) {
                         [tipView removeFromSuperview];
                         [self.tipButtons removeObject:tipView];
                     }];
    
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self)
    {
        return nil;
    }
    else
    {
        return view;
    }
}

@end
