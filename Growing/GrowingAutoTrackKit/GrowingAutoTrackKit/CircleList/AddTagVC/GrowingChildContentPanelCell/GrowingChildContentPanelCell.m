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


#import "GrowingChildContentPanelCell.h"
#import "GrowingRealtimeBarChartView.h"
#import "GrowingRealtimeLineChartView.h"
#import "GrowingUIConfig.h"
#import "UIControl+GrowingHelper.h"
#import "GrowingChildContentPanel.h"


@interface GrowingChildContentPanelCellBase()

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) GrowingElement *element;
@property (nonatomic, retain) GrowingImageCacheImage *image;

@property (nonatomic, retain) UIView *mainContentView;
@property (nonatomic, retain) UIView *chartContentView;

@property (nonatomic, retain) UIButton *saveButton;

@end

#define LEFT_MARGIN 15
#define RIGHT_MARGIN 15
#define TOP_MARGIN 10
#define BOTTOM_HEIGHT 50

#define CHART_Y 60


#define IMAGE_TOP_MARGIN  15
#define IMAGE_BOTTOM_MARGIN 15
#define LINECHART_HEIGHT 240
#define LINECHART_BOTTOM_MARGIN 30

@implementation GrowingChildContentPanelCellBase

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        
        UIView *mainContentView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                          0,
                                                                          self.bounds.size.width,
                                                                           self.bounds.size.height)];
        self.mainContentView = mainContentView;
        mainContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        mainContentView.backgroundColor = [UIColor whiteColor];
        mainContentView.layer.borderWidth = 1;
        mainContentView.layer.borderColor = [GrowingUIConfig circleListMainColor].CGColor;
        mainContentView.layer.cornerRadius = 6;
        [self.contentView addSubview:mainContentView];
        
        
        
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_MARGIN,
                                                                 TOP_MARGIN,
                                                                 self.bounds.size.width - LEFT_MARGIN - RIGHT_MARGIN,
                                                                 20)];
        [lbl.growingAutoResizeMakeObject width];
        lbl.font = [UIFont systemFontOfSize:14];
        lbl.textColor = [GrowingUIConfig eventListTextColor];
        self.titleLabel = lbl;
        [mainContentView addSubview:lbl];
        
        
        self.chartContentView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                         CHART_Y,
                                                                         mainContentView.bounds.size.width,
                                                                         mainContentView.bounds.size.height
                                                                            - CHART_Y
                                                                            - BOTTOM_HEIGHT)];
        self.chartContentView.backgroundColor = [UIColor clearColor];
        [mainContentView addSubview:self.chartContentView];
        
        
        UIButton *btnSave = [[UIButton alloc] initWithFrame:CGRectMake(0,
                                                                       mainContentView.bounds.size.height - BOTTOM_HEIGHT,
                                                                       mainContentView.bounds.size.width,
                                                                       BOTTOM_HEIGHT)];
        btnSave.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.saveButton = btnSave;
        NSMutableAttributedString *titleStr =
        [[NSMutableAttributedString alloc] initWithString:@"保存指标"];
        [titleStr addAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16],
                                  NSForegroundColorAttributeName : [GrowingUIConfig eventListTextColor]}
                          range:NSMakeRange(0, titleStr.length)];
        [self.saveButton setAttributedTitle:titleStr forState:0];
       
        @weakify(self);
        btnSave.growingHelper_onClick = ^{
            @strongify(self);
            [self saveClick];
        };
        [mainContentView addSubview:btnSave];
        
        
        UIView *btnSubline = [[UIView alloc] initWithFrame:CGRectMake(0,0,btnSave.bounds.size.width, 1)];
        btnSubline.backgroundColor = [GrowingUIConfig circleListMainColor];
        [btnSubline.growingAutoResizeMakeObject.width set];
        [btnSave addSubview:btnSubline];
    }
    return self;
}

- (void)closeClick
{
    if ([self.delegate respondsToSelector:@selector(GrowingChildContentPanelCell:didClickCloseWithElement:)])
    {
        [self.delegate GrowingChildContentPanelCell:self didClickCloseWithElement:self.element];
    }
}

- (void)saveElement:(GrowingElement*)element withName:(NSString*)name
{
    if (!element)
    {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(GrowingChildContentPanelCell:didClickSaveWithElement:withName:)])
    {
        [self.delegate GrowingChildContentPanelCell:self didClickSaveWithElement:element withName:name];
    }
}

- (void)saveClick
{
    [self saveElement:self.element withName:self.title];
}

- (GrowingElement*)elementForSave
{
    return self.element;
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    self.titleLabel.text = title;
}

- (void)loadElement:(GrowingElement *)element andImage:(GrowingImageCacheImage *)image
{
    self.image = image;
    self.element = element;
}

@end


@interface GrowingChildContentPanelBarCell()
@property (nonatomic, assign) BOOL enableSave;
@property (nonatomic, retain) GrowingRealtimeBarChartView *barChartView;
@end
@implementation GrowingChildContentPanelBarCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.enableSave = YES;
}

