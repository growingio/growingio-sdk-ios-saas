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


#import "GrowingEventDataBase.h"
#import "FMDBG3.h"
#import <pthread.h>

#define TABLE_NAME @"namedcachetable"
#define VACUUM_DATE(name) [NSString stringWithFormat:@"GIO_VACUUM_DATE_E7B96C4E-6EE2-49CD-87F0-B2E62D4EE96A-%@",name]

static void transferDataBaseto_0_9_14()
{
    NSString *dirPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"libGrowing"];
    NSString *oldPath = [dirPath stringByAppendingString:@"/growing.sqlite"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:oldPath])
    {
        FMG3Database *oldDB = [[FMG3Database alloc] initWithPath:oldPath];
        if ([oldDB open])
        {
            NSArray *namesArray = @[@"trackCirclekeyevent"
                                    ,@"trackCircleevent"
                                    ,@"growingkeyevent"
                                    ,@"growingevent"];
            NSString *newDefaultPath = [dirPath stringByAppendingString:@"/default.sqlite"];
            FMG3ResultSet *set =
            [oldDB executeQuery:@"select * from namedcachetable where name not in (?,?,?,?)"
                         values:namesArray
                          error:nil];
            FMG3Database *newDefaultDB = [[FMG3Database alloc] initWithPath:newDefaultPath];
            
            if ([newDefaultDB open])
            {
                NSString* sql = @"create table if not exists namedcachetable("
                @"id INTEGER PRIMARY KEY,"
                @"name text,"
                @"key text,"
                @"value text);";
                NSString * sqlCreateIndexNameKey = @"create index if not exists namedcachetable_name_key on namedcachetable (name, key);";
                NSString * sqlCreateIndexNameId = @"create index if not exists namedcachetable_name_id on namedcachetable (name, id);";
                NSError *error = nil;
                [newDefaultDB beginTransaction];
                [newDefaultDB executeUpdate:sql values:nil error:&error];
                [newDefaultDB executeUpdate:sqlCreateIndexNameKey values:nil error:&error];
                [newDefaultDB executeUpdate:sqlCreateIndexNameId values:nil error:&error];
                [newDefaultDB commit];
                
                
                NSString *name = nil;
                NSString *key = nil;
                NSString *value = nil;
                
                while ([set next]) {
                    name  = [set stringForColumn:@"name"];
                    key   = [set stringForColumn:@"key"];
                    value = [set stringForColumn:@"value"];
                    
                    if(name.length && key.length && value.length)
                    {
                        [newDefaultDB executeUpdate:@"insert into namedcachetable(name,key,value) values(?,?,?)"
                                             values:@[name,key,value]
                                              error:nil];
                    }
                }
                [newDefaultDB close];
            }
            [set close];
            
            [oldDB executeUpdate:@"delete from namedcachetable where name not in (?,?,?,?)"
                          values:namesArray
                             error:nil];
            [oldDB close];
        }
        NSString *newEventPath = [dirPath stringByAppendingString:@"/event.sqlite"];
        [fm moveItemAtPath:oldPath
                    toPath:newEventPath
                     error:nil];
    }
    
    
}

@interface _GrowingDataBaseWithMutex : FMG3Database
{
    pthread_mutex_t _databaseMutex;
}

@property (nonatomic, readonly) pthread_mutex_t *dbMutex;

@end

@implementation _GrowingDataBaseWithMutex

- (instancetype)initWithPath:(NSString *)inPath
{
    self = [super initWithPath:inPath];
    if (self)
    {
        pthread_mutex_init(&_databaseMutex,NULL);
    }
    return self;
}

- (pthread_mutex_t*)dbMutex
{
    return &_databaseMutex;
}

@end


@interface GrowingEventDataBase()
{
    BOOL _stopAutoUpdate;
    pthread_mutex_t updateArrayMutext;

}

@property (nonatomic, retain) _GrowingDataBaseWithMutex *db;

@property (nonatomic, retain) NSMutableArray *updateKeys;
@property (nonatomic, retain) NSMutableArray *updateValues;

@property (nonatomic, copy, readonly) NSString *sqliteName;

@end

@implementation GrowingEventDataBase

+ (instancetype)databaseWithName:(NSString *)name
{
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"libGrowing/default.sqlite"];
    return [self databaseWithPath:path name:name];
}

