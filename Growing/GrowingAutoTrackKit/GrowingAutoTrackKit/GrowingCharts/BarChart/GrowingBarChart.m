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


#import "GrowingBarChart.h"
#import "UIControl+GrowingHelper.h"
#import "NSNumber+GrowingHelper.h"
#import "GrowingUIConfig.h"

@interface GrowingBarChartRow : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger value;
@property (nonatomic, copy)   NSString *valueText;
@property (nonatomic, retain) UIColor *color;

@property (nonatomic, assign) CGFloat valueWidth;
@property (nonatomic, assign) CGFloat textWidth;

@property (nonatomic, copy) void(^onClick)(NSIndexPath *index);

@end

@implementation GrowingBarChartRow

@end

@interface GrowingBarChartCell : UICollectionViewCell


@property (nonatomic, assign)   CGFloat     leftMargin;
@property (nonatomic, assign)   CGFloat     rightMargin;
@property (nonatomic, assign)   CGFloat     innerMargin;
@property (nonatomic, assign)   CGFloat     valueTextMargin;
@property (nonatomic, assign)   CGFloat     rowHeight;

@property (nonatomic, assign)   CGFloat     zeroBarWidth;


@property (nonatomic, copy)     NSString    *title;
@property (nonatomic, assign)   CGFloat     titleWidth;


@property (nonatomic, copy)     NSString    *valueText;
@property (nonatomic, assign)   CGFloat     valueWidth;

@property (nonatomic, assign)   NSInteger   value;
@property (nonatomic, assign)   NSInteger   maxValue;


@property (nonatomic, retain)   UIColor     *barColor;
@property (nonatomic, retain)   UIColor     *maxBarColor;
@property (nonatomic, retain)   UIColor     *minBarColor;


@property (nonatomic, retain)   UILabel     *titleLabel;
@property (nonatomic, retain)   UIView      *barView;
@property (nonatomic, retain)   UIView      *barBgView;
@property (nonatomic, retain)   UILabel     *valueLabel;
@property (nonatomic, retain)   UIView      *tapGestView;


@property (nonatomic, retain)   UIView      *detailView;

@property (nonatomic, copy)     void(^onClick)();

@end

@implementation GrowingBarChartCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.onClick = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.valueTextMargin = 10;
        self.zeroBarWidth = 5;
        self.clipsToBounds = YES;
        self.contentView.clipsToBounds = YES;
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.titleLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:self.titleLabel];
        
        self.valueLabel = [[UILabel alloc] init];
        self.valueLabel.textColor = [UIColor grayColor];
        self.valueLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.valueLabel];
        
        self.barBgView = [[UIView alloc] init];
        self.barBgView.userInteractionEnabled = NO;
        self.barBgView.backgroundColor = C_R_G_B(235, 235, 235);
        [self.contentView addSubview:self.barBgView];
        
        self.barView = [[UIView alloc] init];
        self.barView.userInteractionEnabled = NO;
        [self.contentView addSubview:self.barView];
        
        self.tapGestView = [[UIView alloc] init];
        [self.contentView addSubview:self.tapGestView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGest)];
        [self.tapGestView addGestureRecognizer:tap];
    }
    return self;
}

