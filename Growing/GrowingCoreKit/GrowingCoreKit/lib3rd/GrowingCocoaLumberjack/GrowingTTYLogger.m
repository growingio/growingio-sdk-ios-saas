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


#import "GrowingTTYLogger.h"

#import <sys/uio.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif








#ifndef Growing_NSLOG_LEVEL
    #define Growing_NSLOG_LEVEL 2
#endif

#define NSLogError(frmt, ...)    do{ if(Growing_NSLOG_LEVEL >= 1) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogWarn(frmt, ...)     do{ if(Growing_NSLOG_LEVEL >= 2) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogInfo(frmt, ...)     do{ if(Growing_NSLOG_LEVEL >= 3) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogDebug(frmt, ...)    do{ if(Growing_NSLOG_LEVEL >= 4) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogVerbose(frmt, ...)  do{ if(Growing_NSLOG_LEVEL >= 5) NSLog((frmt), ##__VA_ARGS__); } while(0)



























#pragma mark -


@interface GrowingTTYLogger () {
    NSString *_appName;
    char *_app;
    size_t _appLen;
    
    NSString *_processID;
    char *_pid;
    size_t _pidLen;
    
}

@end


@implementation GrowingTTYLogger

static GrowingTTYLogger *sharedInstance;


+ (instancetype)sharedInstance {
    static dispatch_once_t GrowingTTYLoggerOnceToken;

    dispatch_once(&GrowingTTYLoggerOnceToken, ^{
        
        
        
        

        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    if (sharedInstance != nil) {
        return nil;
    }

    if (@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)) {

    }

    if ((self = [super init])) {
        

        _appName = [[NSProcessInfo processInfo] processName];

        _appLen = [_appName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

        if (_appLen == 0) {
            _appName = @"<UnnamedApp>";
            _appLen = [_appName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        }

        _app = (char *)calloc(_appLen + 1, sizeof(char));

        if (_app == NULL) {
            return nil;
        }

        BOOL processedAppName = [_appName getCString:_app maxLength:(_appLen + 1) encoding:NSUTF8StringEncoding];

        if (NO == processedAppName) {
            free(_app);
            return nil;
        }

        

        _processID = [NSString stringWithFormat:@"%i", (int)getpid()];

        _pidLen = [_processID lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        _pid = (char *)calloc(_pidLen + 1, sizeof(char));

        if (_pid == NULL) {
            free(_app);
            return nil;
        }

        BOOL processedID = [_processID getCString:_pid maxLength:(_pidLen + 1) encoding:NSUTF8StringEncoding];

        if (NO == processedID) {
            free(_app);
            free(_pid);
            return nil;
        }
        _automaticallyAppendNewlineForCustomFormatters = YES;
    }

    return self;
}

- (GrowingLoggerName)loggerName {
    return GrowingLoggerNameTTY;
}

- (void)logMessage:(GrowingLogMessage *)logMessage {
    NSString *logMsg = logMessage->_message;
    BOOL isFormatted = NO;

    if (_logFormatter) {
        logMsg = [_logFormatter formatLogMessage:logMessage];
        isFormatted = logMsg != logMessage->_message;
    }

    if (logMsg) {
        
        
        
        
        

        NSUInteger msgLen = [logMsg lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        const BOOL useStack = msgLen < (1024 * 4);

        char msgStack[useStack ? (msgLen + 1) : 1]; 
        char *msg = useStack ? msgStack : (char *)calloc(msgLen + 1, sizeof(char));

        if (msg == NULL) {
            return;
        }

        BOOL logMsgEnc = [logMsg getCString:msg maxLength:(msgLen + 1) encoding:NSUTF8StringEncoding];

        if (!logMsgEnc) {
            if (!useStack && msg != NULL) {
                free(msg);
            }

            return;
        }

        

        if (isFormatted) {
            
            int iovec_len = (_automaticallyAppendNewlineForCustomFormatters) ? 5 : 4;
            struct iovec v[iovec_len];

            v[0].iov_base = "";
            v[0].iov_len = 0;

            v[1].iov_base = "";
            v[1].iov_len = 0;

            v[iovec_len - 1].iov_base = "";
            v[iovec_len - 1].iov_len = 0;

            v[2].iov_base = (char *)msg;
            v[2].iov_len = msgLen;

            if (iovec_len == 5) {
                v[3].iov_base = "\n";
                v[3].iov_len = (msg[msgLen] == '\n') ? 0 : 1;
            }

            writev(STDERR_FILENO, v, iovec_len);
        } else {
            

            int len;
            char ts[24] = "";
            size_t tsLen = 0;

            
            
            if (logMessage->_timestamp) {
                NSTimeInterval epoch = [logMessage->_timestamp timeIntervalSince1970];
                struct tm tm;
                time_t time = (time_t)epoch;
                (void)localtime_r(&time, &tm);
                int milliseconds = (int)((epoch - floor(epoch)) * 1000.0);

                len = snprintf(ts, 24, "%04d-%02d-%02d %02d:%02d:%02d:%03d", 
                               tm.tm_year + 1900,
                               tm.tm_mon + 1,
                               tm.tm_mday,
                               tm.tm_hour,
                               tm.tm_min,
                               tm.tm_sec, milliseconds);

                tsLen = (NSUInteger)MAX(MIN(24 - 1, len), 0);
            }

            
            
            
            
            
            
            

            char tid[9];
            len = snprintf(tid, 9, "%s", [logMessage->_threadID cStringUsingEncoding:NSUTF8StringEncoding]);

            size_t tidLen = (NSUInteger)MAX(MIN(9 - 1, len), 0);

            

            struct iovec v[13];

            v[0].iov_base = "";
            v[0].iov_len = 0;

            v[1].iov_base = "";
            v[1].iov_len = 0;

            v[12].iov_base = "";
            v[12].iov_len = 0;

            v[2].iov_base = ts;
            v[2].iov_len = tsLen;

            v[3].iov_base = " ";
            v[3].iov_len = 1;

            v[4].iov_base = _app;
            v[4].iov_len = _appLen;

            v[5].iov_base = "[";
            v[5].iov_len = 1;

            v[6].iov_base = _pid;
            v[6].iov_len = _pidLen;

            v[7].iov_base = ":";
            v[7].iov_len = 1;

            v[8].iov_base = tid;
            v[8].iov_len = MIN((size_t)8, tidLen); 

            v[9].iov_base = "] ";
            v[9].iov_len = 2;

            v[10].iov_base = (char *)msg;
            v[10].iov_len = msgLen;

            v[11].iov_base = "\n";
            v[11].iov_len = (msg[msgLen] == '\n') ? 0 : 1;

            writev(STDERR_FILENO, v, 13);
        }

        if (!useStack) {
            free(msg);
        }
    }
}

@end
