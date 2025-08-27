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
#import "metamacros.h"

@protocol FoAspectToken;

@interface NSObject(foAspectPrivate)
- (id<FoAspectToken>)_foAspectSelector:(SEL)sel
                          canAddMethod:(BOOL)addMethod
                         isBeforeBlock:(BOOL)isBeforeBlock
                 templateCreateorBlock:(id(^)(Class classObject,
                                              Class superClassObject,
                                              SEL sel,
                                              SEL classSEL,
                                              SEL instanceSEL,
                                              IMP oldIMP,
                                              NSString **outTypeEncoding))templateCreatorBlock
                             userBlock:(id)userBlock;
@end


@interface foAspectItem : NSObject
{
@public
    NSMapTable<NSString*,id> *beforeBlock ;
    NSMapTable<NSString*,id> *afterBlock  ;
}

@end


BOOL foCheckTemplateCanRunBlock(Class templateClass, id object, SEL classHookedFlag);

#define foAspecttype_void  ,
#define _foAspectIsVoidType(...) metamacro_if_eq(metamacro_argcount(__VA_ARGS__),2)
#define foAspectIsVoidType(TYPE) _foAspectIsVoidType(foAspecttype_ ## TYPE )


#define addBlockWithUUIDMethod1 addBeforeBlockWithUUID
#define addBlockWithUUIDMethod0 addAfterBlockWithUUID



#define foAspect_blockParamTypeEncodePlaceHolder(INDEX,VALUE)                                                                   \
        @"%s"

#define foAspect_blockParamTypeEncodeGetTypeParam(TYPE)                                                                         \
        TYPE ,

#define foAspect_blockParamTypeEncodeGetType(...)                                                                               \
        ,@encode(metamacro_head(__VA_ARGS__))

#define foAspect_blockParamTypeEncodeVar(INDEX,VALUE)                                                                           \
        foAspect_blockParamTypeEncodeGetType(foAspect_blockParamTypeEncodeGetTypeParam VALUE)


#define foAspect_initReturnValue(TYPE)                                                                                          \
        foAspectIsVoidType(TYPE)                                                                                                \
        ()                                                                                                                      \
        (TYPE originReturnValue; memset(&originReturnValue, 0, sizeof(TYPE));)                                                  \

#define foAspect_setReturnValue(TYPE)                                                                                           \
        foAspectIsVoidType(TYPE)                                                                                                \
        ()                                                                                                                      \
        (originReturnValue = )                                                                                                  \

#define foAspect_returnReturnValue(TYPE)                                                                                        \
        foAspectIsVoidType(TYPE)                                                                                                \
        (return ;)                                                                                                              \
        (return originReturnValue;)                                                                                             \


#define foAspect_foreachParam(paramMacro,...)                                                                                   \
        metamacro_if_eq(1,metamacro_argcount(__VA_ARGS__))                                                                      \
        ()                                                                                                                      \
        (metamacro_foreach(paramMacro,, metamacro_tail(__VA_ARGS__)))                                                           \


#define foAspect_templateParamDefineMacro_(TYPE) TYPE                                                                           \

#define foAspect_templateParamDefineMacro(INDEX,VALUE)                                                                          \
        , foAspect_templateParamDefineMacro_ VALUE                                                                              \


#define foAspect_templateParamCallMacro_(TYPE)                                                                                  \

#define foAspect_templateParamCallMacro(INDEX,VALUE)                                                                            \
        , foAspect_templateParamCallMacro_ VALUE                                                                                \



#define foAspect_returnTypeDefineInParams1(TYPE)                                                                                \
        foAspectIsVoidType(TYPE)                                                                                                \
        (, BOOL * p_shouldEarlyReturn)                                                                                          \
        (, BOOL * p_shouldEarlyReturn, TYPE *p_originReturnValue, TYPE originReturnValue)                                       \


#define foAspect_returnTypeDefineInParams0(TYPE)                                                                                \
        foAspectIsVoidType(TYPE)                                                                                                \
        ()                                                                                                                      \
        (,TYPE *p_originReturnValue , TYPE originReturnValue)                                                                   \