- (GrowingElement*)elementForSave
{
    GrowingElement *element = [[super elementForSave] copy];
    element.content = nil;
    return element;
}

- (void)setEnableSave:(BOOL)enableSave
{
    _enableSave = enableSave;
    
    NSMutableAttributedString *titleStr =
    [[NSMutableAttributedString alloc] initWithString:enableSave ? @"保存指标" : @"收起线图"];
    [titleStr addAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16],
                              NSForegroundColorAttributeName : [GrowingUIConfig eventListTextColor]}
                      range:NSMakeRange(0, titleStr.length)];
    [self.saveButton setAttributedTitle:titleStr forState:0];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self =[super initWithFrame:frame];
    if (self)
    {
        self.barChartView = [[GrowingRealtimeBarChartView alloc] initWithFrame:self.chartContentView.bounds];
        self.barChartView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.chartContentView addSubview:self.barChartView];
        
        
        GrowingRealtimeBarChartView *chart = self.barChartView;
        @weakify(self,chart);
        
        [chart setOnSaveElement:^(GrowingElement *element) {
            @strongify(self);
            [self saveElement:element withName:[NSString stringWithFormat:@"%@的点击",element.content]];
        }];
        
        [chart setOnDetailIndexChange:^(NSIndexPath *index , BOOL animated) {
            @strongify(self);
            self.enableSave = (index == nil);
        }];
        
        
        self.saveButton.growingHelper_onClick = ^{
            @strongify(self,chart);
            
            if (self.enableSave)
            {
                GrowingElement *element = [self.element copy];
                element.content = nil;
                [self saveElement:element withName:self.title];
            }
            else
            {
                [chart closeDetailView:YES];
            }
        };
    }
    return self;
}

- (void)loadElement:(GrowingElement *)element andImage:(GrowingImageCacheImage *)image
{
    [super loadElement:element andImage:image];
    [self.barChartView loadElement:element];
}


@end

@interface GrowingChildContentPanelLineCell()
@property (nonatomic, retain) GrowingDetaiLineChartlView *lineChartView;
@property (nonatomic, retain) UIImageView *screenShotImageView;
@end


@implementation GrowingChildContentPanelLineCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.screenShotImageView = [[UIImageView alloc] init];
        self.screenShotImageView.layer.borderColor = [GrowingUIConfig circleListMainColor].CGColor;
        self.screenShotImageView.layer.borderWidth = 1;
        self.screenShotImageView.layer.cornerRadius = 5;
        [self.chartContentView addSubview:self.screenShotImageView];
        
        
        self.lineChartView =
        [[GrowingDetaiLineChartlView alloc] initWithFrame:CGRectMake(0,
                                                                     self.chartContentView.bounds.size.height
                                                                        - LINECHART_HEIGHT
                                                                        - LINECHART_BOTTOM_MARGIN,
                                                                     self.chartContentView.bounds.size.width - 10,
                                                                     LINECHART_HEIGHT)];
        self.lineChartView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.lineChartView.backgroundColor = [UIColor whiteColor];
        [self.chartContentView addSubview:self.lineChartView];
    }
    return self;
}

- (void)loadElement:(GrowingElement *)element andImage:(GrowingImageCacheImage *)image
{
    [super loadElement:element andImage:image];
    [image loadImage:^(UIImage *image) {
        self.screenShotImageView.image = image;
        [self setNeedsLayout];
    }];
    
    [self.lineChartView loadElement:element];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    BOOL hideImageView = YES;
    if (self.screenShotImageView.image)
    {
        CGSize maxImgSize = CGSizeMake(self.bounds.size.width - 60,
                                       self.chartContentView.bounds.size.height - LINECHART_HEIGHT - LINECHART_BOTTOM_MARGIN - IMAGE_TOP_MARGIN - IMAGE_BOTTOM_MARGIN);
        CGSize imageSize = self.screenShotImageView.image.size;
        if (imageSize.height > 0 && imageSize.width > 0 && maxImgSize.width > 0 && maxImgSize.height > 0)
        {
            hideImageView = NO;
            
            CGFloat scale = MIN( maxImgSize.width / imageSize.width , maxImgSize.height / imageSize.height);
            if (scale > 1)
            {
                scale = 1;
            }
            imageSize.width = (NSInteger)(imageSize.width * scale);
            imageSize.height = (NSInteger)(imageSize.height * scale);
            
            
            self.screenShotImageView.frame =
            CGRectMake((NSInteger)(self.chartContentView.bounds.size.width / 2 - imageSize.width / 2),
                       (NSInteger)(IMAGE_TOP_MARGIN + maxImgSize.height / 2 - imageSize.height / 2),
                        imageSize.width,
                        imageSize.height);
        }
    }
    
    self.screenShotImageView.hidden = hideImageView;
}

@end
