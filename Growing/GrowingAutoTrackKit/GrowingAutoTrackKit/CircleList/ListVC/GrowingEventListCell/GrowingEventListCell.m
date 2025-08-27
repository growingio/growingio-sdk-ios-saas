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


#import "GrowingEventListCell.h"


#import "UIControl+GrowingHelper.h"
#import "GrowingUIConfig.h"



@interface GrowingEventListCell()

@property (nonatomic, retain) UILabel *preTitleLabel;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *subTitleLabel;
@property (nonatomic, retain) UIImageView *screenShotView;

@property (nonatomic, retain) UIView *iconView;

@property (nonatomic, retain) NSMutableArray *commentViews;
@property (nonatomic, retain) NSMutableArray *rightViews;
@property (nonatomic, retain) NSMutableArray *bottomButtons;
@property (nonatomic, retain) UIView *bottomButtonsSubline;

@end

@implementation GrowingEventListCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.screenShot = nil;
    self.screenShotKey = nil;
    self.preTitle = nil;
    self.title = nil;
    self.subtitle = nil;
    [self.commentViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.commentViews = nil;
    [self.rightViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.rightViews = nil;
    
    [self.bottomButtons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.bottomButtons = nil;
    [self.bottomButtonsSubline removeFromSuperview];
    self.bottomButtonsSubline = nil;
}

- (void)addButtonTitle:(NSString *)title
                  type:(GrowingEventListCellButtonType)type
               onClick:(void (^)(void))onClick
{
    if (type == GrowingEventListCellButtonTypeTag)
    {
        [self addComment:title onClick:onClick];
    }
    else if (type == GrowingEventListCellButtonTypeRight)
    {
        [self addRightButton:title onClick:onClick];
    }
    else if (type == GrowingEventListCellButtonTypeBottom)
    {
        [self addBottomButton:title onClick:onClick];
    }
}

- (void)addComment:(NSString *)comment
           onClick:(void (^)(void))onClick
{
    UIButton *btn = [[UIButton alloc] init];
    [self.contentView addSubview:btn];
    btn.titleLabel.font = [UIFont systemFontOfSize:8];
    [btn setTitleColor:[UIColor blackColor] forState:0];
    [btn setTitle:comment forState:0];
    
    btn.growingHelper_onClick = onClick;
    
    if (!self.commentViews)
    {
        self.commentViews = [[NSMutableArray alloc] init];
    }
    [self.commentViews addObject:btn];

}

- (void)addRightButton:(NSString *)string onClick:(void (^)(void))onClick
{
    UIButton *btn = [[UIButton alloc] init];
    btn.backgroundColor = self.mainColor;
    btn.layer.cornerRadius = 4;

    btn.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:btn];
    [btn setTitle:string forState:0];
    btn.growingHelper_onClick = onClick;
    
    if (!self.rightViews)
    {
        self.rightViews = [[NSMutableArray alloc] init];
    }
    [self.rightViews addObject:btn];
}

- (void)addBottomButton:(NSString *)btnTitle onClick:(void (^)(void))onClick
{
    if (!btnTitle.length)
    {
        return;
    }
    if (!self.bottomButtons)
    {
        self.bottomButtons = [[NSMutableArray alloc] init];
    }
    UIButton *lastbtn = self.bottomButtons.lastObject;
    if (lastbtn)
    {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(lastbtn.bounds.size.width - 1,
                                                               8,
                                                               1,
                                                               lastbtn.bounds.size.height - 16)];
        view.backgroundColor = [GrowingUIConfig eventListBgColor];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
        [lastbtn addSubview:view];
    }
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0,0,100,42)];
    [btn setTitle:btnTitle forState:0];
    [btn setTitleColor:[GrowingUIConfig eventListTextColor] forState:0];
    UILabel *lbl = btn.titleLabel;
    
    
    lbl.numberOfLines = 2;
    lbl.text = btnTitle;
    lbl.font = [UIFont systemFontOfSize:14];
    lbl.minimumScaleFactor = 0.7;
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.lineBreakMode = NSLineBreakByTruncatingMiddle;
    lbl.adjustsFontSizeToFitWidth = YES;
    
    


    



    [self.contentView addSubview:btn];
    [self.bottomButtons addObject:btn];
    
    btn.growingHelper_onClick = onClick;
    
    if (!self.bottomButtonsSubline)
    {
        self.bottomButtonsSubline = [[UIView alloc] initWithFrame:CGRectZero];
        self.bottomButtonsSubline.backgroundColor = [GrowingUIConfig eventListBgColor];
        [self.contentView addSubview:self.bottomButtonsSubline];
        self.bottomButtonsSubline.userInteractionEnabled = NO;
    }
    
    [self setNeedsLayout];
}

