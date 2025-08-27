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


#import "GRMTriangleView.h"

@implementation GRMTriangleView

- (void)setFillColor:(UIColor *)fillColor
{
    _fillColor = fillColor;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGSize selfBoundsSize = self.bounds.size;
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint: CGPointMake( 0, selfBoundsSize.height)];
    [path addLineToPoint: CGPointMake( selfBoundsSize.width / 2, 0)];
    [path addLineToPoint: CGPointMake( selfBoundsSize.width , selfBoundsSize.height)];
    [path closePath];
    
    [self.fillColor setFill];
    [path fill];
}

@end
