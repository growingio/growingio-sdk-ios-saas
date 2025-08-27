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


#import "GrowingCustomField+AutoTrackKit.h"
#import "NSDictionary+GrowingHelper.h"
#import <objc/runtime.h>
#import "GrowingEventManager.h"
#import "GrowingAutoTrackEvent.h"
#import "GrowingDispatchManager.h"
#import "GrowingGlobal.h"

@implementation GrowingCustomField (AutoTrackKit)

- (void)mergeGrowingAttributesAvar:(NSDictionary<NSString *, NSObject *> *)growingAttributesAvar
{
    
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:growingAttributesAvar];
    if (![dict isValidDicVar]) {
        return;
    }
    if (dict.count > 100 ) {
        NSLog(parameterValueErrorLog);
        return;
    }
    BOOL somethingWasChange = [self.growingAttributesMutableAvar mergeGrowingAttributesVar:dict];
    if (!somethingWasChange) {
        return;
    }
    
    [GrowingPageEvent resendPageEvent];
}

- (void)removeGrowingAttributesAvar:(NSString *)key
{
    [self.growingAttributesMutableAvar removeGrowingAttributesVar:key];
}

- (NSMutableDictionary<NSString *, NSObject *> *)growingAttributesMutableAvar
{
    static char __theClass__growingAttributesAvar_key;
    NSMutableDictionary<NSString *, NSObject *> * avar = objc_getAssociatedObject(self,&__theClass__growingAttributesAvar_key);
    if (avar == nil)
    {
        avar = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self,
                                 &__theClass__growingAttributesAvar_key,
                                 avar,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return avar;
}

- (NSDictionary<NSString *, NSObject *> *)growingAttributesAvar
{
    return [[self growingAttributesMutableAvar] copy];
}

@end