+ (instancetype)databaseWithPath:(NSString *)path name:(NSString *)name
{
    return [[self alloc] initWithFilePath:path andName:name];
}


- (void)makeDirByFileName:(NSString*)filePath
{
    [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
}

static  NSMapTable *dbMap = nil;

- (instancetype)initWithFilePath:(NSString*)filePath andName:(NSString*)name
{
    self = [super init];
    if (self)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self makeDirByFileName:filePath];
            transferDataBaseto_0_9_14();
        });
        
        pthread_mutex_init(&updateArrayMutext,NULL);
        _name = name;
        
        if (filePath.length > 0) {
            NSArray *cArray = [filePath componentsSeparatedByString:@"/"];
            if (cArray.count > 0) {
                _sqliteName = cArray.lastObject;
            }
        }
        
        
        self.updateValues = [[NSMutableArray alloc] init];
        self.updateKeys = [[NSMutableArray alloc] init];
        
        if (!dbMap)
        {
            dbMap = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                                            | NSPointerFunctionsObjectPersonality
                                              valueOptions:NSPointerFunctionsWeakMemory
                                                  capacity:2];
        }
        _GrowingDataBaseWithMutex *db = [dbMap objectForKey:filePath];
        if (!db)
        {
            db = [[_GrowingDataBaseWithMutex alloc] initWithPath:filePath];
            [dbMap setObject:db forKey:filePath];
        }
        
        self.db = db;
        [self initDB];
    }
    return self;
}

static BOOL isExecuteVaccum(NSString *name)
{
    if (name.length == 0) {
        return NO;
    }
    NSUserDefaults *userDefalut = [NSUserDefaults standardUserDefaults];
    NSDate *beforeDate = [userDefalut objectForKey:VACUUM_DATE(name)];

    NSDate *nowDate = [NSDate date];

    if (beforeDate) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSCalendarUnit unit = NSCalendarUnitDay;
        NSDateComponents *delta = [calendar components:unit fromDate:beforeDate toDate:nowDate options:0];
        BOOL flag;
        if (delta.day > 30) {
            flag = YES;
        } else if (delta.day < 0) {
            flag = YES;
        } else {
            flag = NO;
        }
        
        if (flag) {
            [userDefalut setObject:nowDate forKey:VACUUM_DATE(name)];
        }
        return flag;
    } else {
        [userDefalut setObject:nowDate forKey:VACUUM_DATE(name)];
        return YES;
    }
}

- (void)initDB
{
    [self performDataBaseBlock:^(FMG3Database *db) {
        NSString* sql = @"create table if not exists namedcachetable("
        @"id INTEGER PRIMARY KEY,"
        @"name text,"
        @"key text,"
        @"value text);";
        NSString * sqlCreateIndexNameKey = @"create index if not exists namedcachetable_name_key on namedcachetable (name, key);";
        NSString * sqlCreateIndexNameId = @"create index if not exists namedcachetable_name_id on namedcachetable (name, id);";
        NSError *error = nil;
        [db beginTransaction];
        [db executeUpdate:sql values:nil error:&error];
        [db executeUpdate:sqlCreateIndexNameKey values:nil error:&error];
        [db executeUpdate:sqlCreateIndexNameId values:nil error:&error];
        [db commit];
    }];


}
- (void)setValue:(NSString *)value forKey:(NSString *)key
{
    [self setValue:value forKey:key error:nil];
}

- (void)setValue:(NSString *)value forKey:(NSString *)key error:(NSError *__autoreleasing *)outerror
{
    if (!key.length)
    {
        return;
    }
    
    __block NSUInteger count = 0;
    [self performModifyArrayBlock:^{
        [self.updateKeys addObject:key];
        [self.updateValues addObject:value ? value : [NSNull null]];
        count = self.updateValues.count;
    }];
    if (count >= self.autoFlushCount)
    {
        NSError *error = [self flush];
        if (error && outerror)
        {
            *outerror = error;
        }
    }
}

- (NSString*)valueForKey:(NSString *)key
{
    return [self valueForKey:key error:nil];
}

