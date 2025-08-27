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


#import "GrowingASLLogger.h"

#if !TARGET_OS_WATCH
#import <asl.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

const char* const kGIOASLKeyDDLog = "GrowingLog";

const char* const kGIOASLDDLogValue = "1";

static GrowingASLLogger *sharedInstance;

@interface GrowingASLLogger () {
    aslclient _client;
}

@end


@implementation GrowingASLLogger

+ (instancetype)sharedInstance {
    static dispatch_once_t GrowingASLLoggerOnceToken;

    dispatch_once(&GrowingASLLoggerOnceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    if (sharedInstance != nil) {
        return nil;
    }

    if ((self = [super init])) {
        
        

        _client = asl_open(NULL, "com.apple.console", 0);
    }

    return self;
}

- (GrowingLoggerName)loggerName {
    return GrowingLoggerNameASL;
}

- (void)logMessage:(GrowingLogMessage *)logMessage {
    
    if ([logMessage->_fileName isEqualToString:@"GrowingASLLogCapture"]) {
        return;
    }

    NSString * message = _logFormatter ? [_logFormatter formatLogMessage:logMessage] : logMessage->_message;

    if (message) {
        const char *msg = [message UTF8String];

        size_t aslLogLevel;
        switch (logMessage->_flag) {
            
            
            case GrowingLogFlagError     : aslLogLevel = ASL_LEVEL_CRIT;     break;
            case GrowingLogFlagWarning   : aslLogLevel = ASL_LEVEL_ERR;      break;
            case GrowingLogFlagInfo      : aslLogLevel = ASL_LEVEL_WARNING;  break; 
            case GrowingLogFlagDebug     :
            case GrowingLogFlagVerbose   :
            default                 : aslLogLevel = ASL_LEVEL_NOTICE;   break;
        }

        static char const *const level_strings[] = { "0", "1", "2", "3", "4", "5", "6", "7" };

        
        uid_t const readUID = geteuid();

        char readUIDString[16];
#ifndef NS_BLOCK_ASSERTIONS
        size_t l = (size_t)snprintf(readUIDString, sizeof(readUIDString), "%d", readUID);
#else
        snprintf(readUIDString, sizeof(readUIDString), "%d", readUID);
#endif

        NSAssert(l < sizeof(readUIDString),
                 @"Formatted euid is too long.");
        NSAssert(aslLogLevel < (sizeof(level_strings) / sizeof(level_strings[0])),
                 @"Unhandled ASL log level.");

        aslmsg m = asl_new(ASL_TYPE_MSG);
        if (m != NULL) {
            if (asl_set(m, ASL_KEY_LEVEL, level_strings[aslLogLevel]) == 0 &&
                asl_set(m, ASL_KEY_MSG, msg) == 0 &&
                asl_set(m, ASL_KEY_READ_UID, readUIDString) == 0 &&
                asl_set(m, kGIOASLKeyDDLog, kGIOASLDDLogValue) == 0) {
                asl_send(_client, m);
            }
            asl_free(m);
        }
        
    }
}

@end

#endif
