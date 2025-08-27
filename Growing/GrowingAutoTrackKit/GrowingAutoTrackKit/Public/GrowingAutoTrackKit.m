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


#import "GrowingAutoTrackKit.h"
#import "GrowingInstance.h"
#import "UIViewController+GrowingNode.h"
#import "GrowingCustomField.h"
#import "GrowingCustomField+AutoTrackKit.h"
#import "GrowingEventManager.h"
#import "GrowingDeviceInfo.h"
#import "GrowingGlobal.h"
#import "GrowingNetworkConfig.h"
#import "GrowingDispatchManager.h"
#import "GrowingMediator+GrowingDeepLink.h"
#import "NSString+GrowingHelper.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingAutoTrackEvent.h"
#import "GrowingIMPTrack.h"
#import "UIView+GrowingNode.h"
#import <objc/runtime.h>
#import "GrowingVersionManager.h"

@implementation Growing (AutoTrackKit)

+ (void)load
{
    [GrowingVersionManager registerVersionInfo:@{@"av":[Growing autoTrackKitVersion]}];
}

static NSString* getDateFromMacro()
{
#ifdef AUTOKit_COMPILE_DATE_TIME
    
    
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

+ (NSString*)autoTrackKitVersion
{
    static NSString *ver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifdef GROWINGIO_AUTO_SDK_VERSION
        const char * v = metamacro_stringify(GROWINGIO_AUTO_SDK_VERSION);
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

static double growingGlobalImpScale = 0.0;
+ (void)setGlobalImpScale:(double)scale
{
    growingGlobalImpScale = scale;
}

+ (double)globalImpScale
{
    return growingGlobalImpScale;
}

+ (void)setIMPInterval:(NSTimeInterval)interval
{
    [GrowingIMPTrack shareInstance].IMPInterval = interval;
}

+ (NSTimeInterval)IMPInterval
{
    return [GrowingIMPTrack shareInstance].IMPInterval;
}


+ (void)setHybridJSSDKUrlPrefix:(NSString*)urlPrefix
{
    [GrowingNetworkConfig.sharedInstance setHybridJSSDKUrlPrefix:urlPrefix];
}

+ (void)enableAllWebViews:(BOOL)enable
{
    g_allWebViewsDisabled = !enable;
}

+ (void)enableHybridHashTag:(BOOL)enable
{
    g_isHashTagEnabled = enable;
}

+ (BOOL)isTrackingWebView
{
    return !g_allWebViewsDisabled;
}

+ (void)setImp:(BOOL)imp
{
    g_enableImp = imp;
}

+ (void)setPageVariable:(NSDictionary<NSString *, NSObject *> *)variable
       toViewController:(UIViewController *)viewController
{
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        if (!variable||([variable isKindOfClass:[NSDictionary class] ]&&variable.count==0)){
                [viewController removeGrowingAttributesPvar:nil];
           }else{
               if (![variable isKindOfClass:[NSDictionary class]]) {
                   NSLog(parameterValueErrorLog);
                   return ;
               }
               if (![variable isValidDicVar]) {
                   return ;
               }
               [viewController mergeGrowingAttributesPvar:variable];
           }

    }];
   
}

+ (void)setPageVariableWithKey:(NSString *)key
                andStringValue:(NSString *)stringValue
              toViewController:(UIViewController *)viewController
{
        if (![key isKindOfClass:[NSString class]]) {
            NSLog(parameterKeyErrorLog);
            return ;
        }
        if (![key isValidKey])
        {
            return ;
        }
        
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        if (stringValue != nil)
        {
            if (![stringValue isKindOfClass:[NSString class]])
            {
                NSLog(parameterValueErrorLog);
                return ;
            }
            if (stringValue.length > 1000 || stringValue.length == 0) {
                NSLog(parameterValueErrorLog);
                return ;
            }
            [viewController mergeGrowingAttributesPvar:@{key:stringValue}];
        }
        else
        {
            [viewController removeGrowingAttributesPvar:key];
        }
        
    }];
        
}

+ (void)setPageVariableWithKey:(NSString *)key
                andNumberValue:(NSNumber *)numberValue
              toViewController:(UIViewController *)viewController
{
   
        if (![key isKindOfClass:[NSString class]]) {
            NSLog(parameterKeyErrorLog);
            return ;
        }
        if (![key isValidKey])
        {
            return ;
        }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        if (numberValue != nil)
        {
            if (![numberValue isKindOfClass:[NSNumber class]])
            {
                NSLog(parameterValueErrorLog);
                return ;
            }
            [viewController mergeGrowingAttributesPvar:@{key:numberValue}];
        }
        else
        {
            [viewController removeGrowingAttributesPvar:key];
        }
        
    }];
        
}