- (NSString*)valueForKey:(NSString *)key error:(NSError *__autoreleasing *)outerror
{
    if (key.length == 0)
    {
        return nil;
    }
    __block NSString *result = nil;
    __block BOOL hitCache = NO;
    [self performModifyArrayBlock:^{
        for (NSInteger i = self.updateKeys.count - 1 ; i >= 0 ; i --)
        {
            if ([self.updateKeys[i] isEqualToString:key])
            {
                NSString *value = self.updateValues[i];
                
                if ([value isKindOfClass:[NSNull class]])
                {
                    result = nil;
                }
                else
                {
                    result = value;
                }
                hitCache = YES;
                return ;
            }
        }
    }];
    
    if (hitCache)
    {
        return result;
    }
    
    __block NSError *readError = nil;
    NSError *openError =
    [self performDataBaseBlock:^(FMG3Database *db) {
        NSError *dbError = nil;
        FMG3ResultSet *set =
        [db executeQuery:@"select * from namedcachetable where name=? and key=?"
                  values:@[self.name,key]
                   error:&dbError];
       
        if (outerror && dbError)
        {
            readError = [NSError errorWithDomain:@"db readError" code:GrowingEventDataBaseReadError userInfo:nil];
        }
        
        if ([set next])
        {
            result = [set stringForColumn:@"value"];
        }
        [set close];
    }];
    
    if (outerror)
    {
        *outerror = openError ? openError : readError ;
    }
    
    return result;
}

- (NSUInteger)countOfEvents
{
    [self flush];
    __block NSInteger count = 0;
    [self performDataBaseBlock:^(FMG3Database *db) {
        FMG3ResultSet *set =
        [db executeQuery:@"select count(*) from namedcachetable where name=?"
                  values:@[self.name]
                   error:nil];
        if ([set next])
        {
            count = (NSUInteger)[set longLongIntForColumnIndex:0];
        }
        [set close];
    }];
    return count;
}

- (NSError*)enumerateKeysAndValuesUsingBlock:(void (^)(NSString *, NSString *, BOOL *))block
{
    if (!block)
    {
        return nil;
    }
    [self flush];
    
    __block NSError *readError = nil;
    NSError *openErr =
    [self performDataBaseBlock:^(FMG3Database *db) {
        NSError *dbErr = nil;
        FMG3ResultSet *set =
        [db executeQuery:@"select * from namedcachetable where name=? order by id asc"
                  values:@[self.name]
                   error:&dbErr];
        if (dbErr && readError)
        {
            readError = dbErr;
        }
        
        BOOL stop = NO;
        while (!stop && [set next]) {
            NSString *key = [set stringForColumn:@"key"];
            NSString *value = [set stringForColumn:@"value"];
            block(key,value,&stop);
        }
        [set close];
    }];
        
    return openErr ? openErr : readError;
}

- (NSError*)clearAllItems
{
    NSError *err1 = [self flush];
    NSError *err2 =
    [self performDataBaseBlock:^(FMG3Database *db) {
        [db executeUpdate:@"delete from namedcachetable where name=?"
                        values:@[self.name]
                         error:nil];
    }];
    return err1 ? err1 : err2;
}

#pragma mark - perform
- (NSError*)performDataBaseBlock:(void(^)(FMG3Database *db))block
{
    NSError *err = nil;
    pthread_mutex_lock(self.db.dbMutex);
    
    if ([self.db open])
    {
        block(self.db);
        [self.db close];
    }
    else
    {
        err = [NSError errorWithDomain:@"open db error" code:GrowingEventDataBaseOpenError userInfo:nil];
    }
    pthread_mutex_unlock(self.db.dbMutex);
    return err;
}

- (void)performModifyArrayBlock:(void(^)())block
{
    pthread_mutex_lock(&updateArrayMutext);
    block();
    pthread_mutex_unlock(&updateArrayMutext);
}

#pragma mark - flush


- (NSError*)flush_insertDataBase:(FMG3Database*)db byKeys:(NSArray*)keys values:(NSArray*)values
{
    if (keys.count == 0 || keys.count != values.count)
    {
        return nil;
    }
    NSMutableString *valueString = [[NSMutableString alloc] init];
    NSMutableArray *paramsArr = [[NSMutableArray alloc] init];
    for (NSInteger i = 0 ; i < keys.count ; i ++)
    {
        if (i == 0)
        {
            [valueString appendString:@"(?,?,?)"];
        }
        else
        {
            [valueString appendString:@",(?,?,?)"];
        }
        [paramsArr addObject:self.name];
        [paramsArr addObject:keys[i]];
        [paramsArr addObject:values[i]];
    }
    NSString *sql = [[NSString alloc] initWithFormat:@"insert into namedcachetable(name,key,value) values%@",valueString];
    NSError *error = nil;
    [db executeUpdate:sql
               values:paramsArr
                error:&error];
    return error;
}


