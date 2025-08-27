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
#import "FoDelegateSwizzling.h"
#import "UIView+Growing.h"
#import "FoDefineProperty.h"
#import "GrowingAutoTrackEvent.h"
#import "UIView+GrowingNode.h"
#import "GrowingTaggedViews.h"
#import "GrowingAspect.h"
#import "GrowingDistinctItem.h"
#import <pthread.h>
#import <objc/message.h>


static pthread_mutex_t collectionViewMutex;
pthread_mutex_t * getUICollectionViewMutexPointer()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_mutex_init(&collectionViewMutex, NULL);
    });
    return &collectionViewMutex;
}

@implementation UIView (GrowingSDCycleBanner)

FoPropertyImplementation(NSArray *, growingSelfSDCycleBannerIds, setGrowingSelfSDCycleBannerIds)

@end

@implementation UICollectionViewCell(Growing)

FoPropertyImplementation(NSIndexPath* , growingHook_indexPath, setGrowingHook_indexPath)

FoPropertyImplementation(FoWeakObjectShell*, growingHook_parentTableviewWeakShell, setGrowingHook_parentTableviewWeakShell)

- (BOOL)growingEventProtocolCanTrackWithType:(GrowingEventType)eventType
                                 triggerNode:(id<GrowingNode>)triggerNode
{
    if (triggerNode == self && eventType == GrowingEventTypeUIAddSubView)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}
@end

@implementation UICollectionReusableView(Growing)

FoPropertyImplementation(NSIndexPath* , growingHook_indexPath, setGrowingHook_indexPath)

@end

FoPropertyDefine(UICollectionView, NSHashTable*, growingHook_allCreatedCellsTable, setGrowingHook_allCreatedCellsTable)
FoPropertyDefine(UICollectionView, NSHashTable*, growingHook_allCreatedHeadersTable, setGrowingHook_allCreatedHeadersTable)
FoPropertyDefine(UICollectionView, NSHashTable*, growingHook_allCreatedFootersTable, setGrowingHook_allCreatedFootersTable)

FoSwizzleTempletVoid(@selector(collectionView:didSelectItemAtIndexPath:),
                     void,collectionDidSelect,UICollectionView*,NSIndexPath*)

FoSwizzleTempletVoid(@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:),
                     void,collectionDidEndDisplayCell,UICollectionView*,UICollectionViewCell*,NSIndexPath*)

FoSwizzleTemplet(@selector(collectionView:cellForItemAtIndexPath:),
                 UICollectionViewCell* , collectionViewCellForIndex,UICollectionView*,NSIndexPath*)

FoSwizzleTemplet(@selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:),
                 UICollectionReusableView*,collectionViewOtherCell,UICollectionView*,UICollectionReusableView*,NSIndexPath*)

FoSwizzleTemplet(@selector(numberOfSectionsInCollectionView:),
                 NSInteger,numberOfSectionsInCollectionView,UITableView*)

FoSwizzleTemplet(@selector(collectionView:numberOfItemsInSection:),
                 NSInteger,numberOfRowsInSection,UITableView*,NSInteger)


FoHookListViewDelegate(UICollectionView, @selector(setDelegate:),
               void, NSObject<UICollectionViewDelegate>*, delegate)

GrowingAspectBeforeNoAdd(delegate,
                         collectionDidSelect,
                         void,@selector(collectionView:didSelectItemAtIndexPath:),(UICollectionView*)collectionView,
                         (NSIndexPath *)indexPath, {
                             if (wself == collectionView && originInstance == collectionView.delegate)
                             {
                                 UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
                                 if (cell)
                                 {
                                     [GrowingClickEvent sendEventWithNode:cell
                                                             andEventType:GrowingEventTypeRowSelected];
                                 }
                             }
                         })
,

GrowingAspectAfter(delegate,
                   collectionDidEndDisplayCell,
                   void,@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:),(UICollectionView *)collectionView,(UICollectionViewCell *)cell,(NSIndexPath *)indexPath, {
                       if (wself == collectionView && originInstance == collectionView.delegate)
                       {
                           pthread_mutex_t * pMutex = getUICollectionViewMutexPointer();
                           pthread_mutex_lock(pMutex);
                           
                           cell.growingHook_indexPath = nil;
                           [collectionView.growingHook_allCreatedCells removeObject:cell];
                           
                           pthread_mutex_unlock(pMutex);
                       }
                   })
FoHookDelegateEnd

FoHookListViewDelegate(UICollectionView, @selector(setDataSource:),
               void, NSObject<UICollectionViewDelegate>*, dataSource)

