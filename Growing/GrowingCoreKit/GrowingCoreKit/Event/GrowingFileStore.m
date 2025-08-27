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


#import "GrowingFileStore.h"
#import <pthread.h>

static NSString *const GrowingFileStorePath = @"libGrowing";
static NSString *const GrowingUploadEventFile = @"GrowingUploadEventFile";
static NSString *const GrowingCellularUploadEventSize = @"GrowingCellularUploadEventSize";
static NSString *const GrowingDidUploadActivate = @"GrowingDidUploadActivate";

@interface GrowingFileStore ()

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSMutableDictionary *storeDict;

@end

@implementation GrowingFileStore

static pthread_mutex_t _mutex;
static GrowingFileStore *_instance;

+ (instancetype)shareInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc]  init];
        [_instance createFilePath];
        pthread_mutex_init(&_mutex,NULL);
    });
    return _instance;
}

- (void)createFilePath {
    
    NSString *growingFilePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:GrowingFileStorePath];
    if(![[NSFileManager defaultManager] fileExistsAtPath:growingFilePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:growingFilePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    if([[NSFileManager defaultManager] fileExistsAtPath:growingFilePath]) {
        self.filePath = [growingFilePath stringByAppendingPathComponent:GrowingUploadEventFile];
        self.storeDict = [NSMutableDictionary dictionaryWithContentsOfFile:self.filePath];
        if (!self.storeDict) {
            self.storeDict = [NSMutableDictionary dictionary];
        }
    }
}

+ (unsigned long long)cellularNetworkUploadEventSize {
    
    NSString *todayUploadEvent = [[GrowingFileStore shareInstance].storeDict valueForKey:GrowingCellularUploadEventSize];
    NSArray *todayUploadEventArray = [todayUploadEvent componentsSeparatedByString:@"/"];
    if (todayUploadEventArray.count >=2 && [[todayUploadEventArray objectAtIndex:1] isEqualToString:[self getTodayKey]]) {
        return [todayUploadEventArray.firstObject longLongValue];
    } else {
        return 0;
    }
}

+ (void)cellularNetworkStorgeEventSize:(unsigned long long)uploadEventSize {
    
    pthread_mutex_lock(&_mutex);
    NSString *todayUploadEvent = [NSString stringWithFormat:@"%@/%@", [NSString stringWithFormat:@"%llu",uploadEventSize], [self getTodayKey]];
    [[GrowingFileStore shareInstance].storeDict setObject:todayUploadEvent forKey:GrowingCellularUploadEventSize];
    [[GrowingFileStore shareInstance].storeDict.copy writeToFile:[GrowingFileStore shareInstance].filePath atomically:YES];
    pthread_mutex_unlock(&_mutex);
}

+ (NSString*)getTodayKey {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    return date;
}

+ (BOOL)didUploadActivate {
    return ((NSNumber *)[[GrowingFileStore shareInstance].storeDict valueForKey:GrowingDidUploadActivate]).boolValue;
}

+ (void)setDidUploadActivate:(BOOL)didUploadActivate {
    pthread_mutex_lock(&_mutex);
    [[GrowingFileStore shareInstance].storeDict setObject:@(didUploadActivate) forKey:GrowingDidUploadActivate];
    [[GrowingFileStore shareInstance].storeDict.copy writeToFile:[GrowingFileStore shareInstance].filePath atomically:YES];
    pthread_mutex_unlock(&_mutex);
}

@end