- (NSError *)flush_insertDataBaseV2:(FMG3Database *)db byKeys:(NSArray *)keys values:(NSArray *)values {
    if (!keys || keys.count == 0) {
        return nil;
    }
    
    if (!values || values.count == 0) {
        return nil;
    }
    
    if (keys.count != values.count) {
        return nil;
    }
    
    NSError *error = nil;
    for (NSInteger i = 0 ; i < keys.count ; i++) {
        BOOL result = [db executeUpdate:@"insert into namedcachetable(name,key,value) values(?,?,?)", self.name, keys[i], values[i]];
        if (!result) {
            error = [db lastError];
            break;
        }
    }
    return error;
}


- (NSError *)flush_deleteDataBase:(FMG3Database*)db byKeys:(NSArray*)keys
{
    if (keys.count == 0)
    {
        return nil;
    }
    
    NSMutableString *orStr = [[NSMutableString alloc] init];
    for (NSInteger i = 0 ; i < keys.count ; i++)
    {
        if (i == 0)
        {
            [orStr appendString:@"key=?"];
        }
        else
        {
            [orStr appendString:@" OR key=?"];
        }
    }
    NSString *sql = [[NSString alloc] initWithFormat:@"delete from namedcachetable where name=? and (%@)",orStr];
    NSError *error = nil;
    [db executeUpdate:sql
               values:[@[self.name] arrayByAddingObjectsFromArray:keys]
                error:&error];
    return error;
}


- (NSError *)flush_deleteDataBaseV2:(FMG3Database *)db byKeys:(NSArray *)keys {
    if (!keys || keys.count == 0) {
        return nil;
    }
    
    NSError *error = nil;
    for (NSString *key in keys) {
        BOOL result = [db executeUpdate:@"delete from namedcachetable where name=? and key=?;", self.name, key];
        if (!result) {
            error = [db lastError];
            break;
        }
    }
    return error;
}

- (NSError*)flush
{
    NSMutableArray *removeArr = [[NSMutableArray alloc] init];
    NSMutableArray *updateKeyArr = [[NSMutableArray alloc] init];
    NSMutableArray *updateValueArr = [[NSMutableArray alloc] init];
    
    [self performModifyArrayBlock:^{
        if (!self.updateKeys.count)
        {
            return ;
        }
        
        
        NSHashTable *checkTable = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsObjectPersonality
                                   | NSPointerFunctionsStrongMemory
                                                              capacity:self.updateValues.count];
        NSString *key = nil;
        NSString *value = nil;
        
        
        for (NSInteger i = self.updateValues.count - 1 ; i >= 0 ; i--)
        {
            key = self.updateKeys[i];
            value = self.updateValues[i];
            
            if ([checkTable containsObject:key])
            {
                continue;
            }
            else
            {
                [checkTable addObject:key];
            }
            
            
            [removeArr addObject:key];
            
            if (value != nil && ![value isKindOfClass:[NSNull class]])
            {
                
                [updateKeyArr insertObject:key atIndex:0];
                [updateValueArr insertObject:value atIndex:0];
            }
            
        }
        
        [self.updateValues removeAllObjects];
        [self.updateKeys removeAllObjects];
    }];
    
    __block NSError *writeError = nil;
    NSError *openError =
    [self performDataBaseBlock:^(FMG3Database *db) {
        
        [db beginTransaction];
        NSError *err1 = [self flush_deleteDataBaseV2:db byKeys:removeArr];
        NSError *err2 = [self flush_insertDataBaseV2:db byKeys:updateKeyArr values:updateValueArr];
        [db commit];
        
        if (err1 || err2) {
            writeError = [NSError errorWithDomain:@"db write error" code:GrowingEventDataBaseWriteError userInfo:nil];
        }
    }];
    
    return openError ? openError : writeError;
}

- (NSError*)vacuum
{
    if (!isExecuteVaccum(self.sqliteName)) {
        return nil;
    }
    
    NSError *vacuumError =
    [self performDataBaseBlock:^(FMG3Database *db) {
        [db executeUpdate:@"VACUUM namedcachetable"];
    }];
    return vacuumError;
}

@end
