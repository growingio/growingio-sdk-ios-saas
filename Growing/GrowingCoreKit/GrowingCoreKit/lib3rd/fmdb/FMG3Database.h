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
#import "FMG3ResultSet.h"
#import "FMG3DatabasePool.h"


#if ! __has_feature(objc_arc)
    #define FMG3DBAutorelease(__v) ([__v autorelease]);
    #define FMG3DBReturnAutoreleased FMG3DBAutorelease

    #define FMG3DBRetain(__v) ([__v retain]);
    #define FMG3DBReturnRetained FMG3DBRetain

    #define FMG3DBRelease(__v) ([__v release]);

    #define FMG3DBDispatchQueueRelease(__v) (dispatch_release(__v));
#else
    
    #define FMG3DBAutorelease(__v)
    #define FMG3DBReturnAutoreleased(__v) (__v)

    #define FMG3DBRetain(__v)
    #define FMG3DBReturnRetained(__v) (__v)

    #define FMG3DBRelease(__v)




    #if OS_OBJECT_USE_OBJC
        #define FMG3DBDispatchQueueRelease(__v)
    #else
        #define FMG3DBDispatchQueueRelease(__v) (dispatch_release(__v));
    #endif
#endif

#if !__has_feature(objc_instancetype)
    #define instancetype id
#endif


typedef int(^FMG3DBExecuteStatementsCallbackBlock)(NSDictionary *resultsDictionary);




#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"


@interface FMG3Database : NSObject  {
    
    sqlite3*            _db;
    NSString*           _databasePath;
    BOOL                _logsErrors;
    BOOL                _crashOnErrors;
    BOOL                _traceExecution;
    BOOL                _checkedOut;
    BOOL                _shouldCacheStatements;
    BOOL                _isExecutingStatement;
    BOOL                _inTransaction;
    NSTimeInterval      _maxBusyRetryTimeInterval;
    NSTimeInterval      _startBusyRetryTime;
    
    NSMutableDictionary *_cachedStatements;
    NSMutableSet        *_openResultSets;
    NSMutableSet        *_openFunctions;

    NSDateFormatter     *_dateFormat;
}







@property (atomic, assign) BOOL traceExecution;



@property (atomic, assign) BOOL checkedOut;



@property (atomic, assign) BOOL crashOnErrors;



@property (atomic, assign) BOOL logsErrors;



@property (atomic, retain) NSMutableDictionary *cachedStatements;







+ (instancetype)databaseWithPath:(NSString*)inPath;



- (instancetype)initWithPath:(NSString*)inPath;








- (BOOL)open;



#if SQLITE_VERSION_NUMBER >= 3005000
- (BOOL)openWithFlags:(int)flags;
- (BOOL)openWithFlags:(int)flags vfs:(NSString *)vfsName;
#endif



- (BOOL)close;



- (BOOL)goodConnection;








- (BOOL)executeUpdate:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ...;



- (BOOL)update:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ... __attribute__ ((deprecated));



- (BOOL)executeUpdate:(NSString*)sql, ...;



- (BOOL)executeUpdateWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);



- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments;



- (BOOL)executeUpdate:(NSString*)sql values:(NSArray *)values error:(NSError * __autoreleasing *)error;



- (BOOL)executeUpdate:(NSString*)sql withParameterDictionary:(NSDictionary *)arguments;




- (BOOL)executeUpdate:(NSString*)sql withVAList: (va_list)args;



- (BOOL)executeStatements:(NSString *)sql;



- (BOOL)executeStatements:(NSString *)sql withResultBlock:(FMG3DBExecuteStatementsCallbackBlock)block;



- (sqlite_int64)lastInsertRowId;



- (int)changes;








- (FMG3ResultSet *)executeQuery:(NSString*)sql, ...;



- (FMG3ResultSet *)executeQueryWithFormat:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);



- (FMG3ResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;



- (FMG3ResultSet *)executeQuery:(NSString *)sql values:(NSArray *)values error:(NSError * __autoreleasing *)error;



- (FMG3ResultSet *)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments;



- (FMG3ResultSet *)executeQuery:(NSString*)sql withVAList: (va_list)args;







- (BOOL)beginTransaction;



- (BOOL)beginDeferredTransaction;



- (BOOL)commit;



- (BOOL)rollback;



- (BOOL)inTransaction;








- (void)clearCachedStatements;



- (void)closeOpenResultSets;



- (BOOL)hasOpenResultSets;



- (BOOL)shouldCacheStatements;



- (void)setShouldCacheStatements:(BOOL)value;








- (BOOL)setKey:(NSString*)key;



- (BOOL)rekey:(NSString*)key;



- (BOOL)setKeyWithData:(NSData *)keyData;



- (BOOL)rekeyWithData:(NSData *)keyData;








- (NSString *)databasePath;



- (sqlite3*)sqliteHandle;








- (NSString*)lastErrorMessage;



- (int)lastErrorCode;



- (BOOL)hadError;



- (NSError*)lastError;



- (void)setMaxBusyRetryTimeInterval:(NSTimeInterval)timeoutInSeconds;
- (NSTimeInterval)maxBusyRetryTimeInterval;


#if SQLITE_VERSION_NUMBER >= 3007000







- (BOOL)startSavePointWithName:(NSString*)name error:(NSError**)outErr;



- (BOOL)releaseSavePointWithName:(NSString*)name error:(NSError**)outErr;



- (BOOL)rollbackToSavePointWithName:(NSString*)name error:(NSError**)outErr;



- (NSError*)inSavePoint:(void (^)(BOOL *rollback))block;

#endif







+ (BOOL)isSQLiteThreadSafe;



+ (NSString*)sqliteLibVersion;


+ (NSString*)FMG3DBUserVersion;

+ (SInt32)FMG3DBVersion;








- (void)makeFunctionNamed:(NSString*)name maximumArguments:(int)count withBlock:(void (^)(sqlite3_context *context, int argc, sqlite3_value **argv))block;








+ (NSDateFormatter *)storeableDateFormat:(NSString *)format;



- (BOOL)hasDateFormatter;



- (void)setDateFormat:(NSDateFormatter *)format;



- (NSDate *)dateFromString:(NSString *)s;



- (NSString *)stringFromDate:(NSDate *)date;

@end




@interface FMG3Statement : NSObject {
    sqlite3_stmt *_statement;
    NSString *_query;
    long _useCount;
    BOOL _inUse;
}







@property (atomic, assign) long useCount;



@property (atomic, retain) NSString *query;



@property (atomic, assign) sqlite3_stmt *statement;



@property (atomic, assign) BOOL inUse;







- (void)close;



- (void)reset;

@end

#pragma clang diagnostic pop
