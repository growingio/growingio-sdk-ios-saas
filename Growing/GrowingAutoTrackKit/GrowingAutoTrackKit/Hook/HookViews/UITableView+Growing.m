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


#import "UITableView+Growing.h"
#import "FoDelegateSwizzling.h"
#import "UIView+Growing.h"
#import "FoDefineProperty.h"
#import "GrowingAutoTrackEvent.h"
#import "UIView+GrowingNode.h"
#import "GrowingTaggedViews.h"
#import "GrowingAspect.h"
#import "GrowingDistinctItem.h"
#import "FoWeakObjectShell.h"
#import <pthread.h>

static pthread_mutex_t tableViewMutex;
pthread_mutex_t * getUITableViewMutexPointer()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_mutex_init(&tableViewMutex, NULL);
    });
    return &tableViewMutex;
}

@implementation UITableViewCell(Growing)

FoPropertyImplementation(NSIndexPath*, growingHook_indexPath, setGrowingHook_indexPath)
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

FoPropertyDefine(UITableView, id<FoObjectSELObserverItem>, growingHook_RespondsToSelector, setGrowingHook_RespondsToSelector)
FoPropertyDefine(UITableView, NSHashTable*, growingHook_allCreatedCellsTable, setGrowingHook_allCreatedCellsTable)

FoPropertyDefine(UITableView, id<FoObjectSELObserverItem>, growingHook_DidSelect, setGrowingHook_DidSelect)
FoPropertyDefine(UITableView, id<FoObjectSELObserverItem>, growingHook_DidEndDisplay, setGrowingHook_DidEndDisplay)
FoPropertyDefine(UITableView, id<FoObjectSELObserverItem>, growingHook_TableCellForRow, setGrowingHook_TableCellForRow)
FoPropertyDefine(UITableView, id<FoObjectSELObserverItem>, growingHook_NumberOfSections, setGrowingHook_NumberOfSections)
FoPropertyDefine(UITableView, id<FoObjectSELObserverItem>, growingHook_NumberOfRows, setGrowingHook_NumberOfRows)

FoSwizzleTempletVoid(@selector(tableView:didSelectRowAtIndexPath:),
                     void,tableDidSelectRow,UITableView*,NSIndexPath*)

FoSwizzleTempletVoid(@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:),
                     void,tableDidEndDisplayCell,UITableView*,UITableViewCell*,NSIndexPath*)

FoSwizzleTemplet(@selector(tableView:cellForRowAtIndexPath:),
                 UITableViewCell*,tableCellForRow,UITableView*,NSIndexPath*)

FoSwizzleTemplet(@selector(numberOfSectionsInTableView:),
                 NSInteger,numberOfSectionsInTableView,UITableView*)

FoSwizzleTemplet(@selector(tableView:numberOfRowsInSection:),
                 NSInteger,numberOfRowsInSection,UITableView*,NSInteger)

static void removeHookTableDelegate(UITableView *tableView)
{
    if (tableView.growingHook_DidSelect) {
        [tableView.growingHook_DidSelect remove];
        tableView.growingHook_DidSelect = nil;
    }
    if (tableView.growingHook_DidEndDisplay) {
        [tableView.growingHook_DidEndDisplay remove];
        tableView.growingHook_DidEndDisplay = nil;
    }
}

static void removeHookTableDataSource(UITableView *tableView)
{
    if (tableView.growingHook_TableCellForRow) {
        [tableView.growingHook_TableCellForRow remove];
        tableView.growingHook_TableCellForRow = nil;
    }
    if (tableView.growingHook_NumberOfRows) {
        [tableView.growingHook_NumberOfRows remove];
        tableView.growingHook_NumberOfRows = nil;
    }
    if (tableView.growingHook_NumberOfSections) {
        [tableView.growingHook_NumberOfSections remove];
        tableView.growingHook_NumberOfSections = nil;
    }
}

