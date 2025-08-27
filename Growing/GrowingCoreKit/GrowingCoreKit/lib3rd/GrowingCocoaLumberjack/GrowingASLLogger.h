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


#ifndef Growing_LEGACY_MACROS
    #define Growing_LEGACY_MACROS 0
#endif

#import "GrowingLog.h"

NS_ASSUME_NONNULL_BEGIN


extern const char* const kGIOASLKeyDDLog;


extern const char* const kGIOASLDDLogValue;


API_DEPRECATED("Use GrowingOSLogger instead", macosx(10.4,10.12), ios(2.0,10.0), watchos(2.0,3.0), tvos(9.0,10.0))
@interface GrowingASLLogger : GrowingAbstractLogger <GrowingLogger>


@property (nonatomic, class, readonly, strong) GrowingASLLogger *sharedInstance;






@end

NS_ASSUME_NONNULL_END