- (void)tapGest
{
    if (self.onClick)
    {
        self.onClick();
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
}


- (void)setLeftMargin:(CGFloat)leftMargin
{
    _leftMargin = leftMargin;
    [self setNeedsLayout];
}
- (void)setRightMargin:(CGFloat)rightMargin
{
    _rightMargin = rightMargin;
    [self setNeedsLayout];
}
- (void)setInnerMargin:(CGFloat)innerMargin
{
    _innerMargin = innerMargin;
    [self setNeedsLayout];
}
- (void)setRowHeight:(CGFloat)rowHeight
{
    _rowHeight = rowHeight;
    [self setNeedsLayout];
}



- (void)setTitleWidth:(CGFloat)titleWidth
{
    _titleWidth = titleWidth;
    [self setNeedsLayout];
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    self.titleLabel.text = title;
    [self setNeedsLayout];
}


- (void)setValue:(NSInteger)value
{
    _value = value ;
    [self setNeedsLayout];
}

- (void)setMaxValue:(NSInteger)maxValue
{
    _maxValue = maxValue;
    [self setNeedsLayout];
}

- (void)setValueText:(NSString *)valueText
{
    _valueText = [valueText copy];
    self.valueLabel.text = valueText;
    [self setNeedsLayout];
}

- (void)setValueWidth:(CGFloat)valueWidth
{
    _valueWidth = valueWidth;
    [self setNeedsLayout];
}


- (void)setBarColor:(UIColor *)barColor
{
    _barColor = barColor;
    [self setNeedsLayout];
}

- (void)setMaxBarColor:(UIColor *)maxBarColor
{
    _maxBarColor = maxBarColor;
    [self setNeedsLayout];
}

- (void)setMinBarColor:(UIColor *)minBarColor
{
    _minBarColor = minBarColor;
    [self setNeedsLayout];
}

- (void)setDetailView:(UIView *)detailView
{
    if (_detailView == detailView)
    {
        return;
    }
    [_detailView removeFromSuperview];
    _detailView = detailView;
    [self addSubview:detailView];

    [self setNeedsLayout];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.tapGestView.frame = CGRectMake(0,0,self.bounds.size.width,self.rowHeight);
    
    
    CGFloat maxValueWidth = self.bounds.size.width
                            - self.leftMargin
                            - self.rightMargin
                            - self.zeroBarWidth;
    
    CGFloat percent = 0;
    if (self.maxValue > 0 )
    {
        percent = self.value *1.0f / self.maxValue;
    }
    
    CGRect valueFrame = CGRectMake(self.leftMargin,
                                   20,
                                   (maxValueWidth * percent + self.zeroBarWidth),
                                   15);
    self.barView.frame = valueFrame;
    
    
    CGRect valueBgFrame = valueFrame;
    valueBgFrame.size.width = maxValueWidth + self.zeroBarWidth;
    
    self.barBgView.frame = valueBgFrame;
    
    
    
    if (self.barColor)
    {
        self.barView.backgroundColor = self.barColor;
    }
    else
    {
        CGFloat r1,g1,b1,a1=1,r2,g2,b2,a2=1;
        [self.maxBarColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
        [self.minBarColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
        
#define GETVAUEBY(COLORNAME)  GrowingGetPercentValue(COLORNAME ## 2, COLORNAME ## 1, percent)
        
        self.barView.backgroundColor = [[UIColor alloc] initWithRed:GETVAUEBY(r)
                                                              green:GETVAUEBY(g)
                                                               blue:GETVAUEBY(b)
                                                              alpha:GETVAUEBY(a)];
    }
    
    
    CGSize valueTextSize = [self.valueLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    CGRect valueLableFrame = CGRectMake(self.bounds.size.width
                                            - valueTextSize.width
                                            - self.rightMargin,
                                        valueFrame.origin.y
                                            - valueTextSize.height,
                                        valueTextSize.width,
                                        valueTextSize.height);
    self.valueLabel.frame = valueLableFrame;
    
    
    CGSize titleTextSize = [self.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX,CGFLOAT_MAX)];
    CGFloat maxTitleWidth = valueLableFrame.origin.x - self.leftMargin - self.valueTextMargin ;
    self.titleLabel.frame = CGRectMake(self.leftMargin,
                                       valueFrame.origin.y - titleTextSize.height,
                                       MIN(titleTextSize.width,maxTitleWidth) ,
                                       titleTextSize.height);
    
    
    if (self.detailView)
    {
        self.detailView.frame = CGRectMake(0,
                                           self.rowHeight,
                                           self.bounds.size.width,
                                           self.detailView.frame.size.height);
    }
    
    
}

@end




@interface GrowingBarChart()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (nonatomic, retain) NSMutableArray<GrowingBarChartRow*> *allRows;
@property (nonatomic, assign) NSInteger maxValue;
@property (nonatomic, assign) CGFloat currentMaxTitleWidth;
@property (nonatomic, assign) CGFloat currentMaxValueWidth;

@property (nonatomic, retain) UIFont *titleFont;
@property (nonatomic, retain) NSDictionary *titleFontAttr;

@property (nonatomic, retain) UIFont *valueFont;
@property (nonatomic, retain) NSDictionary *valueFontAttr;

@property (nonatomic, retain) UIView *detailView;
@property (nonatomic, assign) CGFloat detalViewHeight;

@property (nonatomic, retain) UICollectionView *tableView;
@property (nonatomic, retain) UICollectionViewFlowLayout *layout;

@end

@implementation GrowingBarChart

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.allRows.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSIndexPath *detailIndex = self.detailIndex;
    if (detailIndex && detailIndex.row == indexPath.row && detailIndex.section == indexPath.section)
    {
        return CGSizeMake(collectionView.bounds.size.width,  self.rowHeight + self.detalViewHeight);
    }
    else
    {
        return CGSizeMake(collectionView.bounds.size.width, self.rowHeight);
    }
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GrowingBarChartCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell"
                                                                          forIndexPath:indexPath];
    GrowingBarChartRow *row = self.allRows[indexPath.row];
    
        
    cell.titleLabel.font = self.titleFont;
    cell.valueLabel.font = self.valueFont;
    cell.rowHeight = self.rowHeight;
    cell.leftMargin = 25;
    cell.rightMargin = 25;
    cell.innerMargin = 10;

    cell.backgroundColor = self.backgroundColor;
    cell.barColor = row.color;
    cell.maxBarColor = self.maxBarColor;
    cell.minBarColor = self.minBarColor;
    cell.title = row.title;
    cell.value = row.value;
    cell.valueText = row.valueText;
    cell.maxValue = self.maxValue;
    cell.titleWidth = self.currentMaxTitleWidth;
    cell.valueWidth = self.currentMaxValueWidth;
    
    if ([self.detailIndex isEqual:indexPath] && self.detailView)
    {
        cell.detailView = self.detailView;
    }
    
    cell.onClick = ^{
        if (row.onClick)
        {
            row.onClick(indexPath);
        }
    };
    
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}












- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.layout = layout;
        self.tableView = [[UICollectionView alloc] initWithFrame:self.bounds
                                            collectionViewLayout:layout];
        self.tableView.alwaysBounceVertical = YES;
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.tableView registerClass:[GrowingBarChartCell class]
           forCellWithReuseIdentifier:@"cell"];
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self addSubview:self.tableView];
        
        
        self.rowHeight = 45;
        
        self.titleFont = [UIFont systemFontOfSize:12];
        self.titleFontAttr = @{UITextAttributeFont:self.titleFont};
        
        self.valueFont = [UIFont systemFontOfSize:12];
        self.valueFontAttr = @{UITextAttributeFont:self.valueFont};
        
        self.allRows = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)clearAll
{
    [self closeDetailView:NO];
    self.maxValue = 0;
    self.currentMaxTitleWidth = 0;
    [self.allRows removeAllObjects];
    [self.tableView reloadData];
    
}

