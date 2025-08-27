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


#import "FoAspect.h"
#import "GrowingCocoaLumberjack.h"

@implementation foAspectIMPItem

@end


#pragma mark - return token object

@interface foAspectTokenItem : NSObject<FoAspectToken>
@property (nonatomic, weak) id obj;
@property (nonatomic, assign) SEL instanceSelKey;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) BOOL isBeforeBlock;

+ (instancetype)nullItem;

@end

@implementation foAspectTokenItem

+ (instancetype)nullItem
{
    return [[self alloc] init];
}

- (void)remove
{
    id obj = self.obj;
    if (obj)
    {
        foAspectItem *item = objc_getAssociatedObject(obj, self.instanceSelKey);
        if (item)
        {
            if (self.isBeforeBlock)
            {
                if (item->beforeBlock)
                {
                    [item->beforeBlock removeObjectForKey:self.uuid];
                }
            }
            else
            {
                if (item->afterBlock)
                {
                    [item->afterBlock removeObjectForKey:self.uuid];
                }
            }
        }
    }
}
@end


#pragma mark - NSObject category

static void foAspectLog(SEL sel)
{
    GIOLogDebug(@"you should use like follow \n"
          @"[arrayObj %@(id,@selector(objectAtIndex),(NSInterger)index) {\n"
          @"    /* your code */\n"
          @"    return originReturnValue;\n"
          @"}]; ",NSStringFromSelector(sel));
}

@implementation NSObject(foAspect)

- (id<FoAspectToken>)foAspectAfterSeletorNoAddMethod
{
    foAspectLog(_cmd);
    return nil;
}
- (id<FoAspectToken>)foAspectAfterSeletor
{
    foAspectLog(_cmd);
    return nil;
}
- (id<FoAspectToken>)foAspectBeforeSeletorNoAddMethod
{
    foAspectLog(_cmd);
    return nil;
}
- (id<FoAspectToken>)foAspectBeforeSeletor
{
    foAspectLog(_cmd);
    return nil;
}

+ (id<FoAspectToken>)foAspectAfterSeletorNoAddMethod
{
    foAspectLog(_cmd);
    return nil;
}
+ (id<FoAspectToken>)foAspectAfterSeletor
{
    foAspectLog(_cmd);
    return nil;
}
+ (id<FoAspectToken>)foAspectBeforeSeletorNoAddMethod
{
    foAspectLog(_cmd);
    return nil;
}
+ (id<FoAspectToken>)foAspectBeforeSeletor
{
    foAspectLog(_cmd);
    return nil;
}

@end

#pragma mark - block container

@implementation foAspectItem

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        beforeBlock = nil;
        afterBlock = nil;
    }
    return self;
}

- (void)addBlockWithUUID:(NSString *)uuid isBefore:(BOOL)isBefore block:(id)block
{
    block = [block copy];
    if (isBefore)
    {
        if (!beforeBlock)
        {
            beforeBlock = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPointerPersonality
                                                    valueOptions:NSPointerFunctionsStrongMemory
                                                        capacity:3];
        }
        [beforeBlock setObject:block forKey:uuid];
    }
    else
    {
        if (!afterBlock)
        {
            afterBlock = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPointerPersonality
                                                   valueOptions:NSPointerFunctionsStrongMemory
                                                       capacity:3];
        }
        [afterBlock setObject:block forKey:uuid];
    }
}

@end

#pragma mark - private bind template and user block

