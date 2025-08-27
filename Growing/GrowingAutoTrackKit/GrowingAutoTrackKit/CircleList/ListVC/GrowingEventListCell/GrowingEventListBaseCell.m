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


#import "GrowingEventListBaseCell.h"
#import "GrowingUIConfig.h"

@interface GrowingEventListBaseCell()

@property (nonatomic, retain) UIView *sublineView;

@end

@implementation GrowingEventListBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.sublineView = [[UIView alloc] init];
        self.sublineView.backgroundColor = C_R_G_B(236, 236, 236);
        [self.contentView addSubview:self.sublineView];
        self.sublineView.userInteractionEnabled = NO;
    }
    return self;
}

- (void)setMainColor:(UIColor *)mainColor
{
    _mainColor = mainColor;

}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.sublineView.frame = CGRectMake(0,
                                        self.contentView.bounds.size.height - GrowingEventListBaseCellSublineHeight,
                                        self.contentView.bounds.size.width,
                                        GrowingEventListBaseCellSublineHeight);
}

@end
