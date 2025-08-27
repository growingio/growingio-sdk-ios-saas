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


#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

#import "FoObjectSELObserver.h"
#import "FoObjectSELObserverMacro.h"
#import "FoSwizzling.h"
#import "GrowingInstance.h"
#import "GrowingMediator.h"
#import <pthread.h>
#import "GrowingCocoaLumberjack.h"

@interface FoObjectSELObserverItem()<FoObjectSELObserverItem>

@property (nonatomic, assign) id  obj;
@property (nonatomic, assign) SEL sel;
@property (nonatomic, copy)   NSString *kvoKeyPath;
@property (nullable)          void *objObservationInfo;
@property (nonatomic, assign) Class aClass;

- (instancetype)initWithObj:(id)obj
                        sel:(SEL)sel
                   template:(void*)templateImp
                       type:(FoObjectSELObserverOption)type
              callbackBlock:(id)block;
@end

@interface FoObjectSELObserverItemShell : NSObject<FoObjectSELObserverItem>
{
@public
    __weak id<FoObjectSELObserverItem> trueObj;
}
@end

@implementation FoObjectSELObserverItemShell

- (void)remove
{
    [trueObj remove];
}

@end

@interface FoObjectSELObserverManager : NSObject

@property (nonatomic, assign) id obj;
@property (nonatomic, readonly) NSMutableDictionary *beforeDict;
@property (nonatomic, readonly) NSMutableDictionary *afterDict;
@property (nonatomic, assign) BOOL addRespondsToSelectorFlag;

- (void)remove;
- (void)addItem:(FoObjectSELObserverItem*)item
           type:(FoObjectSELObserverOption)type
            sel:(SEL)sel;
- (void)removeItem:(FoObjectSELObserverItem*)item
              type:(FoObjectSELObserverOption)type
               sel:(SEL)sel;
- (void)addRespondsToSelectorHook;
@end

@interface FoObjectSELObserverManagerRemover : NSObject
@property (nonatomic, retain) FoObjectSELObserverManager *manager;
@end

@implementation FoObjectSELObserverManagerRemover

- (void)dealloc
{
    [self.manager remove];
}

@end

#define CLASS_NAME NSObject
#include "FoAspectBody.m"
#undef CLASS_NAME

#define CLASS_NAME NSProxy
#include "FoAspectBody.m"
#undef CLASS_NAME

#define FoAspectMimicKVOSubclassPrefix @"GIOKVONotifying_"

static void FoAspectHookedGetClass(Class subclass, Class originClass)
{
    Method method = class_getInstanceMethod(subclass, @selector(class));
    IMP newIMP = imp_implementationWithBlock(^(id self) {
        return originClass;
    });
    class_replaceMethod(subclass, @selector(class), newIMP, method_getTypeEncoding(method));
}





@implementation NSProxy(FoAspectMimicKVOSubclass)

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    Class objectClass = object_getClass(self);
    
    NSString *className = [NSStringFromClass(objectClass) componentsSeparatedByString:FoAspectMimicKVOSubclassPrefix].lastObject;
    const char *subclassName = [FoAspectMimicKVOSubclassPrefix stringByAppendingString:className].UTF8String;
    Class subclass = objc_getClass(subclassName);
    if (subclass == nil) {
        subclass = objc_allocateClassPair(objectClass, subclassName, 0);
        FoAspectHookedGetClass(subclass, objectClass);
        FoAspectHookedGetClass(object_getClass(subclass), objectClass);
        objc_registerClassPair(subclass);
    }
    object_setClass(self, subclass);
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context
{
    
}

@end



@implementation FoObjectSELObserverItem


- (instancetype)initWithObj:(id)obj
                        sel:(SEL)sel
                   template:(void*)templateImp
                       type:(FoObjectSELObserverOption)type
              callbackBlock:(id)block
{
    if (!obj || !sel || !templateImp || !block)
    {
        return nil;
    }
    
    if (![obj respondsToSelector:sel] && !(type & FoObjectSELObserverOptionAddMethod))
    {
        return nil;
    }
    
    self = [super init];
    if (self)
    {
        self.obj = obj;
        self.sel = sel;
        self.block = block;
        self.kvoKeyPath = [NSString stringWithFormat:@"FoObjectSELObserver_%@",[NSProcessInfo processInfo].globallyUniqueString];
        
        
        [self.obj recordOriginResultOfRespondsToSelector:sel];
        
        [obj addObserver:self
               forKeyPath:self.kvoKeyPath
                  options:NSKeyValueObservingOptionNew
                  context:nil];
        if ([obj isKindOfClass:[NSObject class]]) {
            self.objObservationInfo = ((NSObject *)obj).observationInfo;
        }
        
        Class objectClass = object_getClass(obj);
        self.aClass = objectClass;

        Class superClass = class_getSuperclass(objectClass);
        
        
        
        if (superClass != [obj class])
        {
            
            if (class_getSuperclass(superClass) != [obj class] || ![NSStringFromClass(objectClass) hasSuffix:@"_RACSelectorSignal"]) {
                GIOLogWarn(@"GIO 客户工程使用runtime技术改写了class, 造成我们GrowingAspectModeSubClass失效,请寻找适配方法");
                [obj removeObserver:self forKeyPath:self.kvoKeyPath];
                self.objObservationInfo = nil;
                self.kvoKeyPath = nil;
                return nil;
            } else {
                GIOLogWarn(@"GIO 客户工程使用了RAC框架");
            }
        }
        
        Method oldMethod = class_getInstanceMethod(superClass , sel);

        class_addMethod(objectClass,
                        sel,
                        templateImp,
                        method_getTypeEncoding(oldMethod));
        
        [[obj __createFoObjectSELObserverManager] addItem:self type:type sel:sel];
        
        if (!oldMethod)
        {
            [[obj __FoObjectSELObserverManager] addRespondsToSelectorHook];
        }
    }
    return self;
}

