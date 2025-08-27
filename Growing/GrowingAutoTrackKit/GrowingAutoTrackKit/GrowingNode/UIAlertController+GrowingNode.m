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


#import "UIAlertController+GrowingNode.h"
#import "UIAlertController+Growing.h"
#import "GrowingCategory.h"
#import "NSObject+GrowingHelper.h"

@implementation UIAlertController (GrowingNode)


- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs outPaths:(NSMutableArray *)paths filterChildNode:(id<GrowingNode>)aNode
{
    
    NSMapTable *allButton = [self growing_allActionViews];
    for (UIView *view in  [allButton keyEnumerator])
    {
        NSNumber *n = [allButton objectForKey:view];;
        GrowingAddChildNode(view,
                            (@"button",[n integerValue]));
    }
    
    UIView *view = nil;
    if ([self.view growingHelper_getIvar:"_titleLabel" outObj:&view])
    {
        GrowingAddChildNode(view,
                            (@"title"));
    }
    if ([self.view growingHelper_getIvar:"_messageLabel" outObj:&view])
    {
        GrowingAddChildNode(view,
                            (@"message"));
    }
}

- (void)growingNodeHighLight:(BOOL)highLight
             withBorderColor:(UIColor *)borderColor
          andBackgroundColor:(UIColor *)backgroundColor
{
    [self.view growingNodeHighLight:highLight
                    withBorderColor:borderColor
                 andBackgroundColor:backgroundColor];
}

- (CGRect)growingNodeFrame
{
    return [self.view growingNodeFrame];
}

@end


@interface GrowingCategory(growingAlertVCActionView,
                          (_UIAlertControllerCollectionViewCell,([NSString stringWithFormat:@"_UI%@Controller%@",@"Alert",@"CollectionViewCell"])),
                          (_UIAlertControllerActionView,([NSString stringWithFormat:@"_UI%@Controller%@View",@"Alert",@"Action"])))

- (void)growingNodeOutContainerChilds:(NSMutableArray*)childs
                             outPaths:(NSMutableArray*)paths
                      filterChildNode:(id<GrowingNode>)aNode
{
    
}

- (void)growingNodeOutChilds:(NSMutableArray*)childs
                    outPaths:(NSMutableArray*)paths
             filterChildNode:(id<GrowingNode>)aNode
{
    
}

- (BOOL)growingNodeUserInteraction
{
    return YES;
}

- (NSString*)growingNodeName
{
    return @"弹出框选项";
}
- (NSString*)growingNodeContent
{
    NSString *nodeContent = [[UIAlertController growing_actionForActionView:(id)self] title];
    
    if (nodeContent.length) {
        return nodeContent;
    } else {
        return self.accessibilityLabel;
    }
}

@end
