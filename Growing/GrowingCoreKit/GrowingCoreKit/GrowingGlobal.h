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


#ifndef GrowingGlobal_h
#define GrowingGlobal_h

extern BOOL                 g_doNotTrack;
extern BOOL                 g_GDPRFlag;
extern BOOL                 g_readClipBoardEnable;
extern BOOL                 g_asaEnabled;
extern BOOL                 g_writeLogToFile;
extern NSTimeInterval       g_flushInterval;
extern NSTimeInterval       g_sessionInterval;
extern const NSUInteger     g_maxDBCacheSize;
extern const NSUInteger     g_maxBatchSize;
extern unsigned long long   g_uploadLimitOfCellular;
extern BOOL                 g_enableImp;
extern BOOL                 g_locationEnabled;
extern BOOL                 g_allWebViewsDisabled;
extern BOOL                 g_isHashTagEnabled;
extern BOOL                 g_dataCounterEnable;

extern double              g_dimentionOfSmallItem;
extern double              g_magnifierScaleFactor;
extern double              g_magnifierWidth;
extern double              g_magnifierHeight;


extern const NSUInteger g_maxCountOfKVPairs;
extern const NSUInteger g_maxLengthOfKey;
extern const NSUInteger g_maxLengthOfValue;

typedef NS_ENUM(NSInteger, GrowingSDKDistributedMode)
{
    GrowingDistributeForSaaS = 0,
    GrowingDistributeForOnPremise
};

GrowingSDKDistributedMode getSDKDistributedMode(void);

BOOL SDKDoNotTrack(void);
#define parameterKeyErrorLog @"当前数据的标识符不合法。合法的标识符的详细定义请参考：https://docs.growingio.com/v3/developer-manual/sdkintegrated/ios-sdk/ios-sdk-api/customize-api"
#define parameterValueErrorLog @"当前数据的值不合法。合法值的详细定义请参考：https://docs.growingio.com/v3/developer-manual/sdkintegrated/ios-sdk/ios-sdk-api/customize-api"



#define kHybridModeTrack 1


#define kHybridPatternServer 0

#endif