- (NSIndexPath*)addTitle:(NSString *)title value:(NSInteger)value
{
    return [self addTitle:title value:value color:nil onClick:nil];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    [self.tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.backgroundColor = backgroundColor;
    }];
}

- (NSIndexPath*)addTitle:(NSString *)title
                   value:(NSInteger)value
                   color:(UIColor *)color
                 onClick:(void (^)(NSIndexPath *))onClick
{
    return [self addTitle:title
                    value:value
                valueText:nil
                    color:color
                  onClick:onClick];
}

- (NSIndexPath*)addTitle:(NSString *)title
                   value:(NSInteger)value
               valueText:(NSString *)valueText
                   color:(UIColor *)color
                 onClick:(void (^)(NSIndexPath *))onClick
{
    
    GrowingBarChartRow *row =[[ GrowingBarChartRow alloc] init];
    row.title = title;
    row.value = value;
    row.color = color;
    row.onClick = onClick;
    
    
    
    
    CGSize size = [title sizeWithAttributes:self.titleFontAttr];
    row.textWidth = size.width;
    self.currentMaxTitleWidth = MAX(self.minTitleWidth, MAX(self.currentMaxTitleWidth, size.width));
    self.currentMaxTitleWidth = MIN(self.currentMaxTitleWidth, self.maxTitleWidth);
    
    
    self.maxValue = MAX(self.maxValue , value);
    if (valueText == nil)
    {
        valueText = [[NSString alloc] initWithFormat:@"%ld",(long)value];
    }
    size = [valueText sizeWithAttributes:self.valueFontAttr];
    row.valueWidth = size.width;
    row.valueText = valueText;
    self.currentMaxValueWidth = MAX(self.currentMaxValueWidth, size.width);
    
    [self.allRows addObject:row];
    NSIndexPath *index = [NSIndexPath indexPathForRow:self.allRows.count - 1 inSection:0];
    [self.tableView insertItemsAtIndexPaths:@[index]];
    return index;
}

