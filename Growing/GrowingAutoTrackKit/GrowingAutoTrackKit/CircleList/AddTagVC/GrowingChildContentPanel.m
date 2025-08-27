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


#import "GrowingChildContentPanel.h"
#import "UIView+GrowingHelperLayout.h"
#import "GrowingBarChart.h"
#import "GrowingDetaiLineChartlView.h"
#import "GrowingChildContentPanelCell.h"


@interface GrowingChildContentPanelItem : NSObject
@property (nonatomic, retain) GrowingElement *element;
@property (nonatomic, retain) GrowingImageCacheImage *cacheImage;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) GrowingChildContentPanelStyle style;
@end
@implementation GrowingChildContentPanelItem
@end


@interface GrowingChildContentPanel()<UICollectionViewDelegate,
                                        UICollectionViewDataSource,
                                        UICollectionViewDelegateFlowLayout,
                                        GrowingChildContentPanelCellDelegate>

@property (nonatomic, retain) NSMutableArray<GrowingChildContentPanelItem *> *items;

@property (nonatomic, retain) UICollectionView *collectionView;

@end




@implementation GrowingChildContentPanel

- (void)addElement:(GrowingElement *)element
             image:(GrowingImageCacheImage *)cacheImage
              name:(NSString *)name
         withStyle:(GrowingChildContentPanelStyle)style
{
    GrowingChildContentPanelItem *item = [[GrowingChildContentPanelItem alloc] init];
    item.element = element;
    item.name = name;
    item.style = style;
    item.cacheImage = cacheImage;
    [self.items addObject:item];
    [self.collectionView reloadData];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.items = [[NSMutableArray alloc] init];
        
        self.backgroundColor = [UIColor clearColor];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds
                                                              collectionViewLayout:layout];
        self.collectionView = collectionView;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.alwaysBounceHorizontal = YES;
        
        
        [collectionView registerClass:[GrowingChildContentPanelLineCell class] forCellWithReuseIdentifier:@"linecell"];
        [collectionView registerClass:[GrowingChildContentPanelBarCell class] forCellWithReuseIdentifier:@"barcell"];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        
        collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:collectionView];
        
    }
    return self;
}

- (GrowingMenuShowType)showType
{
    return GrowingMenuShowTypePresent;
}

#define LEFT_MARGIN 15
#define RIGHT_MARGIN LEFT_MARGIN
#define INNTER_MARGIN 10
#define TOP_MARGIN    15
#define BOTTOM_MARGIN 15

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.bounds.size.width - LEFT_MARGIN - RIGHT_MARGIN,
                      collectionView.bounds.size.height - TOP_MARGIN - BOTTOM_MARGIN);
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(TOP_MARGIN, LEFT_MARGIN, BOTTOM_MARGIN, RIGHT_MARGIN );
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return INNTER_MARGIN;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return INNTER_MARGIN;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GrowingChildContentPanelItem *item = self.items[indexPath.row];
    NSString *reuseId = item.style == GrowingChildContentPanelStyleBar ? @"barcell" : @"linecell";
    GrowingChildContentPanelCellBase *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId
                                                                                       forIndexPath:indexPath];
    cell.delegate = self;
    [cell loadElement:item.element andImage:item.cacheImage];
    cell.title = item.name;
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGFloat add = 0;
    NSInteger width = scrollView.bounds.size.width - LEFT_MARGIN - RIGHT_MARGIN + INNTER_MARGIN;
    if (velocity.x > 0)
    {
        add = width;
    }
    
    (*targetContentOffset).x = (((NSInteger)((*targetContentOffset).x)) / width * width ) + add;
}


- (void)GrowingChildContentPanelCell:(GrowingChildContentPanelCellBase*)cell
            didClickCloseWithElement:(GrowingElement*)element
{

}

- (void)GrowingChildContentPanelCell:(GrowingChildContentPanelCellBase*)cell
             didClickSaveWithElement:(GrowingElement*)element
                            withName:(NSString *)name
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (!indexPath)
    {
        return;
    }
    
    if (self.onSaveElement)
    {
        self.onSaveElement(self,name, self.items[indexPath.row].element , element);
    }
    
}

@end
