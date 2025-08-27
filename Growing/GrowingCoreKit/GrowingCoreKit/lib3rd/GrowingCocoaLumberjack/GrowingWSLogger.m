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


#import "GrowingWSLogger.h"

static const NSInteger kGIOMaxCachesLogNumber = 100;

@interface GrowingWSLogger ()

@property (nonatomic, strong) NSMutableArray *cacheArray;

@end

@implementation GrowingWSLogger

+ (instancetype)sharedInstance {

    static GrowingWSLogger *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.cacheArray      = [NSMutableArray array];
        sharedInstance.maxCachesNumber = kGIOMaxCachesLogNumber;
    });
    return sharedInstance;
}

- (GrowingLoggerName)loggerName {
    return GrowingLoggerNameWS;
}

- (void)logMessage:(GrowingLogMessage *)logMessage {
    NSString *logMsg = logMessage->_message;
    BOOL isFormatted = NO;
    if (_logFormatter) {
        logMsg      = [_logFormatter formatLogMessage:logMessage];
        isFormatted = logMsg != logMessage->_message;
    }

    
    NSTimeInterval epoch = [logMessage->_timestamp timeIntervalSince1970];
    struct tm tm;
    time_t time = (time_t)epoch;
    (void)localtime_r(&time, &tm);
    int milliseconds = (int)((epoch - floor(epoch)) * 1000.0);
    NSString *timeStamp = [NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d:%03d", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec, milliseconds];
    
    
    
    if (logMsg) {
        if (0) {
            
            
            
            
        } else {
              while ((NSInteger)self.cacheArray.count >= self.maxCachesNumber) {
                  [self.cacheArray removeObjectAtIndex:0];
              }
            [self.cacheArray addObject:logMessage];
        }
    }
}

@end
