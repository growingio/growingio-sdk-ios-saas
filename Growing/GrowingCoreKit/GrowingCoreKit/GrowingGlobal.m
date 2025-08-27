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
#import <CoreLocation/CoreLocation.h>
#import "GrowingGlobal.h"

const NSUInteger    g_K                     = 1024;
const NSUInteger    g_M                     = g_K * g_K;

BOOL                g_doNotTrack            = NO;
BOOL                g_GDPRFlag              = NO;
BOOL                g_readClipBoardEnable   = YES;
BOOL                g_asaEnabled            = NO;
BOOL                g_writeLogToFile        = NO;
NSTimeInterval      g_flushInterval         = 15; 
NSTimeInterval      g_sessionInterval       = 30; 
const NSUInteger    g_maxDBCacheSize        = 300; 
const NSUInteger    g_maxBatchSize          = 500; 
unsigned long long  g_uploadLimitOfCellular = 20 * g_M; 
BOOL                g_enableImp             = NO;
BOOL                g_allWebViewsDisabled   = NO;
BOOL                g_locationEnabled       = YES;
BOOL                g_isHashTagEnabled      = NO;
BOOL                g_dataCounterEnable     = YES;

double              g_dimentionOfSmallItem  = 50;
double              g_magnifierScaleFactor  = 2.0f;
double              g_magnifierWidth        = 78;
double              g_magnifierHeight       = 53;

const NSUInteger    g_maxCountOfKVPairs     = 100;
const NSUInteger    g_maxLengthOfKey        = 50;
const NSUInteger    g_maxLengthOfValue      = 1000;
GrowingSDKDistributedMode getSDKDistributedMode() {
#ifdef GROWING_SDK_DISTRIBUTED_MODE
    return GROWING_SDK_DISTRIBUTED_MODE;
#else
    return GrowingDistributeForSaaS;
#endif
}

BOOL SDKDoNotTrack() {
    if (!g_GDPRFlag) {
        
        return g_doNotTrack;
    } else {
        return YES;
    }
}