static pthread_mutex_t kvoMutex;
pthread_mutex_t * getkvoMutexPointer()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_mutex_init(&kvoMutex, NULL);
    });
    return &kvoMutex;
}


- (void)remove
{
    pthread_mutex_t * pMutex = getkvoMutexPointer();
    pthread_mutex_lock(pMutex);
    
    if (self.block && self.obj && self.sel && self.kvoKeyPath)
    {
        [[self.obj __FoObjectSELObserverManager] removeItem:self type:FoObjectSELObserverOptionBefore sel:self.sel];
        [[self.obj __FoObjectSELObserverManager] removeItem:self type:FoObjectSELObserverOptionAfter sel:self.sel];
        
        BOOL isRemoveObserver = NO;
        
        
        
        
        if (![self.obj isProxy] &&
            ((NSObject *)self.obj).observationInfo == nil) {
            ((NSObject *)self.obj).observationInfo = self.objObservationInfo;
            [self objectRemoveKVO];
            isRemoveObserver = YES;
            ((NSObject *)self.obj).observationInfo = nil;
        }
        if (!isRemoveObserver) {
            [self objectRemoveKVO];
        }
    }
    self.kvoKeyPath = nil;
    self.obj = nil;
    self.sel = nil;
    self.block = nil;
    self.objObservationInfo = nil;
    self.aClass = nil;
    
    pthread_mutex_unlock(pMutex);
}

- (void)objectRemoveKVO
{
    
    
    @try {
            [self.obj removeObserver:self
                          forKeyPath:self.kvoKeyPath];
    } @catch (NSException *e) {
        Class aClass = object_getClass(self.obj);
        object_setClass(self.obj, self.aClass);
        @try {
            [self.obj removeObserver:self
                          forKeyPath:self.kvoKeyPath];
        } @catch (NSException *exception) {
            
        } @finally {
            
        }
        object_setClass(self.obj, aClass);
        
    } @finally {
    }
}

- (void)dealloc
{
    [self remove];
}

@end

@implementation FoObjectSELObserverManager

@synthesize beforeDict = _beforeDict;
@synthesize afterDict = _afterDict;

- (NSMutableDictionary*)beforeDict
{
    if (!_beforeDict)
    {
        _beforeDict = [[NSMutableDictionary alloc] init];
    }
    return _beforeDict;
}

- (NSMutableDictionary*)afterDict
{
    if (!_afterDict)
    {
        _afterDict = [[NSMutableDictionary alloc] init];
    }
    return _afterDict;
}

- (NSMutableArray*)arrForType:(FoObjectSELObserverOption)type sel:(SEL)sel
{
    NSMutableDictionary *dict = (type & FoObjectSELObserverOptionAfter) ? self.afterDict : self.beforeDict;
    NSString *key = NSStringFromSelector(sel);
    NSMutableArray *arr = [dict valueForKey:key];
    if (!arr)
    {
        arr = [[NSMutableArray alloc] init];
        [dict setValue:arr forKey:key];
    }
    return arr;
}

- (void)addItem:(FoObjectSELObserverItem*)item
           type:(FoObjectSELObserverOption)type
            sel:(SEL)sel
{
    [[self arrForType:type sel:sel] addObject:item];
}

- (void)removeItem:(FoObjectSELObserverItem*)item
              type:(FoObjectSELObserverOption)type
               sel:(SEL)sel
{
    [[self arrForType:type sel:sel] removeObject:item];
}

- (void)removeDictArr:(NSMutableDictionary*)dict
{
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableArray *arr, BOOL *stop) {
        [arr enumerateObjectsUsingBlock:^(FoObjectSELObserverItem *item, NSUInteger idx, BOOL *stop) {
            [item remove];
        }];
        [arr removeAllObjects];
    }];
    [dict removeAllObjects];
}

- (void)remove
{
    [self removeDictArr:self.beforeDict];
    [self removeDictArr:self.afterDict];
    self.obj = nil;
}

FoSwizzleTemplet(@selector(respondsToSelector:),
                 BOOL,selhoookrespondsToSelector,SEL);

- (void)addRespondsToSelectorHook
{
    if (!self.addRespondsToSelectorFlag)
    {
        self.addRespondsToSelectorFlag = YES;
        FoObjectSELObserverItemShell *itemShell = [self.obj addFoObserverSelector:@selector(respondsToSelector:)
                               template:selhoookrespondsToSelector
                                   type:FoObjectSELObserverOptionAfter
                          callbackBlock:^BOOL(NSObject *object, SEL selector , SEL pSel, BOOL oldReturn){
                              if (!oldReturn)
                              {
                                  if ([object __fo_afterBlocks:pSel].count || [[object __fo_beforeBlocks:pSel] count])
                                  {
                                      oldReturn = YES;
                                  }
                              }
                              return oldReturn;
                          }];
        if ([self.obj isKindOfClass:[UITableView class]]) {
            NSDictionary *params = nil;
            if (itemShell) {
                params = @{@"0":itemShell};
            }
            [[GrowingMediator sharedInstance] performTarget:self.obj action:@"setGrowingHook_RespondsToSelector:" params:params];
        }
    }
}

@end