static void removeHookTableRespondsToSelector(UITableView *tableView)
{
    if(tableView.growingHook_RespondsToSelector) {
        [tableView.growingHook_RespondsToSelector remove];
        tableView.growingHook_RespondsToSelector = nil;
    }
}


FoHookListViewDelegate(UITableView, @selector(setDelegate:),
               void, NSObject<UITableViewDelegate>*, delegate)
wself.growingHook_DidSelect = GrowingAspectBeforeNoAdd(delegate,
                         tableDidSelectRow,
                         void,
                         @selector(tableView:didSelectRowAtIndexPath:),
                         (UITableView *)tableView ,
                         (NSIndexPath *)indexPath, {
                             if (wself == tableView && originInstance == tableView.delegate)
                             {
                                 UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                                 if (cell)
                                 {
                                     [GrowingClickEvent sendEventWithNode:cell
                                                             andEventType:GrowingEventTypeRowSelected];
                                 }
                             }
                         })
,
wself.growingHook_DidEndDisplay = GrowingAspectAfter(delegate,
                   tableDidEndDisplayCell,
                   void,
                   @selector(tableView:didEndDisplayingCell:forRowAtIndexPath:),
                   (UITableView *)tableView,
                   (UITableViewCell *)cell,
                   (NSIndexPath *)indexPath, {
                       if (wself == tableView && originInstance == tableView.delegate)
                       {
                           pthread_mutex_t * pMutex = getUITableViewMutexPointer();
                           pthread_mutex_lock(pMutex);
                           
                           cell.growingHook_indexPath = nil;
                           [tableView.growingHook_allCreatedCellsTable removeObject:cell];
                           
                           pthread_mutex_unlock(pMutex);
                       }
                   })

FoHookDelegateEnd


FoHookListViewDelegate(UITableView, @selector(setDataSource:),
               void, NSObject<UITableViewDataSource>*, dataSource)
wself.growingHook_TableCellForRow = GrowingAspectAfterNoAdd(dataSource,
                        tableCellForRow,
                        UITableViewCell*,
                        @selector(tableView:cellForRowAtIndexPath:),
                        (UITableView *)tableView,
                        (NSIndexPath *)indexPath, {
                            if (wself == tableView && originInstance == tableView.dataSource)
                            {
                                pthread_mutex_t * pMutex = getUITableViewMutexPointer();

                                pthread_mutex_lock(pMutex);
                                
                                originReturnValue.growingHook_indexPath = indexPath;
                                NSHashTable *hashTable = tableView.growingHook_allCreatedCellsTable;
                                if (!hashTable)
                                {
                                    hashTable = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory | NSHashTableObjectPointerPersonality  capacity:5];
                                    tableView.growingHook_allCreatedCellsTable = hashTable;
                                }
                                [hashTable addObject:originReturnValue];
                                
                                pthread_mutex_unlock(pMutex);
                                if ([[GrowingTaggedViews shareInstance] shouldDisplayTaggedViews])
                                {
                                    GrowingNodeManager *manager =
                                    [[GrowingNodeManager alloc] initWithNodeAndParent:originReturnValue
                                                                           checkBlock:nil];
                                    [manager enumerateChildrenUsingBlock:^(id<GrowingNode> aNode, GrowingNodeManagerEnumerateContext *context) {
                                        [[GrowingTaggedViews shareInstance] removeNodeHighlight:aNode];
                                    }];
                                }
                                
                                FoWeakObjectShell *weakShell = [[FoWeakObjectShell alloc] init];
                                weakShell.obj = tableView;
                                [originReturnValue setGrowingHook_parentTableviewWeakShell:weakShell];
                                
                                growingListViewReuseView(tableView,originReturnValue);
                                growingListViewTrackView(tableView,originReturnValue,@"cell",indexPath.section,indexPath.row);
                            }
                        }),
wself.growingHook_NumberOfRows = GrowingAspectAfterNoAdd(dataSource,
                        numberOfRowsInSection,
                        NSInteger,
                        @selector(tableView:numberOfRowsInSection:),
                        (UITableView*)tableView,
                        (NSInteger)section, {
                            if (wself == tableView && originInstance == tableView.dataSource)
                            {
                                growingListViewSetCellCount(tableView,section,originReturnValue);
                            }
                        }),
