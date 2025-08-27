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
#import "sqlite3.h"

@class FMG3Database;



@interface FMG3DatabaseQueue : NSObject {
    NSString            *_path;
    dispatch_queue_t    _queue;
    FMG3Database          *_db;
    int                 _openFlags;
}



@property (atomic, retain) NSString *path;



@property (atomic, readonly) int openFlags;







+ (instancetype)databaseQueueWithPath:(NSString*)aPath;


+ (instancetype)databaseQueueWithPath:(NSString*)aPath flags:(int)openFlags;



- (instancetype)initWithPath:(NSString*)aPath;



- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags;



- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags vfs:(NSString *)vfsName;



+ (Class)databaseClass;



- (void)close;







- (void)inDatabase:(void (^)(FMG3Database *db))block;



- (void)inTransaction:(void (^)(FMG3Database *db, BOOL *rollback))block;



- (void)inDeferredTransaction:(void (^)(FMG3Database *db, BOOL *rollback))block;







#if SQLITE_VERSION_NUMBER >= 3007000


- (NSError*)inSavePoint:(void (^)(FMG3Database *db, BOOL *rollback))block;
#endif

@end
