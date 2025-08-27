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


#import "Growing3rdLibUULineChart.h"
#import "Growing3rdLibUUColor.h"
#import "Growing3rdLibUUChartLabel.h"
#import "GrowingInstance.h"


@implementation Growing3rdLibUULineChart {
    NSHashTable *_chartLabelsForX;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.clipsToBounds = NO;
    }
    return self;
}

-(void)setYValues:(NSArray *)yValues
{
    _yValues = yValues;
    [self setYLabels:yValues];
}

-(NSString *)getYLabelString:(CGFloat)value withMax:(CGFloat)max
{
    const NSInteger K = 1000;
    const NSInteger M = K * K;
    const NSInteger G = M * K;
    NSInteger unit = 1;
    NSString * unitName = @"";
    if (max > G)
    {
        unit = G;
        unitName = @"G";
    }
    else if (max > M)
    {
        unit = M;
        unitName = @"M";
    }
    else if (max > K)
    {
        unit = K;
        unitName = @"K";
    }
    if (unit > 1) 
    {
        value /= (CGFloat)unit;
        if (value >= 100)
        {
            return [NSString stringWithFormat:@"%.0lf%@", value, unitName];
        }
        else if (value >= 10)
        {
            return [NSString stringWithFormat:@"%.1lf%@", value, unitName];
        }
        else
        {
            return [NSString stringWithFormat:@"%.2lf%@", value, unitName];
        }
    }
    else
    {
        return [NSString stringWithFormat:@"%.0lf", value];
    }
}

-(void)setYLabels:(NSArray *)yLabels
{
    NSInteger max = 0;
    NSInteger min = NSIntegerMax;

    for (NSArray * ary in yLabels) {
        for (NSString *valueString in ary) {
            NSInteger value = [valueString integerValue];
            if (value > max) {
                max = value;
            }
            if (value < min) {
                min = value;
            }
        }
    }
    if (max < 4) {
        max = 4;
    } else if (max < 1000) {
        max = (max + 3) / 4 * 4; 
    }
    if (self.showRange) {
        _yValueMin = min;
    }else{
        _yValueMin = 0;
    }
    _yValueMax = max;
    
    if (_chooseRange.max!=_chooseRange.min) {
        _yValueMax = _chooseRange.max;
        _yValueMin = _chooseRange.min;
    }

    float level = (_yValueMax-_yValueMin) /4.0;
    CGFloat chartCavanHeight = self.frame.size.height - (UULabelHeight*3+GlobalOffsetY);
    CGFloat levelHeight = chartCavanHeight /4.0;

    for (int i=0; i<5; i++) {
        Growing3rdLibUUChartLabel * label = [[Growing3rdLibUUChartLabel alloc] initWithFrame:CGRectMake(0.0,chartCavanHeight-i*levelHeight+5+GlobalOffsetY, UUYLabelwidth, UULabelHeight)];
        label.text = [self getYLabelString:(level * i + _yValueMin) withMax:_yValueMax];
		[self addSubview:label];
    }
    if ([super respondsToSelector:@selector(setMarkRange:)]) {
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(UUYLabelwidth, (1-(_markRange.max-_yValueMin)/(_yValueMax-_yValueMin))*chartCavanHeight+UULabelHeight, self.frame.size.width-UUYLabelwidth, (_markRange.max-_markRange.min)/(_yValueMax-_yValueMin)*chartCavanHeight)];
        view.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.1];
        [self addSubview:view];
    }

    
    for (int i=0; i<5; i++) {
        if ([_ShowHorizonLine[i] integerValue]>0) {
            
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(UUYLabelwidth,UULabelHeight+i*levelHeight+GlobalOffsetY)];
            [path addLineToPoint:CGPointMake(self.frame.size.width,UULabelHeight+i*levelHeight+GlobalOffsetY)];
            [path closePath];
            shapeLayer.path = path.CGPath;
            shapeLayer.strokeColor = [[[UIColor blackColor] colorWithAlphaComponent:0.1] CGColor];
            shapeLayer.fillColor = [[UIColor whiteColor] CGColor];
            shapeLayer.lineWidth = 1;
            if ([GrowingInstance circleType] == GrowingCircleTypeEventList)
            {
                
                if (i != 4)
                {
                    [shapeLayer setLineJoin:kCALineJoinRound];
                    [shapeLayer setLineDashPattern:@[@10,@5]];
                }
            }
            [self.layer addSublayer:shapeLayer];
        }
    }
}

