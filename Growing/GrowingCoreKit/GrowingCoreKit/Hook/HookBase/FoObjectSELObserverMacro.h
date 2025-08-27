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


#ifndef d_FoObjectSELObserverMacro_h
#define d_FoObjectSELObserverMacro_h

#import <objc/runtime.h>
#import "metamacros.h"


#define functionDefine(index,varType)   \
            ,varType param##index

#define functionCall(index,varType)     \
            ,param##index

#define functionCallforeachParam(paramMacro,...) \
        metamacro_if_eq(1,metamacro_argcount(__VA_ARGS__))()(metamacro_foreach(paramMacro,, metamacro_tail(__VA_ARGS__)))

#define functionDefineforeach(...)      \
        functionCallforeachParam(functionDefine,__VA_ARGS__)

#define functionCallforeach(...)      \
        functionCallforeachParam(functionCall,__VA_ARGS__)

#define functionHookCallInArr(ARRAY,RETURNVARSET,RETURNCALL,EARLYRETURNMACRO,EARLYRETURNCODE, ...)                  \
        for (FoObjectSELObserverItem *item in ARRAY )                                                               \
        {                                                                                                           \
            if (item.block)                                                                                         \
            {                                                                                                       \
                RETURNVARSET ((typeof(tempBlock))item.block)(self,tempSel functionCallforeach(__VA_ARGS__) RETURNCALL EARLYRETURNMACRO(NOTUSED)); \
                if (shouldEarlyReturn)                                                                              \
                {                                                                                                   \
                    EARLYRETURNCODE;                                                                                \
                }                                                                                                   \
            }                                                                                                       \
        }                                                                                                           \


#define _FoSwizzleVoidParama(ReturnType)
#define _FoSwizzleReturnParama(ReturnType) ,retVal

#define _FoSwizzleVoidVarDefine(ReturnType,RETURNVarDefine)
#define _FoSwizzleReturnVarDefine(ReturnType,RETURNVarDefine) ReturnType retVal = (ReturnType)0;
#define _FoSwizzleStructVarDefine(ReturnType,RETURNVarDefine) ReturnType retVal = RETURNVarDefine;

#define _FoSwizzleVoidFunctionDefine(ReturnType)
#define _FoSwizzleReturnFunctionDefine(ReturnType) ,ReturnType

#define _FoSwizzleVoidSet(ReturnType)
#define _FoSwizzleReturnSet(ReturnType) retVal =

#define _FoSwizzleVoidReturn(ReturnType) return
#define _FoSwizzleReturnReturn(ReturnType) return retVal

#define _FoSwizzleNormalImp class_getMethodImplementation

#if defined(__arm64__)
#define _FoSwizzleStructImp class_getMethodImplementation
#else
#define _FoSwizzleStructImp class_getMethodImplementation_stret
#endif


#define _FoSwizzleEarlyReturnParamBeforeBlock(NOTUSED) ,&shouldEarlyReturn

#define _FoSwizzleEarlyReturnParamAfterBlock(NOTUSED) ,nil

