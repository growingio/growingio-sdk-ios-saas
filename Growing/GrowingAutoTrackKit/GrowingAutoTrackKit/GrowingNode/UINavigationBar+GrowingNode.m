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


#import "UINavigationBar+GrowingNode.h"
#import "NSObject+GrowingHelper.h"
#import "UINavigationBar+Growing.h"
#import "GrowingCategory.h"

@implementation UINavigationBar (Growing_xPath)

- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs
                             outPaths:(NSMutableArray *)paths
                      filterChildNode:(id<GrowingNode>)aNode
{
    [super growingNodeOutContainerChilds:childs outPaths:paths filterChildNode:aNode];
    UIView *view = nil;
    if ([self growingHelper_getIvar:"_titleView" outObj:&view] && view)
    {
        GrowingAddChildNode(view,
                            (@"titleView"),
                            (NSStringFromClass([view class])));
    }
    
    NSArray *views = nil;
    if (self.growing_backButtonView)
    {
        GrowingAddChildNode(self.growing_backButtonView,
                            (@"backButton"))
    }
    
    
    if ([self growingHelper_getIvar:"_leftViews" outObj:&views] && views.count)
    {
        for (NSInteger i = 0 ; i < views.count ; i ++)
        {
            UIView *v = views[i];
            GrowingAddChildNode(v,
                                (@"leftViews"),
                                (NSStringFromClass([v class]),i));
        }
    }
    
    if ([self growingHelper_getIvar:"_rightViews" outObj:&views] && views.count)
    {
        for (NSInteger i = 0 ; i < views.count ; i ++)
        {
            UIView *v = views[i];
            GrowingAddChildNode(v,
                                (@"rightViews"),
                                (NSStringFromClass([v class]),i));
        }
    }
}

@end


@interface GrowingCategory(GrowingNavigationBarBackButton,
                           (UINavigationItemButtonView,([NSString stringWithFormat:@"UI%@Item%@View",@"Navigation",@"Button"])))


- (BOOL)growingNodeUserInteraction
{
    return YES;
}

- (NSString*)growingNodeName
{
    return @"返回按钮";
}

- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs
                             outPaths:(NSMutableArray *)paths
                      filterChildNode:(id<GrowingNode>)aNode
{
    
}

- (void)growingNodeOutChilds:(NSMutableArray*)childs
                    outPaths:(NSMutableArray*)paths
             filterChildNode:(id<GrowingNode>)aNode
{
    
}

@end
