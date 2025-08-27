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

#ifndef Growing_FoDefineProperty_h
#define Growing_FoDefineProperty_h

#define FoPropertyDefine(theClass,theType,theGetter,theSetter)                              \
        @interface theClass(FoDefineProperty_##theGetter)                                   \
        @property (nonatomic, retain) theType theGetter;                                    \
        @end                                                                                \
        @implementation theClass(FoDefineProperty_##theGetter)                              \
             FoPropertyImplementation(theType,theGetter,theSetter)                          \
        @end                                                                                \

#define FoPropertyImplementation(theType,theGetter,theSetter)                               \
        static char __##theClass##__##theGetter##_key;                                      \
        - (void)theSetter:(theType)value                                                    \
        {                                                                                   \
            objc_setAssociatedObject(self,                                                  \
                                     &__##theClass##__##theGetter##_key,                    \
                                     value,                                                 \
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);                    \
        }                                                                                   \
        - (theType)theGetter                                                                \
        {                                                                                   \
            return objc_getAssociatedObject(self,&__##theClass##__##theGetter##_key);       \
        }                                                                                   \


#define FoSafeStringPropertyImplementation(theGetter,theSetter)                             \
        static char __##theClass##__##theGetter##_key;                                      \
        - (void)theSetter:(NSString *)value                                                 \
        {                                                                                   \
            if ([value isKindOfClass:[NSNumber class]])                                     \
            {                                                                               \
                value = [(NSNumber *)value stringValue];                                    \
            }                                                                               \
            if (![value isKindOfClass:[NSString class]])                                    \
            {                                                                               \
                value = nil;                                                                \
            }                                                                               \
            objc_setAssociatedObject(self,                                                  \
                                     &__##theClass##__##theGetter##_key,                    \
                                     value,                                                 \
                                     OBJC_ASSOCIATION_COPY_NONATOMIC);                      \
        }                                                                                   \
        - (NSString *)theGetter                                                             \
        {                                                                                   \
            return objc_getAssociatedObject(self,&__##theClass##__##theGetter##_key);       \
        }                                                                                   \



#endif