- (CGFloat)maxTitleWidth
{
    if (_maxTitleWidth == 0)
    {
        return 85;
    }
    return _maxTitleWidth;
}

- (CGFloat)minTitleWidth
{
    if (_minTitleWidth == 0)
    {
        return self.bounds.size.width / 5;
    }
    return _minTitleWidth;
}

- (void)makeVisiableCellDoBlock:(void(^)(GrowingBarChartCell *cell))block
{
    [self.tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj);
    }];
}


#define SETUPDATECELL(THETYPE,SETTER,GETTER,SETBLOCK)          \
- (void)SETTER:(THETYPE)GETTER                                      \
{                                                                   \
    if (_ ## GETTER == GETTER)                                      \
    {                                                               \
        return;                                                     \
    }                                                               \
    _ ## GETTER = GETTER;                                           \
    [self makeVisiableCellDoBlock:^(GrowingBarChartCell *cell) {    \
        SETBLOCK;                                                   \
    }];                                                             \
}

SETUPDATECELL(CGFloat  , setCurrentMaxTitleWidth, currentMaxTitleWidth, cell.titleWidth = currentMaxTitleWidth)
SETUPDATECELL(CGFloat  , setCurrentMaxValueWidth, currentMaxValueWidth, cell.valueWidth = currentMaxValueWidth)
SETUPDATECELL(NSInteger, setMaxValue,             maxValue, cell.maxValue = maxValue)
SETUPDATECELL(UIColor* , setMaxBarColor, maxBarColor, cell.maxBarColor = maxBarColor)
SETUPDATECELL(UIColor* , setMinBarColor, minBarColor, cell.minBarColor = minBarColor)



- (void)addDetailView:(UIView *)detalView forIndexPath:(NSIndexPath *)index animated:(BOOL)animated
{
    GrowingBarChartCell *oldCell = (id)[self.tableView cellForItemAtIndexPath:self.detailIndex];
    GrowingBarChartCell *curCell = (id)[self.tableView cellForItemAtIndexPath:index];
    _detailIndex = index;
    self.detailView = detalView;
    curCell.detailView = detalView;
    self.detalViewHeight = detalView.frame.size.height;
    
    if (animated)
    {
        [self.tableView performBatchUpdates:nil
                                 completion:^(BOOL finished) {
                                     if (oldCell != curCell)
                                     {
                                         oldCell.detailView = nil;
                                     }
                                 }];
    }
    else
    {
        oldCell.detailView = nil;
        [self.layout invalidateLayout];
    }
    [self.tableView scrollToItemAtIndexPath:index
                           atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                   animated:animated];
    if (self.onDetailIndexChange)
    {
        self.onDetailIndexChange(index,animated);
    }
}

- (void)closeDetailView:(BOOL)animated
{
    [self addDetailView:nil forIndexPath:nil animated:animated];
}

@end
