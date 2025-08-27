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


#import "UISegmentedControl+GrowingNode.h"
#import "UISegmentedControl+Growing.h"
#import "UIView+GrowingNode.h"
#import "GrowingCategory.h"


@interface UISegmentedControl ()<GrowingNode>


@end

@implementation UISegmentedControl (GrowingNode)

- (void)growingNodeOutChilds:(NSMutableArray *)childs
                    outPaths:(NSMutableArray *)paths
             filterChildNode:(id<GrowingNode>)aNode
{
}

- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs
                             outPaths:(NSMutableArray *)paths
                      filterChildNode:(id<GrowingNode>)aNode
{
    NSArray *children = self.growing_segmentViews;
    for (NSUInteger i = 0; i < children.count; i++)
    {
        GrowingAddChildNode(children[i],
                            (@"segment", (NSInteger)i));
    }
}

- (BOOL)growingViewUserInteraction
{
    return NO; 
}

@end



@interface GrowingCategory(GrowingSegmentButton,
                          (UISegment,([NSString stringWithFormat:@"UI%@ment",@"Seg"])))

- (BOOL)growingViewUserInteraction
{
    return YES;
}

- (NSString*)growingNodeName
{
    return @"按钮";
}

- (void)growingNodeOutChilds:(NSMutableArray *)childs
                    outPaths:(NSMutableArray *)paths
             filterChildNode:(id<GrowingNode>)aNode
{
}

- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs
                             outPaths:(NSMutableArray *)paths
                      filterChildNode:(id<GrowingNode>)aNode
{
}

- (NSString*)growingNodeContent
{
    NSString *nodeContent = [UISegmentedControl growing_titleForSegment:(id)self];
    if (nodeContent.length) {
        return nodeContent;
    } else {
        return self.accessibilityLabel;
    }
}

@end
