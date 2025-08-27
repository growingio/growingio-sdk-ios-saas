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


#import "UITableView+GrowingNode.h"
#import "UITableView+Growing.h"
#import "GrowingAttributesConst.h"
#import <pthread.h>


@implementation UITableView(Growing_xPath)


- (id)growingNodeAttribute:(NSString *)attrbute
{
    if (attrbute == GrowingAttributeIsHorizontalTableKey)
    {
        CGRect rect = CGRectMake(0, 0, 10, 20);
        rect = [self convertRect:rect toView:self.window];
        if (rect.size.width > rect.size.height)
        {
            
            return GrowingAttributeReturnYESKey;
        }
    }
    return nil;
}

- (id)growingNodeAttribute:(NSString *)attrbute forChild:(id<GrowingNode>)node
{
    if (attrbute == GrowingAttributeIsWithinRowOfTableKey)
    {
        if ([self.growingHook_allCreatedCells containsObject:node])
        {
            return GrowingAttributeReturnYESKey;
        }
    }
    return nil;
}

- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs
                             outPaths:(NSMutableArray *)paths
                      filterChildNode:(id<GrowingNode>)aNode
{
    pthread_mutex_t * pMutex = getUITableViewMutexPointer();
    pthread_mutex_lock(pMutex);
    

    [super growingNodeOutContainerChilds:childs outPaths:paths filterChildNode:aNode];
    for (UITableViewCell * cell in self.growingHook_allCreatedCells)
    {
        GrowingAddChildNodeWithReturnBlock(^{pthread_mutex_unlock(pMutex);},
                                           cell,
                                           ([NSStringFromClass(self.class) stringByAppendingString:@"Section"] ,
                                            cell.growingHook_indexPath.section ,
                                            YES ),
                                           (NSStringFromClass(cell.class) ,
                                            cell.growingHook_indexPath.row,
                                            YES));
    }

    
    pthread_mutex_unlock(pMutex);
}

@end

@interface UITableViewCell(GrowingNode)

@end

@implementation UITableViewCell(GrowingNode)

- (void)growingNodeOutChilds:(NSMutableArray *)childs
                    outPaths:(NSMutableArray *)paths
             filterChildNode:(id<GrowingNode>)aNode
{
    NSUInteger i = 0;
    UIView * cell = self;
    
    
    
    
    
    
    
    
    for (UIView * v in cell.subviews)
    {
        if (v == self.selectedBackgroundView)
        {
            continue;
        }
        else
        {
            GrowingAddChildNode(v,
                                (NSStringFromClass(v.class), i));
            i++;
        }
    }
}

- (id<GrowingNode>)growingNodeParent
{
    id<GrowingNode> parent = self.growingHook_parentTableviewWeakShell.obj;
    if (parent == nil)
    {
        parent = [super growingNodeParent];
    }
    return parent;
}

- (BOOL)growingNodeUserInteraction
{
    return YES;
}

- (NSString*)growingNodeName
{
    __kindof UIView * curView = self;
    UITableView * tableView = nil;
    while (curView != nil)
    {
        if ([curView isKindOfClass:[UITableView class]])
        {
            tableView = curView;
            break;
        }
        curView = curView.superview;
    }
    if (tableView == nil)
    {
        return @"列表项";
    }
    return [tableView growingNodeAttribute:GrowingAttributeIsHorizontalTableKey] == GrowingAttributeReturnYESKey ? @"横滑列表项" : @"竖滑列表项";
}

- (BOOL)growingNodeDonotTrack
{
    
    if ([self growingHook_indexPath] && !self.growingAttributesDonotTrack)
    {
        return NO;
    }
    return [super growingNodeDonotTrack];
}

- (BOOL)growingNodeDonotCircle
{
    return [super growingNodeDonotCircle];
}



@end