#define foAspect_returnTypeCallParams1(TYPE)                                                                                    \
        foAspectIsVoidType(TYPE)                                                                                                \
        (,&shouldEarlyReturn)                                                                                                   \
        (,&shouldEarlyReturn,&originReturnValue,originReturnValue)                                                              \



#define foAspect_returnTypeCallParams0(TYPE)                                                                                    \
        foAspectIsVoidType(TYPE)                                                                                                \
        ()                                                                                                                      \
        (,&originReturnValue,originReturnValue)                                                                                 \


#define foAspect_blockParamDefinePointVarMacro_(...)                                                                            \
        metamacro_head(__VA_ARGS__)                                                                                             \
        metamacro_concat(metamacro_head(metamacro_tail(__VA_ARGS__)),                                                           \
                         metamacro_head(metamacro_tail(metamacro_tail(__VA_ARGS__)))   )

#define foAspect_blockParamDefinePointTypeMacro_(TYPE)                                                                          \
        TYPE *,p_,

#define foAspect_blockParamDefineVarMacro_(TYPE)                                                                                \
        TYPE

#define foAspect_blockParamDefineMacro1(INDEX,VALUE)                                                                            \
        , foAspect_blockParamDefinePointVarMacro_(foAspect_blockParamDefinePointTypeMacro_ VALUE)                               \
        , foAspect_blockParamDefineVarMacro_ VALUE                                                                              \

#define foAspect_blockParamDefineMacro0(INDEX,VALUE)                                                                            \
        , foAspect_blockParamDefineVarMacro_ VALUE                                                                              \


#define foAspect_blockParamCallPointMacro_(TYPE)                                                                                \
        , &

#define foAspect_blockParamCallVarMacro_(TYPE)                                                                                  \
        ,

#define foAspect_blockParamCallMacro1(INDEX,VALUE)                                                                              \
        foAspect_blockParamCallPointMacro_  VALUE foAspect_blockParamCallVarMacro_ VALUE

#define foAspect_blockParamCallMacro0(INDEX,VALUE)                                                                              \
        foAspect_blockParamCallVarMacro_ VALUE



#define _foAspectWithSeletor(ADDMETHOD,ISBEFOREBLOCK,RETURNTYPE, ...)                                                           \
                                                                                          \
    _foAspectSelector : metamacro_head(__VA_ARGS__)                                                                             \
         canAddMethod : ADDMETHOD != 0                                                                                          \
        isBeforeBlock : ISBEFOREBLOCK != 0                                                                                      \
