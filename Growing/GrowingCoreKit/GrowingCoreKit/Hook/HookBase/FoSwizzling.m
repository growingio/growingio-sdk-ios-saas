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


#import <objc/runtime.h>

#import "FoSwizzling.h"
#import <mach-o/getsect.h>

void* fo_imp_hook_function(Class clazz,
                    SEL   sel,
                    void  *newFunction)
{
    Method oldMethod = class_getInstanceMethod(clazz, sel);
    BOOL succeed = class_addMethod(clazz,
                                   sel,
                                   (IMP)newFunction,
                                   method_getTypeEncoding(oldMethod));
    if (succeed)
    {
        return nil;
    }
    else
    {
        return method_setImplementation(oldMethod, (IMP)newFunction);
    }
}

BOOL _fo_check_hook_function(SEL sel,NSInteger paramCount)
{
    BOOL succeed = (([NSStringFromSelector(sel) componentsSeparatedByString:@":"].count - 1) == paramCount);
    if (!succeed)
    {
        assert(0);
    }
    return succeed;
}
