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
#import "FMG3Database.h"




@interface FMG3Database (FMG3DatabaseAdditions)







- (int)intForQuery:(NSString*)query, ...;



- (long)longForQuery:(NSString*)query, ...;



- (BOOL)boolForQuery:(NSString*)query, ...;



- (double)doubleForQuery:(NSString*)query, ...;



- (NSString*)stringForQuery:(NSString*)query, ...;



- (NSData*)dataForQuery:(NSString*)query, ...;



- (NSDate*)dateForQuery:(NSString*)query, ...;













- (BOOL)tableExists:(NSString*)tableName;



- (FMG3ResultSet*)getSchema;



- (FMG3ResultSet*)getTableSchema:(NSString*)tableName;



- (BOOL)columnExists:(NSString*)columnName inTableWithName:(NSString*)tableName;



- (BOOL)columnExists:(NSString*)tableName columnName:(NSString*)columnName __attribute__ ((deprecated));




- (BOOL)validateSQL:(NSString*)sql error:(NSError**)error;


#if SQLITE_VERSION_NUMBER >= 3007017







- (uint32_t)applicationID;



- (void)setApplicationID:(uint32_t)appID;

#if TARGET_OS_MAC && !TARGET_OS_IPHONE



- (NSString*)applicationIDString;



- (void)setApplicationIDString:(NSString*)string;
#endif

#endif







- (uint32_t)userVersion;



- (void)setUserVersion:(uint32_t)version;

@end