templateCreateorBlock : ^id(Class classObject ,                                                                                 \
                            Class superClassObject,                                                                             \
                            SEL sel,                                                                                            \
                            SEL classSEL ,                                                                                      \
                            SEL instanceSEL,                                                                                    \
                            IMP oldIMP,                                                                                         \
                            NSString **outTypeEncoding)                                                                         \
    {                                                                                                                           \
        if (outTypeEncoding)                                                                                                    \
        {                                                                                                                       \
            *outTypeEncoding =                                                                                                  \
            [[NSString alloc] initWithFormat:@"%s"@"%s"@"%s"                                                                    \
                                              foAspect_foreachParam(foAspect_blockParamTypeEncodePlaceHolder,__VA_ARGS__)       \
                                             ,@encode(RETURNTYPE)                                              \
                                             ,@encode(id)                                                             \
                                             ,@encode(SEL)                                                            \
                                              foAspect_foreachParam(foAspect_blockParamTypeEncodeVar , __VA_ARGS__) ];          \
        }                                                                                                                       \
                                                                                                     \
        return ^RETURNTYPE (__unsafe_unretained id originInstance  foAspect_foreachParam(foAspect_templateParamDefineMacro,__VA_ARGS__))    \
        {                                                                                                                       \
            BOOL canRunBlock = foCheckTemplateCanRunBlock(classObject,                                                          \
                                                          originInstance,                                                       \
                                                          classSEL);                                                            \
            foAspectItem *item = nil;                                                                                           \
            if (canRunBlock)                                                                                                    \
            {                                                                                                                   \
                @autoreleasepool {                                                                                              \
                    item = objc_getAssociatedObject(originInstance, instanceSEL);                                               \
                }                                                                                                               \
            }                                                                                                                   \
                                                                                                                                \
            BOOL shouldEarlyReturn = NO;                                                                                        \
            foAspect_initReturnValue(RETURNTYPE)                                                                                \
                                                                                                                                \
                                                                                                        \
            typedef void (^beforeBlockType)(id originInstance                                                                   \
                                            foAspect_returnTypeDefineInParams1 (RETURNTYPE)                                     \
                                            foAspect_foreachParam (foAspect_blockParamDefineMacro1  , __VA_ARGS__));            \
            if (item && item->beforeBlock)                                                                                      \
            {                                                                                                                   \
                for (beforeBlockType block in item->beforeBlock.objectEnumerator)                                               \
                {                                                                                                               \
                    block(originInstance                                                                                        \
                          foAspect_returnTypeCallParams1(RETURNTYPE)                                                            \
                          foAspect_foreachParam(foAspect_blockParamCallMacro1,__VA_ARGS__));                                    \
                    if (shouldEarlyReturn)                                                                                      \
                    {                                                                                                           \
                        foAspect_returnReturnValue(RETURNTYPE)                                                                  \
                    }                                                                                                           \
                }                                                                                                               \
            }                                                                                                                   \
                                                                                                                                \
                                                                                                            \
            RETURNTYPE(*calledIMP)(id,SEL foAspect_foreachParam(foAspect_templateParamDefineMacro,__VA_ARGS__)) = nil;          \
                                                                                                                                \
                                                                                                 \
            if (oldIMP)                                                                                                         \
            {                                                                                                                   \
                calledIMP = (void*)oldIMP;                                                                                      \
            }                                                                                                                   \
                                                                                                                                \
                                                                \
            else if (class_respondsToSelector(superClassObject, sel))                                                           \
            {                                                                                                                   \
                calledIMP = (void*)class_getMethodImplementation(superClassObject, sel);                                        \
            }                                                                                                 \
                                                                                                                 \
            if (calledIMP)                                                                                                      \
            {                                                                                                                   \
                foAspect_setReturnValue(RETURNTYPE)                                                                             \
                calledIMP(originInstance,                                                                                       \
                          sel                                                                                                   \
                          foAspect_foreachParam (foAspect_templateParamCallMacro ,__VA_ARGS__));                                \
            }                                                                                                                   \
                                                                                                         \
            typedef void (^afterBlockType)(id originInstance                                                                    \
                                           foAspect_returnTypeDefineInParams0 (RETURNTYPE)                                      \
                                           foAspect_foreachParam (foAspect_blockParamDefineMacro0  , __VA_ARGS__));             \
            if (item && item->afterBlock)                                                                                       \
            {                                                                                                                   \
                for (afterBlockType block in item->afterBlock.objectEnumerator)                                                 \
                {                                                                                                               \
                    block(originInstance                                                                                        \
                          foAspect_returnTypeCallParams0(RETURNTYPE)                                                            \
                          foAspect_foreachParam(foAspect_blockParamCallMacro0,__VA_ARGS__));                                    \
                }                                                                                                               \
            }                                                                                                                   \
            foAspect_returnReturnValue(RETURNTYPE)                                                                              \
        };                                                                                                                      \
    }                                                                                                                           \
            userBlock : ^void(__unsafe_unretained id originInstance                                                             \
                              foAspect_returnTypeDefineInParams ## ISBEFOREBLOCK (RETURNTYPE)                                   \
                              foAspect_foreachParam (foAspect_blockParamDefineMacro ## ISBEFOREBLOCK  , __VA_ARGS__))

#define foAspectAfterSeletorNoAddMethod(RETURNTYPE, ...)  _foAspectWithSeletor(0 , 0 , RETURNTYPE ,  __VA_ARGS__ )
#define foAspectAfterSeletor(RETURNTYPE, ...)             _foAspectWithSeletor(1 , 0 , RETURNTYPE ,  __VA_ARGS__ )
#define foAspectBeforeSeletorNoAddMethod(RETURNTYPE, ...) _foAspectWithSeletor(0 , 1 , RETURNTYPE ,  __VA_ARGS__ )
#define foAspectBeforeSeletor(RETURNTYPE, ...)            _foAspectWithSeletor(1 , 1 , RETURNTYPE ,  __VA_ARGS__ )