#define SUBTITLESIZE 8
#define TITLESIZE  13

#define LEFTMARGIN 30
#define RIGHTMARGIN 10

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.iconView = [[UIView alloc] initWithFrame:CGRectMake(10,10,10,10)];
        self.iconView.layer.cornerRadius = 5;
        self.iconView.clipsToBounds = YES;
        [self.contentView addSubview:self.iconView];
        self.iconView.userInteractionEnabled = NO;
        
        self.preTitleLabel = [[UILabel alloc] init];
        self.preTitleLabel.font = [UIFont systemFontOfSize:11];
        self.preTitleLabel.textColor = [GrowingUIConfig eventListTextColor];
        [self.contentView addSubview:self.preTitleLabel];
        
        self.titleLabel = [[self class] createTitleView];;
        [self.contentView addSubview:self.titleLabel];
        
        self.subTitleLabel = [[self class] createSubtitleView];
        [self.contentView addSubview:self.subTitleLabel];
        
        self.screenShotView = [[UIImageView alloc] init];
        [self.contentView addSubview:self.screenShotView];
        self.screenShotView.backgroundColor = [UIColor clearColor];
        
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setMainColor:(UIColor *)mainColor
{
    [super setMainColor:mainColor];
    self.iconView.backgroundColor = mainColor;
    self.screenShotView.layer.borderColor = [mainColor colorWithAlphaComponent:0.3].CGColor;
    
    [self.rightViews enumerateObjectsUsingBlock:^(UIButton *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.backgroundColor = mainColor;
    }];

}

- (void)setPreTitle:(NSString *)preTitle
{
    _preTitle = preTitle;
    self.preTitleLabel.text = preTitle;
    [self setNeedsLayout];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
    [self setNeedsLayout];
}

- (void)setSubtitle:(NSString *)subtitle
{
    _subtitle = subtitle;
    self.subTitleLabel.text = subtitle;
    [self setNeedsLayout];
}

- (void)setScreenShot:(UIImage *)screenShot
{
    _screenShot = screenShot;
    self.screenShotView.image = screenShot;
    if (screenShot)
    {
        self.screenShotView.layer.cornerRadius = 4;
        self.screenShotView.layer.borderWidth = 1;
        self.screenShotView.clipsToBounds = YES;
        
    }
    else
    {
        self.screenShotView.layer.cornerRadius = 0;
        self.screenShotView.layer.borderWidth = 0;
        self.screenShotView.clipsToBounds = NO;
    }
}

- (void)setScreenShotSize:(CGSize)screenShotSize
{
    _screenShotSize = screenShotSize;
    [self setNeedsLayout];
}