GrowingAspectAfterNoAdd(dataSource,
                        collectionViewCellForIndex,
                        UICollectionViewCell*,@selector(collectionView:cellForItemAtIndexPath:),(UICollectionView *)collectionView,(NSIndexPath *)indexPath,{
                            if (wself == collectionView && originInstance == collectionView.dataSource)
                            {
                                pthread_mutex_t * pMutex = getUICollectionViewMutexPointer();

                                pthread_mutex_lock(pMutex);
                                
                                originReturnValue.growingHook_indexPath = indexPath;
                                NSHashTable *hashTable = collectionView.growingHook_allCreatedCellsTable;
                                if (!hashTable)
                                {
                                    hashTable = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory | NSHashTableObjectPointerPersonality capacity:7];
                                    collectionView.growingHook_allCreatedCellsTable = hashTable;
                                }
                                [hashTable addObject:originReturnValue];
                                
                                pthread_mutex_unlock(pMutex);
                                if ([[GrowingTaggedViews shareInstance] shouldDisplayTaggedViews])
                                {
                                    GrowingNodeManager *manager = [[GrowingNodeManager alloc] initWithNodeAndParent:originReturnValue
                                                                                                         checkBlock:nil];
                                    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode, GrowingNodeManagerEnumerateContext *context) {
                                        [[GrowingTaggedViews shareInstance] removeNodeHighlight:aNode];
                                    }];
                                }
                                
                                FoWeakObjectShell *weakShell = [[FoWeakObjectShell alloc] init];
                                weakShell.obj = collectionView;
                                [originReturnValue setGrowingHook_parentTableviewWeakShell:weakShell];
                            
                                growingListViewReuseView(collectionView,originReturnValue);
                                growingListViewTrackView(collectionView,originReturnValue, @"cell",indexPath.section,indexPath.row);
                            }
                        })
,
GrowingAspectAfterNoAdd(dataSource,
                        collectionViewOtherCell,
                        UICollectionReusableView* ,
                        @selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:) ,
                        (UICollectionView *)collectionView,
                        (NSString *)kind,
                        (NSIndexPath *)indexPath,{
                            
                            if (indexPath.section == NSNotFound || indexPath.item == NSNotFound || indexPath.row == NSNotFound) {
                                return;
                            }
                            if (wself == collectionView && originInstance == collectionView.dataSource)
                            {
                                NSHashTable * hashTable = nil;
                                if ([kind isEqualToString:UICollectionElementKindSectionHeader])
                                {
                                    hashTable = collectionView.growingHook_allCreatedHeadersTable;
                                    if (hashTable == nil)
                                    {
                                        hashTable = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory | NSHashTableObjectPointerPersonality capacity:7];
                                        collectionView.growingHook_allCreatedHeadersTable = hashTable;
                                    }
                                }
                                else if ([kind isEqualToString:UICollectionElementKindSectionFooter])
                                {
                                    hashTable = collectionView.growingHook_allCreatedFootersTable;
                                    if (hashTable == nil)
                                    {
                                        hashTable = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory | NSHashTableObjectPointerPersonality capacity:7];
                                        collectionView.growingHook_allCreatedFootersTable = hashTable;
                                    }
                                }
                                if (hashTable != nil)
                                {
                                    [hashTable addObject:originReturnValue];
                                    growingListViewTrackView(collectionView,originReturnValue, kind,indexPath.section,indexPath.row);
                                }
                            }
                        }),
GrowingAspectAfterNoAdd(dataSource,
                        numberOfRowsInSection,
                        NSInteger,
                        @selector(collectionView:numberOfItemsInSection:),
                        (UICollectionView*)collectionView,
                        (NSInteger)section, {
                            if (wself == collectionView && originInstance == collectionView.dataSource)
                            {
                                growingListViewSetCellCount(collectionView,section,originReturnValue);
                            }
                        }),
GrowingAspectAfterNoAdd(dataSource,
                        numberOfSectionsInCollectionView,
                        NSInteger,
                        @selector(numberOfSectionsInCollectionView:),
                        (UICollectionView*)collectionView,{
                            if (wself == collectionView && originInstance == collectionView.dataSource)
                            {
                                growingListViewSetSectionCount(collectionView,originReturnValue);
                            }
                        })
FoHookDelegateEnd


#pragma mark For SDCycleScrollView