static BOOL growing_object_isClass(id obj)
{







    Class theGetClass = object_getClass(obj);
    if (class_isMetaClass(theGetClass))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@implementation NSObject(foAspectPrivate)

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
                             userBlock:(id)userBlock
{
    
    BOOL objectIsClass = NO;
    if (object_isClass)
    {
        objectIsClass = object_isClass(self);
    }
    else
    {
        objectIsClass = growing_object_isClass(self);
    }
    
    if (!templateCreatorBlock
        || !userBlock
        || (!addMethod && ![self respondsToSelector:sel]))
    {
        return [foAspectTokenItem nullItem];
    }
    
    NSString *selName = NSStringFromSelector(sel);
    NSString *classSelName = [[NSString alloc] initWithFormat:@"foClassHookedFlag_%@",selName];
    SEL classSEL = NSSelectorFromString(classSelName);
    NSString *instanceSelName = [[NSString alloc] initWithFormat:@"foAspectInstanceFlag_%@",selName];
    SEL instanceSEL = NSSelectorFromString(instanceSelName);
    NSString *foAspectIMPItemSelName = [[NSString alloc] initWithFormat:@"foAspectIMPItem_%@",selName];
    SEL foAspectIMPItemSEL = NSSelectorFromString(foAspectIMPItemSelName);

    
    Class origClassObject = nil;                                                                                                
    Class privateClassObject = nil;                                 
    
    
    if (objectIsClass)
    {                                                                                                                           
        if (class_isMetaClass((Class)self))
        {
                                                                                                                  
        }                                                                                                                       
        else                                                                                                                    
        {                                                                                                                       
            origClassObject = object_getClass(self);
        }                                                                                                                       
    }                                                                                                                           
    else                                                                                                                        
    {                                                                                                                           
        origClassObject     = [self class];
        privateClassObject  = object_getClass(self);
        if (origClassObject == privateClassObject)                                                                              
        {                                                                                                                       
            privateClassObject = Nil;                                                                                           
        }                                                                                                                       
    }                                                                                                                           

                                                                                          
    for (int classIndex = 0 ; classIndex < 2 ; classIndex++)                                                                    
    {                                                                                                                           
        Class classObject = classIndex == 0 ? origClassObject : privateClassObject;                                             
        if (Nil == classObject)                                                                                                 
        {                                                                                                                       
            continue;                                                                                                           
        }                                                                                                                       
        Class superClassObject = class_getSuperclass(classObject);                                                              
                                                                                                           
        if (nil == objc_getAssociatedObject(classObject, classSEL))                                                             
        {                                                                                                                       
                                                                                                             
            objc_setAssociatedObject(classObject,                                                                               
                                     classSEL,                                                                                  
                                     @YES,                                                                                      
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
                                                                                                          
            unsigned int methodsCount = 0;                                                                                      
            Method *methods = class_copyMethodList(classObject, &methodsCount);                                                 
            Method oldMethod = nil;                                                                                             
            IMP    oldIMP = nil;                                                                                                
            for (NSInteger i = 0 ; i < methodsCount ; i ++)                                                                     
            {                                                                                                                   
                Method method = methods[i];                                                                                     
                if (method_getName(method) == sel)                                                                              
                {                                                                                                               
                    oldMethod = method;                                                                                         
                    oldIMP = method_getImplementation(method);                                                                  
                    break;                                                                                                      
                }
            }
            
            foAspectIMPItem *impItem = [[foAspectIMPItem alloc] init];
            impItem.oldIMP = oldIMP;
            impItem.selName = selName;
            objc_setAssociatedObject(classObject, foAspectIMPItemSEL, impItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
            NSString *typeEncoding = nil;
            id templateBlock = templateCreatorBlock(classObject,
                                                    superClassObject,
                                                    sel,
                                                    classSEL,
                                                    instanceSEL,
                                                    oldIMP,
                                                    oldMethod ? nil : &typeEncoding);
    
            IMP blockImp = imp_implementationWithBlock(templateBlock);                                                            
            
            if (oldMethod)                                                                                                        
            {                                                                                                                     
                method_setImplementation(oldMethod,blockImp);                                                                     
            }                                                                                                                     
            else                                                                                                                  
            {
                class_addMethod(classObject, sel, blockImp, [typeEncoding UTF8String]);
            }
            free(methods);
        }
    }
    
    foAspectItem *item = objc_getAssociatedObject(self,instanceSEL);
    if (!item)
    {
        item = [[foAspectItem alloc] init];
        objc_setAssociatedObject(self,
                                 instanceSEL,
                                 item,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSString *uuid = [[NSUUID UUID] UUIDString];
    [item addBlockWithUUID:uuid isBefore:isBeforeBlock block:userBlock];
    
    
    foAspectTokenItem *token = [[foAspectTokenItem alloc] init];
    token.obj = self;
    token.instanceSelKey = instanceSEL;
    token.uuid = uuid;
    token.isBeforeBlock = isBeforeBlock;
    
    return token;
}

@end


#pragma mark - use for template block
BOOL foCheckTemplateCanRunBlock(Class templateClass, id object, SEL classHookedFlag)
{
    Class classObject = object_getClass(object);
    while (classObject) {
        
        if (objc_getAssociatedObject(classObject, classHookedFlag))
        {
            if (templateClass == classObject)
            {
                return YES;
            }
            else
            {
                return NO;
            }
        }
        classObject = class_getSuperclass(classObject);
    }
    return NO;
}