#define __FoSwizzleTemplet(SELECTOR,                                                                                            \
                           getIMPFunction,                                                                                      \
                           ReturnType,ReturnDefaultValue,                                                                       \
                           oldReturnParam , RETURNVarDefine,                                                                    \
                           RETURNFunctionDefine , RETURNSET ,RETURNRETURN,  ...)                                                \
        static ReturnType metamacro_concat(__,metamacro_head(__VA_ARGS__)) (id self,SEL _cmd functionDefineforeach(__VA_ARGS__)  )     \
        {                                                                                                                       \
            BOOL shouldEarlyReturn = NO;                                                                                        \
            SEL tempSel = SELECTOR;                                                                                             \
            ReturnType (^tempBlock)(id,SEL functionDefineforeach(__VA_ARGS__) RETURNFunctionDefine(ReturnType), BOOL*) = nil;   \
            RETURNVarDefine(ReturnType,ReturnDefaultValue)                                                                      \
                                                                                                                      \
            functionHookCallInArr([self __fo_beforeBlocks:tempSel],                                                             \
                                  RETURNSET(ReturnType),                                                                        \
                                  oldReturnParam(ReturnType),                                                                   \
                                  _FoSwizzleEarlyReturnParamBeforeBlock,                                                        \
                                  RETURNRETURN(ReturnType),                                                                     \
                                  __VA_ARGS__)                                                                                  \
                                                                                                                        \
            Class superClass = class_getSuperclass(object_getClass(self));                                                      \
            ReturnType (*tempImp)(id,SEL functionDefineforeach(__VA_ARGS__)) = nil;                                             \
            Method method = class_getInstanceMethod(superClass, tempSel);                                                       \
            if (method)                                                                                                         \
            {                                                                                                                   \
                tempImp = (void*)method_getImplementation(method);                                                              \
            }                                                                                                                   \
            else                                                                                                                \
            {                                                                                                                   \
                                                                             \
                BOOL isRespondsToSelector = [self restoreOriginResultOfRespondsToSelector:tempSel];                             \
                                \
                if (isRespondsToSelector)                                                                                       \
                {                                                                                                               \
                    tempImp = (void*)getIMPFunction(superClass, tempSel);                                                       \
                }                                                                                                               \
            }                                                                                                                   \
                                                                                                                                \
            if (tempImp)                                                                                                        \
            {                                                                                                                   \
                RETURNSET(ReturnType) tempImp(self,tempSel  functionCallforeach(__VA_ARGS__)  );                                \
            }                                                                                                                   \
                                                                                                                       \
            functionHookCallInArr([self __fo_afterBlocks:tempSel],                                                              \
                                  RETURNSET(ReturnType),                                                                        \
                                  oldReturnParam(ReturnType),                                                                   \
                                  _FoSwizzleEarlyReturnParamAfterBlock,                                                         \
                                  ,                                                                 \
                                  __VA_ARGS__)                                                                                  \
            RETURNRETURN(ReturnType);                                                                                           \
        }                                                                                                                       \
        static void * metamacro_head(__VA_ARGS__) = metamacro_concat(__,metamacro_head(__VA_ARGS__));                           \


#define FoSwizzleTempletVoid(SELECTOR,ReturnType, ...)  \
        __FoSwizzleTemplet(SELECTOR,class_getMethodImplementation, ReturnType , ,  _FoSwizzleVoidParama , _FoSwizzleVoidVarDefine ,  _FoSwizzleVoidFunctionDefine , _FoSwizzleVoidSet ,_FoSwizzleVoidReturn , __VA_ARGS__)

#define FoSwizzleTemplet(SELECTOR,ReturnType, ...)  \
        __FoSwizzleTemplet(SELECTOR,class_getMethodImplementation, ReturnType , ,  _FoSwizzleReturnParama , _FoSwizzleReturnVarDefine ,  _FoSwizzleReturnFunctionDefine , _FoSwizzleReturnSet ,_FoSwizzleReturnReturn , __VA_ARGS__)

#define FoSwizzleTempletStruct(SELECTOR,ReturnType,ReturnDefaultValue, ...)  \
        __FoSwizzleTemplet(SELECTOR,_FoSwizzleStructImp ,ReturnType ,ReturnDefaultValue,  _FoSwizzleReturnParama , _FoSwizzleStructVarDefine ,  _FoSwizzleReturnFunctionDefine , _FoSwizzleReturnSet ,_FoSwizzleReturnReturn , __VA_ARGS__)


#endif

@interface FoObjectSELObserverItem : NSObject
@property (nonatomic, strong) id  block;
@end

#define CLASS_NAME NSObject
#include "FoAspectMacro.h"
#undef CLASS_NAME

#define CLASS_NAME NSProxy
#include "FoAspectMacro.h"
#undef CLASS_NAME
