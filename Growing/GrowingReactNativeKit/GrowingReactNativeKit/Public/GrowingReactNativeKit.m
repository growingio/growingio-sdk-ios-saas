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


#import "GrowingReactNativeKit.h"
#import "GrowingVersionManager.h"

@implementation Growing (ReactNativeKit)

+ (void)load
{
    [GrowingVersionManager registerVersionInfo:@{@"rv":[Growing rnKitVersion]}];
}

static NSString* getDateFromMacro()
{
#ifdef RNKit_COMPILE_DATE_TIME
    
    
    return @metamacro_stringify(COMPILE_DATE_TIME);
#else
    int month, day, year;
    int h, m, s;
    char s_month[5];
    static const char month_names[] = "JanFebMarAprMayJunJulAugSepOctNovDec";
    sscanf(__DATE__, "%s %d %d", s_month, &day, &year);
    month = (int)(strstr(month_names, s_month)-month_names) / 3 + 1;
    sscanf(__TIME__ , "%d:%d:%d", &h, &m, &s);
    return [NSString stringWithFormat:@"%d%02d%02d%02d%02d%02d",year,month,day,h,m,s];
#endif
}

+ (NSString*)rnKitVersion
{
    static NSString *ver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifdef GROWINGIO_RN_SDK_VERSION
        const char * v = metamacro_stringify(GROWINGIO_RN_SDK_VERSION);
#else
        const char * v = "2.0";
#endif
#if defined(DEBUG) && DEBUG
        ver = [NSString stringWithFormat:@"%s-%@", v, @"debug"];
#else
        ver = [NSString stringWithFormat:@"%s", v];
#endif
    });
    return ver;
}

@end