+ (void)setAppVariable:(NSDictionary<NSString *, NSObject *> *)variable
{
        
    if (![variable isKindOfClass:[NSDictionary class]] ) {
           NSLog(parameterValueErrorLog);
           return ;
    }
    
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        [[GrowingCustomField shareInstance] mergeGrowingAttributesAvar:variable];

    }];
    
}

+ (void)setAppVariableWithKey:(NSString *)key andStringValue:(NSString *)stringValue
{
    
        
    if (![key isKindOfClass:[NSString class]]) {
        NSLog(parameterKeyErrorLog);
        return ;
    }
    if (![key isValidKey])
    {
        return ;
    }
     
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        
        if (stringValue != nil) {
            if (![stringValue isKindOfClass:[NSString class]])
            {
                NSLog(parameterValueErrorLog);
                return ;
            }
            if (stringValue.length > 1000 || stringValue.length == 0) {
                NSLog(parameterValueErrorLog);
                return ;
            }
            [[GrowingCustomField shareInstance] mergeGrowingAttributesAvar:@{key:stringValue}];
        }
        else
        {
            [[GrowingCustomField shareInstance] removeGrowingAttributesAvar:key];
        }
        
    }];
    
}

+ (void)setAppVariableWithKey:(NSString *)key andNumberValue:(NSNumber *)numbervalue
{
    
    if (![key isKindOfClass:[NSString class]]) {
        NSLog(parameterKeyErrorLog);
        return ;
    }
    if (![key isValidKey])
    {
        return ;
    }
        
    [GrowingDispatchManager trackApiSel:_cmd dispatchInMainThread:^{
        if (numbervalue != nil)
        {
            if (![numbervalue isKindOfClass:[NSNumber class]])
            {
                NSLog(parameterValueErrorLog);
                return ;
            }
            [[GrowingCustomField shareInstance] mergeGrowingAttributesAvar:@{key:numbervalue}];
        }
        else
        {
            [[GrowingCustomField shareInstance] removeGrowingAttributesAvar:key];
        }
        
    }];
        
}

+ (void)sendPage:(NSString *)pageName
{
    [GrowingPageEvent sendPage:pageName];
}

@end

@implementation UIView (GrowingImpression)

static char UIView_GrowingIMPTrack_scale;

- (double)growingImpScale
{
    NSNumber *number = objc_getAssociatedObject(self, &UIView_GrowingIMPTrack_scale);
    if (number) {
        return [number doubleValue];
    } else {
        return [Growing globalImpScale];
    }
}

- (void)setGrowingImpScale:(double)scale
{
    objc_setAssociatedObject(self, &UIView_GrowingIMPTrack_scale, [NSNumber numberWithDouble:scale], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)growingImpTrack:(NSString *)eventId
{
    [self growingImpTrack:eventId withNumber:nil andVariable:nil];
}

- (void)growingImpTrack:(NSString *)eventId withNumber:(NSNumber *)number
{
    [self growingImpTrack:eventId withNumber:number andVariable:nil];
}

- (void)growingImpTrack:(NSString *)eventId withVariable:(NSDictionary<NSString *, id> *)variable
{
    [self growingImpTrack:eventId withNumber:nil andVariable:variable];
}

- (void)growingImpTrack:(NSString *)eventId withNumber:(NSNumber *)number andVariable:(NSDictionary<NSString *, id> *)variable
{
    if (eventId.length == 0) {
        return;
    }
    
    if ([eventId isEqualToString:self.growingIMPTrackEventId]) {
        if ((number && [number isEqual:self.growingIMPTrackNumber]) || number == self.growingIMPTrackNumber) {
            if ((variable && [variable isEqualToDictionary:self.growingIMPTrackVariable]) || variable == self.growingIMPTrackVariable) {
                return;
            }
        }
    }
    
    [GrowingIMPTrack shareInstance].impTrackActive = YES;
    
    self.growingIMPTrackEventId = eventId;
    self.growingIMPTrackVariable = variable;
    self.growingIMPTrackNumber = number;
    self.growingIMPTracked = NO;
    [[GrowingIMPTrack shareInstance] addNode:self inSubView:NO];
}

- (void)growingStopImpTrack
{
    [[GrowingIMPTrack shareInstance] clearNode:self];
}

@end
