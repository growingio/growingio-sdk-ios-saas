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
#import "FoAspect.h"
#import "FoObjectSELObserver.h"
#import "metamacros.h"

#import "GrowingInstance.h"

#define _GrowingAspectForeachParam(paramMacro,...)                                                                                   \
        metamacro_if_eq(2,metamacro_argcount(__VA_ARGS__))                                                                      \
        ()                                                                                                                      \
        (metamacro_foreach(paramMacro,, metamacro_tail(metamacro_take(metamacro_dec(metamacro_argcount(__VA_ARGS__)), __VA_ARGS__ ))))                                                           \

#define _GrowingAspectGetCode(...)           \
        metamacro_drop(metamacro_dec( metamacro_argcount(__VA_ARGS__)),__VA_ARGS__)

#define _GrowingAspectOldMACRO(TYPE)        \
        , TYPE

#define _GrowingAspectOld(INDEX,VALUE)      \
        _GrowingAspectOldMACRO VALUE        \

#define _GrowingAspectRunOldMACRO(TYPE)     \
        ,

#define _GrowingAspectRunOld(INDEX,VALUE)    \
            _GrowingAspectRunOldMACRO VALUE  \

#define _GrowingAspectNEWMACRO(TYPE)        \
        ,(TYPE)

#define _GrowingAspectNEW(INDEX,VALUE)      \
        _GrowingAspectNEWMACRO VALUE

#define _GrowingAspectRETURN(TYPE)          \
        foAspectIsVoidType(TYPE)            \
        ()                                  \
        (, TYPE originReturnValue)

#define _GrowingAspectRETURNPOINT(TYPE)     \
        foAspectIsVoidType(TYPE)            \
        ()                                  \
        (, TYPE* p_originReturnValue)

#define _GrowingAspectCallRETURN(TYPE)      \
        foAspectIsVoidType(TYPE)            \
        ()                                  \
        (, originReturnValue)

#define _GrowingAspectCallRETURNPOINT(TYPE) \
        foAspectIsVoidType(TYPE)            \
        ()                                  \
        (, &originReturnValue)


#define _GrowingAspectRETURN_BLOCK(INDEX,VALUE)     \
        foAspectIsVoidType(TYPE)                    \
        ()                                          \
        (__unused TYPE * p_originReturnValue = &originReturnValue;)

#define _GrowingAspectRETURN_RETURN(TYPE)       \
        foAspectIsVoidType(TYPE)                \
        ()                                      \
        (return  originReturnValue;)


#define _GrowingAspect(OPTION,MACRO,OBJECT,TEMPLATE,RETURNTYPE,...)                                                     \
        ^id{                                                                                                            \
            [GrowingInstance setFreezeAspectMode];                                                                      \
            if ([GrowingInstance aspectMode] == GrowingAspectModeSubClass)                                              \
            {                                                                                                           \
                return                                                                                                  \
                [OBJECT addFoObserverSelector:metamacro_head(__VA_ARGS__)                                               \
                                     template:TEMPLATE                                                                  \
                                         type:OPTION                                                                    \
                                callbackBlock:^RETURNTYPE(id originInstance ,                                           \
                                                          SEL theCmd                                                    \
                                                          _GrowingAspectForeachParam(_GrowingAspectOld , __VA_ARGS__)   \
                                                          _GrowingAspectRETURN(RETURNTYPE)                              \
                                                          , BOOL * p_shouldEarlyReturn)  {                              \
                        ^void(id originInstance ,                                                                       \
                              SEL theCmd                                                                                \
                              _GrowingAspectForeachParam(_GrowingAspectOld , __VA_ARGS__)                               \
                              _GrowingAspectRETURN(RETURNTYPE)                                                          \
                              _GrowingAspectRETURNPOINT(RETURNTYPE)                                                     \
                              , BOOL * p_shouldEarlyReturn)                                                             \
                                                                                                                        \
                        _GrowingAspectGetCode(__VA_ARGS__)                                                              \
                        (originInstance,                                                                                \
                         theCmd                                                                                         \
                         _GrowingAspectForeachParam(_GrowingAspectRunOld ,__VA_ARGS__ )                                 \
                         _GrowingAspectCallRETURN(RETURNTYPE)                                                           \
                         _GrowingAspectCallRETURNPOINT(RETURNTYPE)                                                      \
                         , p_shouldEarlyReturn                                                                          \
                        );                                                                                              \
                        _GrowingAspectRETURN_RETURN(RETURNTYPE)                                                         \
                    }                                                                                                   \
                ];                                                                                                      \
            }                                                                                                           \
            else                                                                                                        \
            {                                                                                                           \
                return                                                                                                  \
                [OBJECT  MACRO (RETURNTYPE ,                                                                            \
                                metamacro_head(__VA_ARGS__)                                                             \
                                _GrowingAspectForeachParam(_GrowingAspectNEW , __VA_ARGS__))  _GrowingAspectGetCode(__VA_ARGS__)];\
            }                                                                                                           \
        }()


#define GrowingAspectAfter(OBJECT,TEMPLATE,RETURNTYPE,...)                                                              \
        _GrowingAspect(FoObjectSELObserverOptionAfter | FoObjectSELObserverOptionAddMethod,foAspectAfterSeletor,        \
                        OBJECT,TEMPLATE,RETURNTYPE,__VA_ARGS__)

#define GrowingAspectBefore(OBJECT,TEMPLATE,RETURNTYPE,...)                                                             \
        _GrowingAspect(FoObjectSELObserverOptionBefore | FoObjectSELObserverOptionAddMethod,foAspectBeforeSeletor,      \
                        OBJECT,TEMPLATE,RETURNTYPE,__VA_ARGS__)

#define GrowingAspectAfterNoAdd(OBJECT,TEMPLATE,RETURNTYPE,...)                                                         \
        _GrowingAspect(FoObjectSELObserverOptionAfter ,foAspectAfterSeletorNoAddMethod,                                            \
                        OBJECT,TEMPLATE,RETURNTYPE,__VA_ARGS__)

#define GrowingAspectBeforeNoAdd(OBJECT,TEMPLATE,RETURNTYPE,...)                                                        \
        _GrowingAspect(FoObjectSELObserverOptionBefore ,foAspectBeforeSeletorNoAddMethod,                                          \
                        OBJECT,TEMPLATE,RETURNTYPE,__VA_ARGS__)