#define MAX_IMG_HEIGHT 180.0f

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    
    [self.preTitleLabel sizeToFit];
    CGRect preFrame = self.preTitleLabel.frame;
    preFrame.origin = CGPointMake(LEFTMARGIN , 14);
    self.preTitleLabel.frame = preFrame;
    
    
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake(self.titleLabel.frame.size.width / 2
                                         + self.preTitleLabel.frame.size.width
                                         + self.preTitleLabel.frame.origin.x
                                         + 5,
                                         self.preTitleLabel.center.y );
    
    
    self.iconView.center = CGPointMake(LEFTMARGIN / 2, self.titleLabel.center.y);
    
    
    CGFloat leftY = self.preTitleLabel.frame.size.height + self.preTitleLabel.frame.origin.y;;
    CGSize size = [[self class] heightForText:self.subtitle andWidth:self.bounds.size.width];
    CGRect subFrame = CGRectMake(LEFTMARGIN,leftY + 10,size.width,size.height);
    self.subTitleLabel.frame = subFrame;
    if (subFrame.size.height != 0)
    {
        leftY = subFrame.size.height + subFrame.origin.y;
    }
    
    
    
    CGSize imgsize = self.screenShotSize;
    CGFloat maxW = self.bounds.size.width / 2 - LEFTMARGIN;
    CGFloat maxH = MAX_IMG_HEIGHT;
    
    CGFloat scale = MAX(imgsize.width / maxW, imgsize.height / maxH);
    if (scale < 1)
    {
        scale = 1;
    }
    imgsize.width /= scale;
    imgsize.height /= scale;
    
    self.screenShotView.frame = CGRectMake(LEFTMARGIN, leftY + 10, imgsize.width, imgsize.height);
    
    if (imgsize.height)
    {
        leftY = self.screenShotView.frame.size.height + self.screenShotView.frame.origin.y;
    }
    
    
    
    if (self.commentViews.count)
    {
        leftY += 6;
        for (UIButton *btn in self.commentViews)
        {
            CGSize size = [btn sizeThatFits:CGSizeMake(self.bounds.size.width - LEFTMARGIN - RIGHTMARGIN, CGFLOAT_MAX)];
            btn.frame = CGRectMake(LEFTMARGIN,
                                   leftY,
                                   size.width ,
                                   size.height);
            leftY += size.height;
        }
    }
    
    
    NSInteger rightY = 6;
    if (self.rightViews.count)
    {
        for (UIButton *btn in self.rightViews)
        {
            rightY += 4;
            CGSize size = [btn sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)];
            size.height += 2;
            size.width += 10;
            
            btn.frame = CGRectMake(self.bounds.size.width - RIGHTMARGIN - size.width,
                                   rightY,
                                   size.width,
                                   size.height);
            
            rightY += size.height;
            
        }
    }
    
    
    CGFloat y = MAX(leftY , rightY);
    if (self.bottomButtons.count)
    {
        y += 10;
        self.bottomButtonsSubline.frame = CGRectMake(0, y, self.contentView.bounds.size.width, 1);
        NSInteger width = self.contentView.bounds.size.width / self.bottomButtons.count;
        CGFloat btnX = 0;
        for (NSInteger i = 0 ; i < self.bottomButtons.count; i++)
        {
            UIControl *btn = self.bottomButtons[i];
            btn.frame = CGRectMake(btnX, y, width, 42);
            btnX += width;
        }
        y += 42;
    }
    else
    {
        y += 10;
    }
    y += GrowingEventListBaseCellSublineHeight;
    _preferredHeight = y;
}

+ (CGSize)heightForText:(NSString*)text andWidth:(CGFloat)width
{
    static UILabel *subTitlelabel = nil;
    if (!subTitlelabel)
    {
        subTitlelabel = [[UILabel alloc] init];
        subTitlelabel.numberOfLines = 0;
        subTitlelabel.font = [UIFont systemFontOfSize:SUBTITLESIZE];
    }
    
    subTitlelabel.text = text;
    CGSize size = [subTitlelabel sizeThatFits:CGSizeMake(width - 20, CGFLOAT_MAX)];
    return size;
    
}

+ (UILabel*)createTitleView
{
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 1;
    label.font = [UIFont systemFontOfSize:TITLESIZE];
    label.textColor = [GrowingUIConfig eventListTextColor];
    return label;
}

+ (UILabel*)createSubtitleView
{
    UILabel *label2 = [[UILabel alloc] init];
    label2.numberOfLines = 0;
    label2.font = [UIFont systemFontOfSize:SUBTITLESIZE];
    label2.textColor = [GrowingUIConfig eventListTextColor];
    return label2;
}

@end