-(void)setXLabels:(NSArray *)xLabels
{
    if( !_chartLabelsForX ){
        _chartLabelsForX = [NSHashTable weakObjectsHashTable];
    }
    
    _xLabels = xLabels;
    CGFloat num = 0;
    if (xLabels.count>=20) {
        num=20.0;
    }else if (xLabels.count<=1){
        num=1.0;
    }else{
        num = xLabels.count;
    }
    _xLabelWidth = (self.frame.size.width - UUYLabelwidth)/num;
    
    for (int i=0; i<xLabels.count; i++) {
        NSString *labelText = xLabels[i];
        Growing3rdLibUUChartLabel * label = [[Growing3rdLibUUChartLabel alloc] initWithFrame:CGRectMake(i * _xLabelWidth+UUYLabelwidth, self.frame.size.height - UULabelHeight, _xLabelWidth, UULabelHeight)];
        label.text = labelText;
        [self addSubview:label];
        
        [_chartLabelsForX addObject:label];
    }
    
    
    for (int i=0; i<xLabels.count+1; i++) {
        if ([GrowingInstance circleType] == GrowingCircleTypeEventList)
        {
            
            
            if (i != 0)
            {
                break;
            }
            
        }
        
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(UUYLabelwidth+i*_xLabelWidth,UULabelHeight+GlobalOffsetY)];
        [path addLineToPoint:CGPointMake(UUYLabelwidth+i*_xLabelWidth,self.frame.size.height-2*UULabelHeight)];
        [path closePath];
        shapeLayer.path = path.CGPath;
        shapeLayer.strokeColor = [[[UIColor blackColor] colorWithAlphaComponent:0.1] CGColor];
        shapeLayer.fillColor = [[UIColor whiteColor] CGColor];
        shapeLayer.lineWidth = 1;
        [self.layer addSublayer:shapeLayer];
    }
}

-(void)setColors:(NSArray *)colors
{
	_colors = colors;
}

-(void)setLineNames:(NSArray *)names
{
    _lineNames = names;
}

- (void)setMarkRange:(CGRange)markRange
{
    _markRange = markRange;
}

- (void)setChooseRange:(CGRange)chooseRange
{
    _chooseRange = chooseRange;
}

- (void)setShowHorizonLine:(NSMutableArray *)ShowHorizonLine
{
    _ShowHorizonLine = ShowHorizonLine;
}

- (void)addPoint:(CGPoint)point
   withLastPoint:(CGPoint)lastPoint
          toPath:(UIBezierPath*)path
{





    [path addLineToPoint:point];
}

