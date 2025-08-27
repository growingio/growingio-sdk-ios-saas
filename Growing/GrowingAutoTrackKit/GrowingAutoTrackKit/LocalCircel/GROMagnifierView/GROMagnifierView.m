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


#import "GROMagnifierView.h"
#import "GRMTriangleView.h"
#import "GrowingGlobal.h"

@interface GROMagnifierView()
@property (nonatomic, retain) UIImageView *snapshotImageView;
@property (nonatomic, retain) GRMTriangleView *triangleView;
@end


@implementation GROMagnifierView
+ (instancetype)magnifierViewWithSnapshotImage: (UIImage *) snapshotImage position: (GROMagnifierPosition) position borderColro: (UIColor *) borderColor
{
    CGRect magnifierFrame;
    switch (position) {
        case Left:
        case Right:
            magnifierFrame = CGRectMake(0, 0, g_magnifierWidth * 1.2 , g_magnifierHeight);
            break;
        case Above:
            magnifierFrame = CGRectMake(0, 0, g_magnifierWidth  , g_magnifierHeight * 1.2);
            break;
        default:
            break;
    }
    GROMagnifierView *magnifierView = [[GROMagnifierView alloc] initWithFrame: magnifierFrame];
    
    magnifierView.snapshotImageView = [[UIImageView alloc] initWithImage: snapshotImage];
    CGRect triangleFrame = CGRectMake(0, 0, g_magnifierHeight * 0.2 , g_magnifierHeight * 0.2);
    magnifierView.triangleView = [[GRMTriangleView alloc] initWithFrame: triangleFrame];
    magnifierView.triangleView.fillColor = borderColor;
    
    
    magnifierView.snapshotImageView.layer.cornerRadius = 5;
    magnifierView.snapshotImageView.layer.borderWidth = 3;
    magnifierView.snapshotImageView.layer.borderColor = borderColor.CGColor;
    magnifierView.snapshotImageView.clipsToBounds = YES;
    
    [magnifierView refreshWithSnapshotImage:snapshotImage position:position];
    
    [magnifierView.triangleView setBackgroundColor: [UIColor clearColor]];
    
    [magnifierView addSubview: magnifierView.snapshotImageView];
    [magnifierView addSubview: magnifierView.triangleView];
    
    return magnifierView;
}

- (void)refreshWithSnapshotImage: (UIImage *) snapshotImage position: (GROMagnifierPosition) position;
{
    self.snapshotImageView.image = snapshotImage;
    
    self.triangleView.transform = CGAffineTransformMakeRotation(  M_PI_2 + M_PI_2 * position);
    
    CGFloat snapshotImageViewWidth = self.snapshotImageView.bounds.size.width;
    CGFloat snapshotImageViewHeight = self.snapshotImageView.bounds.size.height;
    
    CGFloat triangleViewWidth = self.triangleView.bounds.size.width;
    CGFloat triangleViewHeight = self.triangleView.bounds.size.height;
    
    [self.snapshotImageView setCenter: CGPointMake( snapshotImageViewWidth / 2, snapshotImageViewHeight / 2)];
    
    switch (position) {
        case Left:
            self.triangleView.center =
            CGPointMake( snapshotImageViewWidth + triangleViewWidth / 2 , snapshotImageViewHeight / 2);
            break;
        case Right:
            self.triangleView.center =
            CGPointMake( triangleViewWidth / 2 , snapshotImageViewHeight / 2);
            
            self.snapshotImageView.center =
            CGPointMake(snapshotImageViewWidth / 2 + triangleViewWidth, snapshotImageViewHeight / 2);
            break;
        case Above:
            self.triangleView.center =
            CGPointMake( snapshotImageViewWidth / 2 , snapshotImageViewHeight + triangleViewHeight / 2);
            break;
        default:
            break;
    }
}

@end
