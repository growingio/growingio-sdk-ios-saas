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


#import "UISegmentedControl+Growing.h"
#import "FoSwizzling.h"
#import "FoDefineProperty.h"
#import "GrowingAutoTrackEvent.h"
#import "UIImage+GrowingHook.h"
#import "NSObject+GrowingHelper.h"
#import "GrowingGlobal.h"

@implementation UISegmentedControl (Growing)

+ (UILabel*)growing_labelForSegment:(UIView*)segment
{
    UILabel *lable = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([segment respondsToSelector:@selector(label)])
    {
        lable = [segment performSelector:@selector(label)];
    }
#pragma clang diagnostic pop
#if DEBUG
    else
    {
        
        assert(0);
    }
#endif
    return lable;
}

+ (NSString*)growing_titleForSegment:(UIView *)segment
{
    return [self growing_labelForSegment:segment].text;
}

- (NSArray*)growing_segmentViews
{
    NSArray *array = nil;
    if( [self growingHelper_getIvar:"_segments" outObj:&array])
    {
        return array;
    }
    return nil;
}

@end

@interface UISegmentedControlGrowingObserver : NSObject
+ (instancetype)shareInstance;
- (void)growingSegmentAction:(UISegmentedControl *)segmentControl;
@end

void growingUISegmentedControlSetUp(UISegmentedControl *self)
{
    NSSet *allTargets = nil;
    @autoreleasepool {
        allTargets = self.allTargets;
    }
    
    if ([allTargets containsObject:[UISegmentedControlGrowingObserver shareInstance]])
    {
        return;
    }
    [self addTarget:[UISegmentedControlGrowingObserver shareInstance]
             action:@selector(growingSegmentAction:)
   forControlEvents:UIControlEventValueChanged];
}


FoHookInstance(UISegmentedControl, @selector(initWithFrame:),
               id, CGRect frame)
{
    id ret = FoHookOrgin(frame);
    growingUISegmentedControlSetUp(self);
    return ret;
}
FoHookEnd


FoHookInstance(UISegmentedControl, @selector(initWithCoder:),
               id, NSCoder * aDecoder)
{
    id ret = FoHookOrgin(aDecoder);
    growingUISegmentedControlSetUp(self);
    return ret;
}
FoHookEnd


FoHookInstance(UISegmentedControl, @selector(initWithItems:),
               id, NSArray * _Nullable items)
{
    id ret = FoHookOrgin(items);
    growingUISegmentedControlSetUp(self);
    return ret;
}
FoHookEnd



@implementation UISegmentedControlGrowingObserver

+ (instancetype)shareInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)growingSegmentAction:(UISegmentedControl *)segmentControl
{
    
    NSInteger index = segmentControl.selectedSegmentIndex;
    NSArray *arr    = segmentControl.growing_segmentViews;
    
    if (index >= 0 && index < arr.count)
    {
        [GrowingClickEvent sendEventWithNode:arr[index] andEventType:GrowingEventTypeSegmentControlSelect];
    }
}

@end

static UIView *growingGetSegLabelView(UIView* segLabel)
{
    UISegmentedControl *seg = (id)segLabel;
    while (seg && ![seg isKindOfClass:[UISegmentedControl class]])
    {
        seg = (id)[seg superview];
    }
    if (!seg)
    {
        return nil;
    }
    
    for (UIView * v in [seg growing_segmentViews])
    {
        if ([UISegmentedControl growing_labelForSegment:v] == segLabel)
        {
            return v;
        }
    }
    return nil;
}


FoHookInstancePlus(([NSString stringWithFormat:@"UI%@Label",@"Segment"].UTF8String), UILabel*,@selector(setText:), void,NSString *text)
{
    NSString *oldText = self.text;
    FoHookOrgin(text);
    
    if (!g_enableImp)
    {
        return;
    }

    id node = growingGetSegLabelView(self);
    if (node && self.text.length && ![oldText isEqualToString:self.text] )
    {
        [GrowingImpressionEvent sendEventWithNode:node andEventType:GrowingEventTypeSegmentSetTitle];
    }
}
FoHookEnd

FoHookInstancePlus(([NSString stringWithFormat:@"UI%@Label",@"Segment"].UTF8String), UILabel*,@selector(didMoveToSuperview), void)
{
    FoHookOrgin();
    
    if (!g_enableImp)
    {
        return;
    }

    id node = growingGetSegLabelView(self);
    if (node && self.superview && self.window)
    {
        [GrowingImpressionEvent sendEventWithNode:node andEventType:GrowingEventTypeSegmentSetTitle];
    }
}
FoHookEnd