FoHookInstancePlus("SDCycleScrollView", UIView *, @selector(collectionView:cellForItemAtIndexPath:), UICollectionViewCell *, UICollectionView *collectionView, NSIndexPath *indexPath)
{
    UICollectionViewCell *cell = FoHookOrgin(collectionView, indexPath);
    
    int currentIndex = 0;
    SEL currentIndexSel = NSSelectorFromString(@"pageControlIndexWithCurrentCellIndex:");
    if ([self respondsToSelector:currentIndexSel]) {
        currentIndex = ((int(*)(UIView *,SEL,NSInteger))objc_msgSend)((UIView *)self, currentIndexSel, indexPath.item);
    }
    
    NSArray *bannerIdsArray = self.growingSDCycleBannerIds.count > 0 ? self.growingSDCycleBannerIds : self.growingSelfSDCycleBannerIds;
    
    NSUInteger bannerIdsCount = bannerIdsArray.count;
    if (bannerIdsCount && bannerIdsCount - 1 >= currentIndex) {
        cell.growingAttributesValue = bannerIdsArray[currentIndex];
    }
    return cell;
}
FoHookEnd

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstancePlus("SDCycleScrollView", UIView *, @selector(setImagePathsGroup:), void, NSArray *imagePathsGroup)
#pragma clang diagnostic pop
{
    if (self.growingSDCycleBannerIds.count == 0) {
        
        NSMutableArray *bannerIdsArray = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < imagePathsGroup.count; i++) {
            NSString *imagePathString = imagePathsGroup[i];
            
            
            if (![imagePathString isKindOfClass:[NSString class]]) {
                bannerIdsArray = nil;
                break;
            }
            
            
            if (!imagePathString.length) {
                bannerIdsArray = nil;
                break;
            } else {
                if ([imagePathString hasPrefix:@"http"]) {
                    NSArray *componentsArray = [imagePathString componentsSeparatedByString:@"/"];
                    [bannerIdsArray addObject:componentsArray.lastObject];
                } else {
                    [bannerIdsArray addObject:imagePathString];
                }
            }
        }
        
        self.growingSelfSDCycleBannerIds = bannerIdsArray;
    } else {
        self.growingSelfSDCycleBannerIds = self.growingSDCycleBannerIds;
    }
    
    FoHookOrgin(imagePathsGroup);
}
FoHookEnd


@implementation UICollectionView (Growing)

- (NSHashTable*)growingHook_allCreatedCells
{
    return self.growingHook_allCreatedCellsTable;
}

- (NSHashTable*)growingHook_allCreatedHeaders
{
    return self.growingHook_allCreatedHeadersTable;
}

- (NSHashTable*)growingHook_allCreatedFooters
{
    return self.growingHook_allCreatedFootersTable;
}

@end




FoHookInstance(UICollectionView, @selector(reloadData), void)
{
    growingListViewDidReload(self);
    FoHookOrgin();
}
FoHookEnd


FoHookInstance(UICollectionView, @selector(reloadSections:), void, NSIndexSet *indexs)
{
    growingListViewDidReloadSections(self,indexs);
    FoHookOrgin(indexs);
}
FoHookEnd

FoHookInstance(UICollectionView, @selector(insertSections:), void, NSIndexSet *indexs)
{
    growingListViewDidInsertSections(self, indexs);
    FoHookOrgin(indexs);
}
FoHookEnd

FoHookInstance(UICollectionView, @selector(deleteSections:), void, NSIndexSet *indexs)
{
    growingListViewDidDeleteSections(self, indexs);
    FoHookOrgin(indexs);
}
FoHookEnd

FoHookInstance(UICollectionView, @selector(moveSection:toSection:), void, NSInteger section,NSInteger newSection)
{
    growingListViewDidMoveSection(self, section, newSection);
    FoHookOrgin(section,newSection);
}
FoHookEnd


FoHookInstance(UICollectionView, @selector(reloadItemsAtIndexPaths:), void, NSArray *indexs)
{
    growingListViewDidReloadIndexPaths(self, indexs, @"cell");
    FoHookOrgin(indexs);
}
FoHookEnd

FoHookInstance(UICollectionView, @selector(insertItemsAtIndexPaths:), void,NSArray *indexs)
{
    growingListViewDidInsertIndexPaths(self, indexs, @"cell");
    FoHookOrgin(indexs);
}
FoHookEnd

FoHookInstance(UICollectionView, @selector(deleteItemsAtIndexPaths:), void,NSArray *indexs)
{
    growingListViewDidDeleteIndexPaths(self, indexs, @"cell");
    FoHookOrgin(indexs);
}
FoHookEnd

FoHookInstance(UICollectionView, @selector(moveItemAtIndexPath:toIndexPath:), void,NSIndexPath *index, NSIndexPath *newIndex)
{
    growingListViewDidMoveIndexPath(self, index,newIndex,@"cell");
    FoHookOrgin(index,newIndex);
}
FoHookEnd

FoHookInstance(UICollectionView, @selector(awakeFromNib), void)
{
    FoHookOrgin();
    if (self.delegate)
    {
        id delegate = self.delegate;
        self.delegate = nil;
        self.delegate = delegate;
    }
    if (self.dataSource)
    {
        id datasource = self.dataSource;
        self.dataSource = nil;
        self.dataSource = datasource;
    }
}
FoHookEnd
