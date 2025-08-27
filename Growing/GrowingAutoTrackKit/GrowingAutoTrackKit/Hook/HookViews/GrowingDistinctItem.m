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


#import "GrowingDistinctItem.h"
#import <objc/runtime.h>
#import "GrowingAutoTrackEvent.h"
#import "GrowingGlobal.h"

@interface GrowingDistinctItem : NSObject

@end

typedef void(^growingUpdateBlock)(id<GrowingListViewProtocol> listView, GrowingDistinctItem *item);

@interface GrowingDistinctItem()
{
    NSMutableDictionary *rootDict;
    NSMutableArray<growingUpdateBlock> *updateBlocks;
    NSMutableDictionary *countDict;
}


@property (nonatomic, assign) NSInteger sectionCount;
- (void)setCellCount:(NSInteger)cellCount inSection:(NSInteger)section;
- (NSInteger)cellCountInSection:(NSInteger)section;

@property (nonatomic, readonly) NSInteger cellCount;

@end

@implementation GrowingDistinctItem

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        rootDict = [[NSMutableDictionary alloc] init];
        updateBlocks = [[NSMutableArray alloc] init];
        
        countDict = [[NSMutableDictionary alloc] init];
        
        self.sectionCount = 1;
    }
    return self;
}

- (void)addUpdateBlock:(growingUpdateBlock)block
{
    if (!block)
    {
        return;
    }
    [updateBlocks addObject:block];
}

- (void)callUpdateBlocks:(id<GrowingListViewProtocol>)listView
{
    for (growingUpdateBlock block in updateBlocks)
    {
        block(listView, self);
    }
    [updateBlocks removeAllObjects];
}


- (BOOL)tracktable:(id<GrowingListViewProtocol>)listView
           section:(NSInteger)section
              type:(NSString *)type
               row:(NSInteger)row
{
    [self callUpdateBlocks:listView];
    
    
    NSString *sectionString = [[NSString alloc] initWithFormat:@"%d",(int)section];
    NSMutableDictionary *typeDict = [rootDict valueForKey:sectionString];
    
    NSMutableIndexSet *rowSet = [typeDict valueForKey:type];
    
    
    if (typeDict && rowSet && [rowSet containsIndex:row])
    {
        return NO;
    }
    else
    {
        if (!typeDict)
        {
            typeDict = [[NSMutableDictionary alloc] init];
            [rootDict setValue:typeDict forKey:sectionString];
        }
        if (!rowSet)
        {
            rowSet = [[NSMutableIndexSet alloc] init];
            [typeDict setValue:rowSet forKey:type];
        }
        [rowSet addIndex:row];
        
        return YES;
    }
}

- (void)clear
{
    [rootDict removeAllObjects];
}

- (void)clearSection:(NSInteger)section
{
    NSString *sectionString = [[NSString alloc] initWithFormat:@"%d",(int)section];
    [rootDict removeObjectForKey:sectionString];
}

- (void)clearSection:(NSInteger)section type:(NSString*)type  beginRow:(NSInteger)beginRow endRow:(NSInteger)endRow
{
    NSMutableDictionary *typeDict = [rootDict valueForKey:[NSString stringWithFormat:@"%d",(int)section]];
    NSMutableIndexSet *set = [typeDict valueForKey:type];
    [set removeIndexesInRange:NSMakeRange(MIN(beginRow,endRow) , ABS(beginRow - endRow) + 1)];
}



- (void)setSectionCount:(NSInteger)sectionCount
{
    for (NSInteger i = 0 ; i < sectionCount ; i ++)
    {
        NSNumber *number = [[NSNumber alloc] initWithInteger:0];
        NSString *key = [[NSString alloc] initWithFormat:@"%d",(int)i];
        [countDict setValue:number forKey:key];
    }
}

