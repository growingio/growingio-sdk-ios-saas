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

NS_ASSUME_NONNULL_BEGIN

typedef NSString *GrowingLoggerName NS_TYPED_EXTENSIBLE_ENUM;

FOUNDATION_EXPORT GrowingLoggerName const GrowingLoggerNameOS NS_SWIFT_NAME(GrowingLoggerName.os); 
FOUNDATION_EXPORT GrowingLoggerName const GrowingLoggerNameFile NS_SWIFT_NAME(GrowingLoggerName.file); 

FOUNDATION_EXPORT GrowingLoggerName const GrowingLoggerNameTTY NS_SWIFT_NAME(GrowingLoggerName.tty); 

API_DEPRECATED("Use GrowingOSLogger instead", macosx(10.4, 10.12), ios(2.0, 10.0), watchos(2.0, 3.0), tvos(9.0, 10.0))
FOUNDATION_EXPORT GrowingLoggerName const GrowingLoggerNameASL NS_SWIFT_NAME(GrowingLoggerName.asl); 

FOUNDATION_EXPORT GrowingLoggerName const GrowingLoggerNameWS NS_SWIFT_NAME(GrowingLoggerName.ws); 

NS_ASSUME_NONNULL_END
