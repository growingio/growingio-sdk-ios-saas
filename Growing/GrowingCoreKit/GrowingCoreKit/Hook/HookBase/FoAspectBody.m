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
#import "GrowingAspect.h"



@implementation CLASS_NAME(FoObjectSELObserver)


static char __FoObjectSELObserverManagerKey;
- (FoObjectSELObserverManager*)__FoObjectSELObserverManager
{
    return objc_getAssociatedObject(self, &__FoObjectSELObserverManagerKey);
}

- (FoObjectSELObserverManager*)__createFoObjectSELObserverManager
{
    FoObjectSELObserverManager *manager = [self __FoObjectSELObserverManager];
    if (!manager)
    {
        manager = [[FoObjectSELObserverManager alloc] init] ;
        manager.obj = self;
        objc_setAssociatedObject(self, &__FoObjectSELObserverManagerKey, manager, OBJC_ASSOCIATION_RETAIN);
        FoObjectSELObserverManagerRemover *remover = [[FoObjectSELObserverManagerRemover alloc] init];
        remover.manager = manager;
        
        static char __FoObjectSELObserverManagerRemoverKey;
        objc_setAssociatedObject(self,
                                 &__FoObjectSELObserverManagerRemoverKey,
                                 remover,
                                 OBJC_ASSOCIATION_RETAIN);
    }
    return manager;
}


- (id<FoObjectSELObserverItem>)addFoObserverSelector:(SEL)sel
                                            template:(void*)templateImp
                                                type:(FoObjectSELObserverOption)type
                                       callbackBlock:(id)callbackBlock
{
    FoObjectSELObserverItem *item = [[FoObjectSELObserverItem alloc] initWithObj:self
                                                                             sel:sel
                                                                        template:templateImp
                                                                            type:type
                                                                   callbackBlock:callbackBlock];

    FoObjectSELObserverItemShell *shell = [[FoObjectSELObserverItemShell alloc] init];
    shell->trueObj = item;
    return shell;
}

@end

@implementation CLASS_NAME(FoObjectSELObserverMacro)

- (NSArray*)__fo_beforeBlocks:(SEL)sel
{
    return [[[self __FoObjectSELObserverManager] beforeDict] valueForKey:NSStringFromSelector(sel)];
}

- (NSArray*)__fo_afterBlocks:(SEL)sel
{
    return [[[self __FoObjectSELObserverManager] afterDict] valueForKey:NSStringFromSelector(sel)];
}

@end

@implementation CLASS_NAME(FoObjectOriginResultsOfRespondsToSelHelper)
static char originResultsOfRespondsToSelectorKey;

- (BOOL)restoreOriginResultOfRespondsToSelector:(SEL) sel
{
    if ([Growing getAspectMode] == GrowingAspectModeDynamicSwizzling) {
        void (*tempImp)(void) = nil;
        NSString *selString = [@"foAspectIMPItem_" stringByAppendingString:NSStringFromSelector(sel)];
        foAspectIMPItem *impItem = objc_getAssociatedObject([self class], NSSelectorFromString(selString));
        foAspectIMPItem *impSuperItem = objc_getAssociatedObject([self superclass], NSSelectorFromString(selString));
        if(impItem.oldIMP) {
            tempImp = (void*)impItem.oldIMP;
        } else if (impSuperItem.oldIMP) {
            
            tempImp = impSuperItem.oldIMP;
        } else if (!impSuperItem && class_respondsToSelector([self superclass], sel)) {
            
            tempImp = (void*)class_getMethodImplementation([self superclass], sel);
        }
        
        if (tempImp) {
            return YES;
        } else {
            return NO;
        }
    } else {
        NSMutableDictionary *originResultsOfRespondsToSelector = objc_getAssociatedObject(self, &originResultsOfRespondsToSelectorKey);
        
        
        return ((NSNumber*)originResultsOfRespondsToSelector[NSStringFromSelector(sel)]).boolValue;
    }
    
}

- (void)recordOriginResultOfRespondsToSelector:(SEL) sel
{
    BOOL isRespondsToSelector = [self respondsToSelector:sel];
    NSMutableDictionary *originResultsOfRespondsToSelector = objc_getAssociatedObject(self, &originResultsOfRespondsToSelectorKey);
    if (!originResultsOfRespondsToSelector) {
        originResultsOfRespondsToSelector = [NSMutableDictionary dictionaryWithCapacity:20];
        objc_setAssociatedObject(self,
                                 &originResultsOfRespondsToSelectorKey,
                                 originResultsOfRespondsToSelector,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if(!originResultsOfRespondsToSelector[NSStringFromSelector(sel)])
    {
        originResultsOfRespondsToSelector[NSStringFromSelector(sel)] = @(isRespondsToSelector);
    }
}
@end