wself.growingHook_NumberOfSections = GrowingAspectAfterNoAdd(dataSource,
                        numberOfSectionsInTableView,
                        NSInteger,
                        @selector(numberOfSectionsInTableView:),
                        (UITableView*)tableView,{
                            if (wself == tableView && originInstance == tableView.dataSource)
                            {
                                growingListViewSetSectionCount(tableView,originReturnValue);
                            }
                        })
FoHookDelegateEnd



FoHookInstance(UITableView, @selector(reloadData), void)
{
    growingListViewDidReload(self);
    FoHookOrgin();
}
FoHookEnd


FoHookInstance(UITableView, @selector(reloadSections:withRowAnimation:), void, NSIndexSet *indexs,UITableViewRowAnimation animation)
{
    growingListViewDidReloadSections(self,indexs);
    FoHookOrgin(indexs,animation);
}
FoHookEnd

FoHookInstance(UITableView, @selector(insertSections:withRowAnimation:), void, NSIndexSet *indexs, UITableViewRowAnimation animation)
{
    growingListViewDidInsertSections(self, indexs);
    FoHookOrgin(indexs,animation);
}
FoHookEnd

FoHookInstance(UITableView, @selector(deleteSections:withRowAnimation:), void, NSIndexSet *indexs,UITableViewRowAnimation animation)
{
    growingListViewDidDeleteSections(self, indexs);
    FoHookOrgin(indexs,animation);
}
FoHookEnd

FoHookInstance(UITableView, @selector(moveSection:toSection:), void, NSInteger section,NSInteger newSection)
{
    growingListViewDidMoveSection(self, section, newSection);
    FoHookOrgin(section,newSection);
}
FoHookEnd


FoHookInstance(UITableView, @selector(reloadRowsAtIndexPaths:withRowAnimation:), void, NSArray *indexs,UITableViewRowAnimation animation)
{
    growingListViewDidReloadIndexPaths(self, indexs, @"cell");
    FoHookOrgin(indexs,animation);
}
FoHookEnd

FoHookInstance(UITableView, @selector(insertRowsAtIndexPaths:withRowAnimation:), void,NSArray *indexs, UITableViewRowAnimation animation)
{
    growingListViewDidInsertIndexPaths(self, indexs, @"cell");
    FoHookOrgin(indexs,animation);
}
FoHookEnd

FoHookInstance(UITableView, @selector(deleteRowsAtIndexPaths:withRowAnimation:), void,NSArray *indexs,UITableViewRowAnimation animation)
{
    growingListViewDidDeleteIndexPaths(self, indexs, @"cell");
    FoHookOrgin(indexs,animation);
}
FoHookEnd

FoHookInstance(UITableView, @selector(moveRowAtIndexPath:toIndexPath:), void,NSIndexPath *index, NSIndexPath *newIndex)
{
    growingListViewDidMoveIndexPath(self, index,newIndex,@"cell");
    FoHookOrgin(index,newIndex);
}
FoHookEnd

@implementation UITableView (Growing_Hook)

+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clazz = NSClassFromString(@"UITableView");
        
        SEL originalSelector = NSSelectorFromString(@"dealloc");
        SEL swizzledSelector = @selector(grow_dealloc);
        
        Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(clazz, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(clazz,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(clazz,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)grow_dealloc
{
    @autoreleasepool {
        removeHookTableDelegate(self);
        removeHookTableDataSource(self);
        removeHookTableRespondsToSelector(self);
        
        self.dataSource = nil;
        self.delegate = nil;
    }
    [self grow_dealloc];
}

@end

@implementation UITableView (Growing)

- (NSHashTable*)growingHook_allCreatedCells
{
    return self.growingHook_allCreatedCellsTable;
}
@end


FoHookInstance(UITableView, @selector(awakeFromNib), void)
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
