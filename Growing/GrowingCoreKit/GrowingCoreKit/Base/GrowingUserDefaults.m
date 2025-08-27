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


#import "GrowingUserDefaults.h"
#import "GrowingEventDataBase.h"

@interface GrowingUserDefaults()
@property (nonatomic, retain) GrowingEventDataBase *db;
@end



@implementation GrowingUserDefaults

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.db = [GrowingEventDataBase databaseWithName:@"GrowingIOUserDefaults"];
    }
    return self;
}

+ (instancetype)shareInstance
{
    static GrowingUserDefaults *_shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[self alloc] init];
    });
    return _shareInstance;
}

- (void)setValue:(NSString *)value forKey:(NSString *)key
{
    [self.db setValue:value forKey:key];
}

- (NSString*)valueForKey:(NSString *)key
{
    return [self.db valueForKey:key];
}

@end
