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


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^growingListViewCall)(void);



@protocol GrowingListViewProtocol <NSObject>

@end

@interface UICollectionView(growingTableViewAndCollectionView)<GrowingListViewProtocol>
@end
@interface UITableView(growingTableViewAndCollectionView)<GrowingListViewProtocol>
@end


void growingListViewSetSectionCount     (id<GrowingListViewProtocol> listView, NSInteger sectionCount);
void growingListViewSetCellCount        (id<GrowingListViewProtocol> listView, NSInteger section,NSInteger cellCount);

void growingListViewTrackView           (id<GrowingListViewProtocol> listView, UIView *view, NSString *type, NSInteger section,NSInteger row);

void growingListViewReuseView           (id<GrowingListViewProtocol> listView, UIView *view);

void growingListViewDidReload           (id<GrowingListViewProtocol> listView);

void growingListViewDidInsertSections   (id<GrowingListViewProtocol> listView, NSIndexSet *sections);
void growingListViewDidDeleteSections   (id<GrowingListViewProtocol> listView, NSIndexSet *sections);
void growingListViewDidReloadSections   (id<GrowingListViewProtocol> listView, NSIndexSet *sections);
void growingListViewDidMoveSection      (id<GrowingListViewProtocol> listView, NSInteger section, NSInteger newSection);

void growingListViewDidInsertIndexPaths (id<GrowingListViewProtocol> listView, NSArray<NSIndexPath *> *indexPaths, NSString *type);
void growingListViewDidDeleteIndexPaths (id<GrowingListViewProtocol> listView, NSArray<NSIndexPath *> *indexPaths, NSString *type);
void growingListViewDidReloadIndexPaths (id<GrowingListViewProtocol> listView, NSArray<NSIndexPath *> *indexPaths, NSString *type);
void growingListViewDidMoveIndexPath    (id<GrowingListViewProtocol> listView, NSIndexPath *indexPath, NSIndexPath *newIndexPath, NSString *type);
