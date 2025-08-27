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


#import "GrowingEventListAction.h"
#import "UIApplication+GrowingHelper.h"
#import "UIImage+GrowingHelper.h"


#define imageScale 1

@implementation GrowingEventListActionAppLifeCycle

- (BOOL)eventlist_item:(GrowingEventListItem *)item canShowWithStyle:(GrowingChildContentPanelStyle)style
{
    return NO;
}

- (void)eventlist_addElementFromItem:(GrowingEventListItem *)item
                chartStyle:(GrowingChildContentPanelStyle)style
                  forPanel:(GrowingChildContentPanel *)panel
{
    
}

- (UIImage*)eventlist_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode
                                         thisNode:(id<GrowingNode>)thisNode
                                             item:(GrowingEventListItem *)item
{
    return nil;
}

- (UIImage*)replay_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode
                                      thisNode:(id<GrowingNode>)thisNode
                                          item:(GrowingEventListItem *)item
{
    return nil;
}

@end

@implementation GrowingEventListActionPage

- (BOOL)eventlist_item:(GrowingEventListItem *)item canShowWithStyle:(GrowingChildContentPanelStyle)style
{
    if (style == GrowingChildContentPanelStyleLine)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)eventlist_addElementFromItem:(GrowingEventListItem *)item
                chartStyle:(GrowingChildContentPanelStyle)style
                  forPanel:(GrowingChildContentPanel *)panel
{
    NSString *name = [[NSString alloc] initWithFormat:@"页面:%@的显示总量(PV)",
                      item.childItems.firstObject.element.page];
    [panel addElement:[item.childItems.firstObject.element copy]
                image:item.cacheImage
                 name:name
            withStyle:style];
}

- (UIImage*)eventlist_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode
                                         thisNode:(id<GrowingNode>)thisNode
                                             item:(GrowingEventListItem *)item
{
    return [[UIApplication sharedApplication] growingHelper_screenshotWithGrowingWindow:imageScale];
}

- (UIImage*)replay_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode
                                      thisNode:(id<GrowingNode>)thisNode
                                          item:(GrowingEventListItem *)item
{
    return [self eventlist_screenShotWithTriggerNode:triggerNode
                                              thisNode:thisNode
                                                  item:item];
}


@end

@implementation GrowingEventListActionUserInteraction

- (BOOL)eventlist_item:(GrowingEventListItem *)item canShowWithStyle:(GrowingChildContentPanelStyle)style
{
    if (style == GrowingChildContentPanelStyleLine)
    {
        return YES;
    }
    else
    {
        for (GrowingEventListChildItem *child in item.childItems)
        {
            if (child.element.content.length)
            {
                return YES;
            }
        }
        return NO;
    }
}

- (void)eventlist_addElementFromItem:(GrowingEventListItem *)item
                chartStyle:(GrowingChildContentPanelStyle)style
                  forPanel:(GrowingChildContentPanel *)panel
{
    
    NSMutableArray<GrowingEventListChildItem*> *childs = [[NSMutableArray alloc] initWithArray:item.childItems];
    
    
    if (GrowingChildContentPanelStyleLine == style
        && childs.count
        && childs.firstObject.element.index != [GrowingNodeItemComponent indexNotDefine])
    {
        GrowingElement *e1 = [childs.firstObject.element copy];
        GrowingElement *e2 = [e1 copy];
        
        e1.content = nil;
        e2.content = nil;
        e2.index = [GrowingNodeItemComponent indexNotDefine];
        
        [panel addElement:e1
                    image:item.cacheImage
                     name:[NSString stringWithFormat:@"第%d行的点击量",(int)e1.index + 1]
                withStyle:style];
        
        [panel addElement:e2
                    image:item.cacheImage
                     name:@"所有行的点击量总数"
                withStyle:style];
        [childs removeObjectAtIndex:0];
    }

    
    for (GrowingEventListChildItem *child in childs)
    {
        if (GrowingChildContentPanelStyleLine == style 
            || child.element.content )
        {
            GrowingElement *e = [child.element copy];
            
            e.index = [GrowingNodeItemComponent indexNotDefine];
            
            NSString *title = nil;
            if (style == GrowingChildContentPanelStyleLine)
            {
                if (e.content.length)
                {
                    title = [[NSString alloc] initWithFormat:@"\"%@按钮\"的点击量",e.content];
                }
                else
                {
                    title = @"按钮的点击量";
                }
            }
            else
            {
                title = [NSString stringWithFormat:@"点击时\"%@\"位置的文本",e.content];
            }
            
            [panel addElement:e
                        image:item.cacheImage
                         name:title
                    withStyle:style];
        }
    }
}

