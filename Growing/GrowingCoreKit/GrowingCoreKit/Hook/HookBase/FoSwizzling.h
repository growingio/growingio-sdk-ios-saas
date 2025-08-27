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




    #define fo_check_hook_function(theSEL,COUNT)



#define FoHookOrgin(...)                                                                                    \
            __fo_hook_function                                                                            \
            ?__fo_hook_function(self,_cmd,##__VA_ARGS__)                                                  \
            :((typeof(__fo_hook_function))(class_getMethodImplementation(__foHookSuperClass,__foHookSel)))(self,_cmd,##__VA_ARGS__)                                                                        \


#define FoHookSuper(...)                                                                                    \
            ((typeof(__fo_hook_function))(class_getMethodImplementation(__foHookSuperClass,__foHookSel)))(self,_cmd,##__VA_ARGS__)                                                                         \



#define __FoHookInstance(theCFunctionName,                                                                      \
                         theSelfType,                                                                           \
                         theClass,                                                                              \
                         theSuperClass,                                                                         \
                         theSEL,                                                                                \
                         theSectionName,                                                                        \
                         theRetType,...)                                                                        \
    static theRetType (metamacro_concat_(*old , theCFunctionName))(theSelfType self,SEL _cmd,##__VA_ARGS__);    \
    static theRetType metamacro_concat_(new ,theCFunctionName)    (theSelfType self,SEL _cmd,##__VA_ARGS__);    \
    @interface NSNull(metamacro_concat_(fosetup__ ,theCFunctionName)) @end                                      \
    @implementation NSNull(metamacro_concat_(fosetup__ ,theCFunctionName))                                      \
    + (void)load                                                                                                \
    {                                                                                                           \
        fo_check_hook_function(theSEL, metamacro_argcount(1,##__VA_ARGS__) -1);                                 \
        metamacro_concat_(old , theCFunctionName) = fo_imp_hook_function(theClass,                              \
                                                     theSEL,                                                    \
                                                     metamacro_concat_(new ,theCFunctionName));                 \
    }                                                                                                           \
    @end                                                                                                        \
    static theRetType metamacro_concat_(new ,theCFunctionName) (theSelfType self,SEL _cmd,##__VA_ARGS__)        \
    {                                                                                                           \
        __unused Class __foHookSuperClass = theSuperClass;                                                      \
        __unused SEL   __foHookSel  = theSEL;                                                                   \
        __unused theRetType (*__fo_hook_function)(theSelfType self,SEL _cmd,##__VA_ARGS__)                      \
                    = metamacro_concat_(old , theCFunctionName);


#define FoHookInstance(theClass,theSEL,theRetType,...)                                                          \
        __FoHookInstance(metamacro_concat(__fo_function , __COUNTER__) ,                                        \
                         theClass*,                                                                             \
                         objc_getClass(#theClass),                                                              \
                         class_getSuperclass(objc_getClass(#theClass)),                                         \
                         theSEL,                                                                                \
                         __foHookInit,                                                                          \
                         theRetType,                                                                            \
                         ##__VA_ARGS__)                                                                         \

#define FoHookInstanceWithName(functionName,theClass,theSEL,theRetType,...)                                     \
        __FoHookInstance(functionName,                                                                          \
                         theClass*,                                                                             \
                         objc_getClass(#theClass),                                                              \
                         class_getSuperclass(objc_getClass(#theClass)),                                         \
                         theSEL,                                                                                \
                         __foHookInit,                                                                          \
                         theRetType,                                                                            \
                         ##__VA_ARGS__)                                                                         \


#define FoHookInstancePlus(theClassName,selfType,theSEL,theRetType,...)                                         \
        __FoHookInstance(metamacro_concat(__fo_function , __COUNTER__) ,                                        \
                        selfType,                                                                               \
                        objc_getClass(theClassName),                                                            \
                        class_getSuperclass(objc_getClass(theClassName)),                                       \
                        theSEL,                                                                                 \
                        __foHookInit,                                                                           \
                        theRetType,                                                                             \
                        ##__VA_ARGS__)                                                                          \


#define FoHookClass(theClass,theSEL,theRetType,...)                                                             \
        __FoHookInstance(metamacro_concat(__fo_function , __COUNTER__),                                         \
                         Class ,                                                                                \
                         object_getClass(objc_getClass(#theClass)),                                             \
                         object_getClass(class_getSuperclass(objc_getClass(#theClass))),                         \
                         theSEL,                                                                                \
                         __foHookInit,                                                                          \
                         theRetType,                                                                            \
                         ##__VA_ARGS__)                                                                         \


#define FoHookEnd }

void* fo_imp_hook_function(Class clazz,
                    SEL   sel,
                    void  *newFunction);

BOOL _fo_check_hook_function(SEL sel,NSInteger paramCount);