- (void)setCellCount:(NSInteger)cellCount inSection:(NSInteger)section
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:cellCount];
    NSString *key = [[NSString alloc] initWithFormat:@"%d",(int)section];
    [countDict setValue:number forKey:key];
}

- (NSInteger)cellCountInSection:(NSInteger)section
{
    NSString *key = [[NSString alloc] initWithFormat:@"%d",(int)section];
    return [[countDict valueForKey:key] integerValue];
}

- (NSInteger)cellCount
{
    NSInteger count = 0;
    
    for (NSNumber *n in countDict.allValues)
    {
        count += n.integerValue;
    }
    return count;
}

@end




@implementation UITableView(growingTableViewAndCollectionView)

@end

@implementation UICollectionView(growingTableViewAndCollectionView)

@end

void setListViewItem(id<GrowingListViewProtocol> listView, GrowingDistinctItem *item)
{
    objc_setAssociatedObject(listView, growingListViewTrackView, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

GrowingDistinctItem *getListViewItem(id<GrowingListViewProtocol> listView)
{
    GrowingDistinctItem *item = objc_getAssociatedObject(listView,growingListViewTrackView);
    if (!item)
    {
        item = [[GrowingDistinctItem alloc] init];
        setListViewItem(listView, item);
    }
    return item;
}

void growingListViewSetSectionCount     (id<GrowingListViewProtocol> listView, NSInteger sectionCount)
{
    GrowingDistinctItem *item = getListViewItem(listView);
    item.sectionCount = sectionCount;
}
void growingListViewSetCellCount        (id<GrowingListViewProtocol> listView, NSInteger section,NSInteger cellCount)
{
    GrowingDistinctItem *item = getListViewItem(listView);
    [item setCellCount:cellCount inSection:section];
}

void growingListViewTrackView(id<GrowingListViewProtocol> listView,UIView *view,NSString *type,NSInteger section,NSInteger row)
{
    if (!g_enableImp) { return; }
    
    GrowingDistinctItem *item = getListViewItem(listView);
    
    if ([item tracktable:listView section:section type:type row:row])
    {

        [GrowingImpressionEvent sendEventWithNode:view
                                     andEventType:GrowingEventTypeUINewRow];
    }
    else
    {
        [GrowingNewCellNoTrackEvent sendEventWithNode:view
                                         andEventType:GrowingEventTypeUINewRow];
    }
}

void growingListViewReuseView(id<GrowingListViewProtocol> listView, UIView *view)
{
    if (!g_enableImp) { return; }

    [GrowingViewHideEvent sendEventWithNode:view andEventType:GrowingEventTypeUIHiddenCellReuse];
}

void growingListViewDidReload(id<GrowingListViewProtocol> listView)
{
    GrowingDistinctItem *distincetItem = getListViewItem(listView);
    NSInteger cellcount = distincetItem.cellCount;

    [distincetItem addUpdateBlock:^(id<GrowingListViewProtocol> listView,
                                    GrowingDistinctItem *item) {
        
        if (cellcount < item.cellCount)
        {
            
        }
        else
        {
            [item clear];
        }
    }];
}

void growingListViewDidInsertSections   (id<GrowingListViewProtocol> listView, NSIndexSet *sections)
{
    
    GrowingDistinctItem *item = getListViewItem(listView);
    
    __block NSInteger minIndex = item.sectionCount;
    __block NSInteger maxIndex = minIndex + sections.count;
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        minIndex = MIN(minIndex, idx);
    }];
    
    for (NSInteger i = minIndex ; i <= maxIndex ; i++)
    {
        [item clearSection:i];
    }
}

void growingListViewDidDeleteSections   (id<GrowingListViewProtocol> listView, NSIndexSet *sections)
{
    GrowingDistinctItem *item = getListViewItem(listView);
    
    __block NSInteger minIndex = item.sectionCount;
    __block NSInteger maxIndex = minIndex;
    
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        minIndex = MIN(minIndex, idx);
    }];
    
    for (NSInteger i = minIndex ; i <= maxIndex ; i++)
    {
        [item clearSection:i];
    }
}

