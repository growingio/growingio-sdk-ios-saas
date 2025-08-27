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


#import "NSObject+GrowingIvarHelper.h"
#import <objc/runtime.h>

@implementation NSObject(GrowingIvarHelper)

- (BOOL)growingHelper_getIvar:(const char *)ivarName outObj:(id *)outObj
{
    id ret = nil;
    Ivar var = object_getInstanceVariable(self,ivarName,(void**)&ret);
    if (outObj)
    {
        *outObj = [[ret retain] autorelease];
    }
    if (var)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
