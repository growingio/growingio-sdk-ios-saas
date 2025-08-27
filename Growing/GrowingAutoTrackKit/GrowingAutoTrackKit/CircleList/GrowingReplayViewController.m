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


#import "GrowingReplayViewController.h"
#import "GrowingUIConfig.h"

@interface GrowingReplayViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>


@property (nonatomic, retain) NSArray<GrowingEventListItem*> *items;

@property (nonatomic, retain) UIImageView *mainImageView;
@property (nonatomic, retain) UIImage     *mainImage;
@property (nonatomic, assign) NSInteger   curImageIndex;

@property (nonatomic, retain) UICollectionView *thumbCollection;

@property (nonatomic, retain) NSTimer *timer;

@end


@interface GrowingReplayThumbCell : UICollectionViewCell
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIImageView *imageView;
@end

@implementation GrowingReplayThumbCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageView.clipsToBounds = YES;
        [self.contentView addSubview:self.imageView];
        self.imageView.contentMode = UIViewContentModeScaleToFill;
        
        self.imageView.layer.borderColor = [GrowingUIConfig circleListMainColor].CGColor;
        self.imageView.layer.borderWidth = 1;
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
}

@end


#define CELL_WIDTH 80
#define THUMB_BAR_HEGIHT 80

@implementation GrowingReplayViewController

- (instancetype)initWithItems:(NSArray<GrowingEventListItem *> *)items
{
    self = [self initWithNibName:nil bundle:nil];
    if (self)
    {
        self.view.backgroundColor = [UIColor blackColor];
        _curImageIndex = -1;
        NSMutableArray *filterItems = [[NSMutableArray alloc] init];
        for (GrowingEventListItem * item in items)
        {
            if (item.cacheImage)
            {
                [filterItems insertObject:item atIndex:0];
            }
        }
        self.items = filterItems;
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(closeClick)];
        
    }
    return self;
}

- (void)closeClick
{
    if (self.onCloseClick)
    {
        self.onCloseClick();
    }

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.timer =
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(playNext)
                                   userInfo:nil
                                    repeats:YES];
    self.curImageIndex = 0;
}

- (void)playNext
{
    self.curImageIndex++;
    if (self.curImageIndex >= self.items.count)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mainImageView = [[UIImageView alloc] init];
    [self.view addSubview:self.mainImageView];
    
    UICollectionViewFlowLayout*layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(THUMB_BAR_HEGIHT, CELL_WIDTH);
    layout.sectionInset = UIEdgeInsetsZero;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    
    UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - THUMB_BAR_HEGIHT, self.view.bounds.size.width, THUMB_BAR_HEGIHT) collectionViewLayout:layout];
    [self.view addSubview:view];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    view.delegate = self;
    view.dataSource = self;
    view.alwaysBounceHorizontal = YES;
    view.contentInset = UIEdgeInsetsMake(0,
                                         self.view.bounds.size.width / 2 - CELL_WIDTH / 2,
                                         0,
                                         self.view.bounds.size.width / 2 - CELL_WIDTH / 2);
    [view registerClass:[GrowingReplayThumbCell class] forCellWithReuseIdentifier:@"cell"];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GrowingReplayThumbCell *cell = (id)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell"
                                                                            forIndexPath:indexPath];
    GrowingImageCacheImage *image = [self.items[indexPath.row] cacheImage];
    if (image)
    {
        [image loadImage:^(UIImage *image) {
            cell.image = image;
        }];
    }
    else
    {
        cell.image = nil;
    }
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat baseX = - self.view.bounds.size.width / 2 + CELL_WIDTH / 2;
    CGFloat x = scrollView.contentOffset.x - baseX;
    NSInteger index = x / CELL_WIDTH;
    if (index < 0)
    {
        index = 0;
    }
    if (index >= self.items.count)
    {
        index = self.items.count - 1;
    }
    self.curImageIndex = index;
}

- (void)setCurImageIndex:(NSInteger)curImageIndex
{
    if (_curImageIndex == curImageIndex)
    {
        return;
    }
    if (self.items.count == 0)
    {
        return;
    }
    
    if (curImageIndex < 0)
    {
        curImageIndex = 0;
    }
    if (curImageIndex >= self.items.count)
    {
        curImageIndex = self.items.count - 1;
    }
    
    _curImageIndex = curImageIndex;

    [[self.items[curImageIndex] cacheImage] loadImage:^(UIImage *image) {
        self.mainImage = image;
    }];
}

#define MAIN_IMG_MARGIN_LEFT 20
#define MAIN_IMG_MARGIN_TOP 20


- (void)setMainImage:(UIImage *)mainImage
{
    _mainImage = mainImage;
    self.mainImageView.image = mainImage;
    CGSize maxImgSize = CGSizeMake(self.view.bounds.size.width - MAIN_IMG_MARGIN_LEFT * 2,
                                self.view.bounds.size.height - self.topLayoutGuide.length - THUMB_BAR_HEGIHT - MAIN_IMG_MARGIN_TOP * 2);
    CGSize imageSize = mainImage.size;
    CGFloat scale = MIN( maxImgSize.width / imageSize.width , maxImgSize.height / imageSize.height);
    if (scale > 1)
    {
        scale = 1;
    }
    imageSize.width = (NSInteger)(imageSize.width * scale);
    imageSize.height = (NSInteger)(imageSize.height * scale);
    
    
    self.mainImageView.frame = CGRectMake(self.view.bounds.size.width / 2 - imageSize.width / 2,
                                          MAIN_IMG_MARGIN_TOP + self.topLayoutGuide.length + maxImgSize.height / 2 - imageSize.height / 2 ,
                                          imageSize.width,
                                          imageSize.height);
    
}


@end