static void growingListViewDidReloadSection(id<GrowingListViewProtocol> listView,NSInteger section)
{
    GrowingDistinctItem *item = getListViewItem(listView);
    NSInteger cellcount = [item cellCountInSection:section];
    
    [getListViewItem(listView) addUpdateBlock:^(id<GrowingListViewProtocol> listView,GrowingDistinctItem *item) {
        
        if (cellcount < [item cellCountInSection:section])
        {
            
        }
        else
        {
            [item clearSection:section];
        }
    }];
}

void growingListViewDidReloadSections   (id<GrowingListViewProtocol> listView, NSIndexSet *sections)
{
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        growingListViewDidReloadSection(listView, idx);
    }];
}
void growingListViewDidMoveSection      (id<GrowingListViewProtocol> listView, NSInteger section, NSInteger newSection)
{
    if(section == newSection)
    {
        return;
    }
    for (NSInteger i = MIN(section, newSection) ; i < MIN(section, newSection) ; i ++)
    {
        [getListViewItem(listView) clearSection:i];
    }
}

static NSMutableDictionary *growingCreateDictsByIndexPaths(NSArray<NSIndexPath *> *indexPaths)
{
    NSMutableDictionary *sectionDict = [[NSMutableDictionary alloc] init];
    for (NSIndexPath *index in indexPaths)
    {
        NSString *sectionString = [[NSString alloc] initWithFormat:@"%d",(int)index.section];
        NSMutableIndexSet *set = [sectionDict valueForKey:sectionString];
        if (!set)
        {
            set = [[NSMutableIndexSet alloc] init];
        }
        [set addIndex:index.row];
    }
    return sectionDict;
}

void growingListViewDidInsertIndexPaths (id<GrowingListViewProtocol> listView, NSArray<NSIndexPath *> *indexPaths,NSString *type)
{
    NSDictionary *sectionDict = growingCreateDictsByIndexPaths(indexPaths);
    GrowingDistinctItem *item = getListViewItem(listView);
    [sectionDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSIndexSet *obj, BOOL * _Nonnull stop) {
        if (obj.count)
        {
            [item clearSection:key.integerValue type:type beginRow:obj.firstIndex endRow:obj.lastIndex];
        }
    }];
    
}
void growingListViewDidDeleteIndexPaths (id<GrowingListViewProtocol> listView, NSArray<NSIndexPath *> *indexPaths, NSString *type)
{
    NSDictionary *sectionDict = growingCreateDictsByIndexPaths(indexPaths);
    GrowingDistinctItem *item = getListViewItem(listView);
    [sectionDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSIndexSet *obj, BOOL * _Nonnull stop) {
        if (obj.count)
        {
            NSInteger count = [item cellCountInSection:key.integerValue];
            [item clearSection:key.integerValue
                          type:type
                      beginRow:MIN(obj.firstIndex, count)
                        endRow:MAX(obj.lastIndex, count)];
        }
    }];
}
void growingListViewDidReloadIndexPaths (id<GrowingListViewProtocol> listView, NSArray<NSIndexPath *> *indexPaths, NSString *type)
{
    GrowingDistinctItem *item = getListViewItem(listView);
    for (NSIndexPath *index in indexPaths)
    {
        [item clearSection:index.section type:type beginRow:index.row endRow:index.row];
    }
}
void growingListViewDidMoveIndexPath    (id<GrowingListViewProtocol> listView, NSIndexPath *indexPath, NSIndexPath *newIndexPath, NSString *type)
{
    GrowingDistinctItem *item = getListViewItem(listView);
    [item clearSection:indexPath.section type:type beginRow:indexPath.row endRow:indexPath.row];
    [item clearSection:newIndexPath.section type:type beginRow:newIndexPath.row endRow:newIndexPath.row];
}
