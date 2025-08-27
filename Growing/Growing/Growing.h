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


#if !defined(__has_include)
#error "Growing.h won't import anything if your compiler doesn't support __has_include. Please \
import the headers individually."
#else
    #if __has_include(<GrowingCDPCoreKit/GrowingCoreKit.h>)
    #import <GrowingCDPCoreKit/GrowingCoreKit.h>
    #endif
    #if __has_include(<GrowingCoreKit/GrowingCoreKit.h>)
    #import <GrowingCoreKit/GrowingCoreKit.h>
    #endif
    #if __has_include(<GrowingAutoTrackKit/GrowingAutoTrackKit.h>)
    #import <GrowingAutoTrackKit/GrowingAutoTrackKit.h>
    #endif
    #if __has_include(<GrowingReactNativeKit/GrowingReactNativeKit.h>)
    #import <GrowingReactNativeKit/GrowingReactNativeKit.h>
    #endif


#endif
