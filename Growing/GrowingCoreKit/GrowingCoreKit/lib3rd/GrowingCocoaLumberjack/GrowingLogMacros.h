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


#ifndef Growing_LEGACY_MACROS
    #define Growing_LEGACY_MACROS 0
#endif

#import "GrowingLog.h"


#ifndef GIO_LOG_LEVEL_DEF
    #define GIO_LOG_LEVEL_DEF gioLogLevel
#endif


#ifndef LOG_ASYNC_ENABLED
    #define LOG_ASYNC_ENABLED YES
#endif


#define GIO_LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
        [GrowingLog log : isAsynchronous                                     \
             level : lvl                                                \
              flag : flg                                                \
           context : ctx                                                \
              file : __FILE__                                           \
          function : fnct                                               \
              line : __LINE__                                           \
               tag : atag                                               \
            format : (frmt), ## __VA_ARGS__]

#define GIO_LOG_MAYBE(async, lvl, flg, ctx, tag, fnct, frmt, ...) \
        do { if(lvl & flg) GIO_LOG_MACRO(async, lvl, flg, ctx, tag, fnct, frmt, ##__VA_ARGS__); } while(0)


#define GIOLogError(frmt, ...)   GIO_LOG_MAYBE(LOG_ASYNC_ENABLED, GIO_LOG_LEVEL_DEF, GrowingLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define GIOLogWarn(frmt, ...)    GIO_LOG_MAYBE(LOG_ASYNC_ENABLED, GIO_LOG_LEVEL_DEF, GrowingLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define GIOLogInfo(frmt, ...)    GIO_LOG_MAYBE(LOG_ASYNC_ENABLED, GIO_LOG_LEVEL_DEF, GrowingLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define GIOLogDebug(frmt, ...)   GIO_LOG_MAYBE(LOG_ASYNC_ENABLED, GIO_LOG_LEVEL_DEF, GrowingLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define GIOLogVerbose(frmt, ...) GIO_LOG_MAYBE(LOG_ASYNC_ENABLED, GIO_LOG_LEVEL_DEF, GrowingLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