- (UIImage*)eventlist_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode thisNode:(id<GrowingNode>)thisNode item:(GrowingEventListItem *)item
{
    if (item.cacheImage)
    {
        return nil;
    }
    
    CGRect nodeFrame = [triggerNode growingNodeFrame];
    UIImage *img =
    [[UIApplication sharedApplication] growingHelper_screenshotWithGrowingWindow:imageScale
                                                                           block:^(CGContextRef context) {
                                                                               CGContextClipToRect(context, nodeFrame);
                                                                               CGContextSetStrokeColorWithColor(context,[UIColor redColor].CGColor);
                                                                               CGContextSetLineWidth(context, 5);
                                                                               CGContextStrokeRect(context, nodeFrame);
                                                                           }];
    
    CGRect cutFrame = nodeFrame;
    CGFloat scale = 2.5f;
    cutFrame.size.width *= scale;
    cutFrame.size.height *= scale;
    cutFrame.size.width = MAX(cutFrame.size.width, 150);
    cutFrame.size.height = MAX(cutFrame.size.height, 150);
    
    cutFrame.origin.x = nodeFrame.size.width / 2 + nodeFrame.origin.x - cutFrame.size.width / 2;
    cutFrame.origin.y = nodeFrame.size.height / 2 + nodeFrame.origin.y - cutFrame.size.height / 2;
    if (cutFrame.origin.x < 0)
    {
        cutFrame.size.width += cutFrame.origin.x;
        cutFrame.origin.x = 0;
    }
    if (cutFrame.origin.y < 0)
    {
        cutFrame.size.height += cutFrame.origin.y;
        cutFrame.origin.y = 0;
    }
    
    cutFrame.size.width = MIN([UIScreen mainScreen].bounds.size.width - cutFrame.origin.x,
                              cutFrame.size.width);
    cutFrame.size.height = MIN([UIScreen mainScreen].bounds.size.height - cutFrame.origin.y,
                               cutFrame.size.height);
    return [img growingHelper_getSubImage:cutFrame];
}

- (UIImage*)replay_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode thisNode:(id<GrowingNode>)thisNode item:(GrowingEventListItem *)item
{
    if (item.cacheImage)
    {
        return nil;
    }
    
    return [[UIApplication sharedApplication] growingHelper_screenshotWithGrowingWindow:imageScale];
}

@end

@implementation GrowingEventListActionUI

- (BOOL)eventlist_item:(GrowingEventListItem *)item canShowWithStyle:(GrowingChildContentPanelStyle)style
{
    return NO;
}

- (void)eventlist_addElementFromItem:(GrowingEventListItem *)item
                chartStyle:(GrowingChildContentPanelStyle)style
                  forPanel:(GrowingChildContentPanel *)panel
{
    
    
}

- (UIImage*)eventlist_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode thisNode:(id<GrowingNode>)thisNode item:(GrowingEventListItem *)item
{
    return nil;
}

- (UIImage*)replay_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode thisNode:(id<GrowingNode>)thisNode item:(GrowingEventListItem *)item
{
    return nil;
}

@end

@implementation GrowingEventListActionNetWork

- (BOOL)eventlist_item:(GrowingEventListItem *)item canShowWithStyle:(GrowingChildContentPanelStyle)style
{
    return NO;
}

- (void)eventlist_addElementFromItem:(GrowingEventListItem *)item
                chartStyle:(GrowingChildContentPanelStyle)style
                  forPanel:(GrowingChildContentPanel *)panel
{
    
}

- (UIImage*)eventlist_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode thisNode:(id<GrowingNode>)thisNode item:(GrowingEventListItem *)item
{
    return nil;
}

- (UIImage*)replay_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode thisNode:(id<GrowingNode>)thisNode item:(GrowingEventListItem *)item
{
    return nil;
}

@end