-(void)strokeChart
{
    for (int i=0; i<_yValues.count; i++) {
        NSArray *childAry = _yValues[i];
        if (childAry.count==0) {
            return;
        }
        
        CGFloat max = [childAry[0] floatValue];
        CGFloat min = [childAry[0] floatValue];
        NSInteger max_i = 0;
        NSInteger min_i = 0;
        
        for (int j=0; j<childAry.count; j++){
            CGFloat num = [childAry[j] floatValue];
            if (max<=num){
                max = num;
                max_i = j;
            }
            if (min>=num){
                min = num;
                min_i = j;
            }
        }
        
        
        CAShapeLayer *_chartLine = [CAShapeLayer layer];
        _chartLine.lineCap = kCALineCapRound;
        _chartLine.lineJoin = kCALineJoinBevel;
        _chartLine.fillColor   = [[UIColor whiteColor] CGColor];
        _chartLine.lineWidth   = 2.0;
        _chartLine.strokeEnd   = 0.0;
        [self.layer addSublayer:_chartLine];
        
        UIBezierPath *progressline = [UIBezierPath bezierPath];
        CGFloat firstValue = [[childAry objectAtIndex:0] floatValue];
        CGFloat xPosition = (UUYLabelwidth + _xLabelWidth/2.0);
        CGFloat chartCavanHeight = self.frame.size.height - (UULabelHeight*3+GlobalOffsetY);
        
        float grade = ((float)firstValue-_yValueMin) / ((float)_yValueMax-_yValueMin);
       
        
        BOOL isShowMaxAndMinPoint = YES;
        if (self.ShowMaxMinArray) {
            if ([self.ShowMaxMinArray[i] intValue]>0) {
                isShowMaxAndMinPoint = (max_i==0 || min_i==0)?NO:YES;
            }else{
                isShowMaxAndMinPoint = YES;
            }
        }
        [self addPoint:CGPointMake(xPosition, chartCavanHeight - grade * chartCavanHeight+UULabelHeight+GlobalOffsetY)
                 index:i
                isShow:isShowMaxAndMinPoint
                 value:firstValue];

        CGPoint lastPoint = 
        CGPointMake(xPosition, chartCavanHeight - grade * chartCavanHeight+UULabelHeight+GlobalOffsetY);
        [progressline moveToPoint:lastPoint];
        [progressline setLineWidth:2.0];
        [progressline setLineCapStyle:kCGLineCapRound];
        [progressline setLineJoinStyle:kCGLineJoinRound];
        NSInteger index = 0;
        for (NSString * valueString in childAry) {
            
            float grade =([valueString floatValue]-_yValueMin) / ((float)_yValueMax-_yValueMin);
            if (index != 0) {
                CGPoint point = CGPointMake(xPosition+index*_xLabelWidth, chartCavanHeight - grade * chartCavanHeight+UULabelHeight+GlobalOffsetY);
                [self addPoint:point withLastPoint:lastPoint toPath:progressline];
                lastPoint = point;
                
                
                BOOL isShowMaxAndMinPoint = YES;
                if (self.ShowMaxMinArray) {
                    if ([self.ShowMaxMinArray[i] intValue]>0) {
                        isShowMaxAndMinPoint = (max_i==index || min_i==index)?NO:YES;
                    }else{
                        isShowMaxAndMinPoint = YES;
                    }
                }
                [progressline moveToPoint:point];
                [self addPoint:point
                         index:i
                        isShow:isShowMaxAndMinPoint
                         value:[valueString floatValue]];
                

            }
            index += 1;
        }
        
        



        
        _chartLine.path = progressline.CGPath;
        if ([[_colors objectAtIndex:i] CGColor]) {
            _chartLine.strokeColor = [[_colors objectAtIndex:i] CGColor];
        }else{
            _chartLine.strokeColor = [UUGreen CGColor];
        }
        CABasicAnimation *pathAnimation = nil;
        pathAnimation.duration = 0.35;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        pathAnimation.autoreverses = NO;
        [_chartLine addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
        
        _chartLine.strokeEnd = 1.0;
    }
}

- (void)addPoint:(CGPoint)point index:(NSInteger)index isShow:(BOOL)isHollow value:(CGFloat)value
{
    if ([GrowingInstance circleType] == GrowingCircleTypeEventList)
    {
        
        isHollow = NO;
    }
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(5, 5, 8, 8)];
    view.center = point;
    view.layer.masksToBounds = YES;
    view.layer.cornerRadius = 4;



    if (isHollow) {
        view.backgroundColor = [UIColor clearColor];
    }else{
        view.backgroundColor = [_colors objectAtIndex:index]?[_colors objectAtIndex:index]:UUGreen;
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(point.x-UUTagLabelwidth/2.0, point.y-UULabelHeight*1.6, UUTagLabelwidth, UULabelHeight)];
        label.font = [UIFont systemFontOfSize:10];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = view.backgroundColor;
        label.text = [NSString stringWithFormat:@"%d",(int)value];
        [self addSubview:label];
    }
    
    [self addSubview:view];
}

- (void)drawLegend
{
    const CGFloat fontSize = 10;
    const CGFloat legendHeight = UULabelHeight;
    const CGFloat gap = 2;
    CGFloat chartCavanWidth = self.frame.size.width;

    UIView * legend = [[UIView alloc] init];
    NSUInteger count = (self.colors.count < self.lineNames.count ? self.colors.count : self.lineNames.count);
    CGFloat x = 0;
    for (NSUInteger i = 0; i < count; i++)
    {
        if (self.lineNames.count == 0)
        {
            continue;
        }
        
        NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:self.lineNames[i]];
        NSRange allRange = NSMakeRange(0, string.length);
        [string addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize] range:allRange];
        CGRect rect = [string boundingRectWithSize:CGSizeMake(CGFLOAT_MAX,legendHeight)
                                           options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                           context:nil];
        rect = CGRectOffset(rect, x, 0);
        UILabel * label = [[UILabel alloc] initWithFrame:rect];
        label.attributedText = string;
        [legend addSubview:label];
        x += rect.size.width + gap;
        
        UIView * dot = [[UIView alloc] initWithFrame:CGRectMake(x, 1, legendHeight, legendHeight)];
        dot.layer.cornerRadius = legendHeight / 2;
        dot.layer.borderWidth = legendHeight / 2;
        dot.layer.borderColor = ((UIColor *)[self.colors objectAtIndex:i]).CGColor;
        [legend addSubview:dot];
        x += dot.frame.size.width + gap;
        
        x += gap*2;
    }
    legend.frame = CGRectMake(chartCavanWidth - x, 0, x, legendHeight);
    [self addSubview:legend];
}

- (NSArray *)chartLabelsForX
{
    return [_chartLabelsForX allObjects];
}

@end
