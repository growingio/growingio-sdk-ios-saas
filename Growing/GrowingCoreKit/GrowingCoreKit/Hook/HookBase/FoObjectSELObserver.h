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
#import "FoObjectSELObserverMacro.h"

@protocol FoObjectSELObserverItem <NSObject>
- (void)remove;
@end


typedef NS_ENUM(NSUInteger, FoObjectSELObserverOption)
{
    FoObjectSELObserverOptionAfter      = 1,
    FoObjectSELObserverOptionBefore     = 2,
    FoObjectSELObserverOptionAddMethod  = 4,
};

#define CLASS_NAME NSObject
#include "FoAspectBody.h"
#undef CLASS_NAME

#define CLASS_NAME NSProxy
#include "FoAspectBody.h"
#undef CLASS_NAME

@interface NSProxy(FoAspectMimicKVOSubclass)

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context;

@end
