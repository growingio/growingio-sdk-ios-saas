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
#import <objc/runtime.h>
#import "metamacros.h"


#if DEBUG

    #define GrowingCategoryCheckName(originClass,classNameString) \
               if(![@#originClass isEqualToString:classNameString])\
               {\
                    NSLog(@"%@与%@不匹配",@#originClass,classNameString);\
                    assert(0);\
               }

#else

    #define GrowingCategoryCheckName(originClass,classNameString)

#endif



#define GrowingCategoryBindCheckName(index,var) \
            GrowingCategoryCheckName  var




#define GrowingCategoryCreateClassArrayItem(originName,fakeName)    \
            {                                                       \
                Class clazz = NSClassFromString(fakeName);          \
                if (clazz)                                          \
                {                                                   \
                    [classes addObject:clazz];                      \
                }                                                   \
            }                                                       \


#define GrowingCategoryCreateClassArray(index,var) \
            GrowingCategoryCreateClassArrayItem var


#define GrowingCategory(CategoryName , ...)                                         \
            CategoryName : NSObject                                                 \
            @end                                                                    \
            @implementation CategoryName                                            \
            + (void)load                                                            \
            {                                                                       \
                metamacro_foreach(GrowingCategoryBindCheckName, ,__VA_ARGS__ )      \
                unsigned int count = 0;                                             \
                Method *methods = class_copyMethodList(self, &count);               \
                NSMutableArray *classes = [[NSMutableArray alloc] init];            \
                metamacro_foreach(GrowingCategoryCreateClassArray , , __VA_ARGS__)  \
                for (unsigned int i = 0 ; i < count ; i++)                          \
                {                                                                   \
                    Method method = methods[i];                                     \
                    for (Class clazz in classes)                                    \
                    {                                                               \
                        class_addMethod(clazz,                                      \
                                        method_getName(method),                     \
                                        method_getImplementation(method),           \
                                        method_getTypeEncoding(method));            \
                    }                                                               \
                }                                                                   \
                free(methods);                                                      \
            }                                                                       \
