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


#import "UICollectionView+Growing.h"
#import "UICollectionView+GrowingNode.h"
#import "UIView+GrowingNode.h"
#import "GrowingAttributesConst.h"
#import <pthread.h>

@implementation UICollectionView(Growing_xPath)

- (id)growingNodeAttribute:(NSString *)attrbute
{
    if (attrbute == GrowingAttributeIsHorizontalTableKey)
    {
        if (self.alwaysBounceHorizontal && !self.alwaysBounceVertical)
        {
            return GrowingAttributeReturnYESKey;
        }
        CGSize boundSize = self.bounds.size;
        CGSize contentSize = self.contentSize;
        if (contentSize.height <= boundSize.height && contentSize.width > boundSize.width)
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
        if ([self.growingHook_allCreatedHeaders containsObject:node])
        {
            return GrowingAttributeReturnYESKey;
        }
        if ([self.growingHook_allCreatedFooters containsObject:node])
        {
            return GrowingAttributeReturnYESKey;
        }
    }
    return nil;
}

- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs outPaths:(NSMutableArray *)paths filterChildNode:(id<GrowingNode>)aNode
{
    pthread_mutex_t * pMutex = getUICollectionViewMutexPointer();
    pthread_mutex_lock(pMutex);
    

    [super growingNodeOutContainerChilds:childs outPaths:paths filterChildNode:aNode];
    
    NSString * selfClassName = NSStringFromClass(self.class);
    for (UICollectionViewCell * cell in self.growingHook_allCreatedCells)
    {
        GrowingAddChildNodeWithReturnBlock(^{pthread_mutex_unlock(pMutex);},
                                           cell,
                                           ([selfClassName stringByAppendingString:@"Section"],
                                            cell.growingHook_indexPath.section, YES),
                                           (NSStringFromClass(cell.class),
                                            cell.growingHook_indexPath.row, YES));
    }
    for (UICollectionReusableView * header in self.growingHook_allCreatedHeaders)
    {
        GrowingAddChildNodeWithReturnBlock(^{pthread_mutex_unlock(pMutex);},
                                           header,
                                           ([selfClassName stringByAppendingString:@"SectionHeader"],
                                            header.growingHook_indexPath.section, YES),
                                           (NSStringFromClass(header.class)));
    }
    for (UICollectionReusableView * footer in self.growingHook_allCreatedFooters)
    {
        GrowingAddChildNodeWithReturnBlock(^{pthread_mutex_unlock(pMutex);},
                                           footer,
                                           ([selfClassName stringByAppendingString:@"SectionFooter"],
                                            footer.growingHook_indexPath.section, YES),
                                           (NSStringFromClass(footer.class)));
    }

    
    pthread_mutex_unlock(pMutex);
}

@end

@interface UICollectionViewCell(GrowingNode)<GrowingNode>

@end

@implementation UICollectionViewCell(GrowingNode)

- (void)growingNodeOutChilds:(NSMutableArray *)childs
                    outPaths:(NSMutableArray *)paths
             filterChildNode:(id<GrowingNode>)aNode
{
    NSUInteger i = 0;
    for (UIView * v in self.subviews)
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

- (BOOL)growingViewUserInteraction
{
    return YES;
}

- (NSString*)growingNodeName
{
    __kindof UIView *curView = self;
    UICollectionView *collecitonView = nil;
    while (curView) {
        if ([curView isKindOfClass:[UICollectionView class]])
        {
            collecitonView = curView;
        }
        curView = curView.superview;
    }
    if (!collecitonView)
    {
        return @"列表";
    }
    else
    {
        CGSize contentsize = collecitonView.contentSize;
        CGSize frameSize = collecitonView.frame.size;
        BOOL w = ABS(contentsize.width - frameSize.width) > 1;
        BOOL h = ABS(contentsize.height - frameSize.height) > 1;
        if(w && !h)
        {
            return @"横滑列表项";
        }
        else if (h && !w)
        {
            return @"竖滑列表项";
        }
        else
        {
            return @"列表项";
        }
    }
}

@end

@interface UICollectionReusableView(GrowingNode)<GrowingNode>

@end

@implementation UICollectionReusableView(GrowingNode)

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
