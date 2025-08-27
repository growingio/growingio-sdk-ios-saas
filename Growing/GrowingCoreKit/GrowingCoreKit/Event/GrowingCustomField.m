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


#import "GrowingCustomField.h"
#import "NSDictionary+GrowingHelper.h"
#import "GrowingEventManager.h"
#import "GrowingManualTrackEvent.h"
#import <objc/runtime.h>
#import "GrowingMobileDebugger.h"
#import <pthread.h>
#import "GrowingGlobal.h"
#import "GrowingCocoaLumberjack.h"

@implementation GrowingCustomField
{
    NSMutableDictionary *_persistentData;
    NSString *_filePath;
    BOOL isFirstSetCS;
    BOOL userAccess;
}

static pthread_mutex_t csMutex;
pthread_mutex_t * getCSMutexPointer()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_mutex_init(&csMutex, NULL);
    });
    return &csMutex;
}

+ (instancetype)shareInstance
{
    static id obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *dirPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"libGrowing"];
        _filePath = [dirPath stringByAppendingPathComponent:@"D00C531B-CC47-48D4-A84A-FEAB505FDFD5.plist"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        if([[NSFileManager defaultManager] fileExistsAtPath:dirPath])
        {
            _persistentData = [NSMutableDictionary dictionaryWithContentsOfFile:_filePath];
            if (!_persistentData) {
                _persistentData = [[NSMutableDictionary alloc] init];
                [self persistence];
            }
            [self setCS];
            isFirstSetCS = YES;
        }
    }
    return self;
}

#define setCs(n)                    \
- (void)setCs##n:(NSString *)cs     \
{                                   \
    [self handleFirstSetCS];        \
    _cs##n = [cs copy];             \
    if (userAccess) {               \
        [self persistence];         \
    }                               \
}

setCs(1)

- (void)handleFirstSetCS
{
    if (isFirstSetCS) {
        isFirstSetCS = NO;
        
        userAccess = NO;
        self.cs1 = nil;
        userAccess = YES;
    }
}

- (void)setCS
{
    userAccess = NO;
    self.cs1 = [_persistentData valueForKey:@"CS1"];
    userAccess = YES;
}

- (void)persistence
{
    [_persistentData setValue:self.cs1 forKey:@"CS1"];
    NSMutableDictionary *dataDict = [_persistentData mutableCopy];
    [[GrowingEventManager shareInstance] dispathInUpload:^{
        [dataDict writeToFile:self->_filePath atomically:YES];
    }];
}



- (void)sendEvarEvent:(NSDictionary<NSString *, NSObject *> *)evar
{
    
    [[GrowingMobileDebugger shareDebugger] cacheValue:evar ofType:@"evar"];


    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:evar];
    if (![dict isValidDicVar]) {
        return ;
    }
    if (dict.count > 100 ) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    [GrowingEvarEvent sendEvarEvent:dict];
}

- (void)sendPeopleEvent:(NSDictionary<NSString *, NSObject *> *)peopleVar
{
    
    [[GrowingMobileDebugger shareDebugger] cacheValue:peopleVar ofType:@"ppl"];


    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:peopleVar];
    if (![dict isValidDicVar]) {
        return ;
    }
    if (dict.count > 100 ) {
        GIOLogError(parameterValueErrorLog);
        return ;
    }
    [GrowingPeopleVarEvent sendEventWithVariable:dict];
}

- (void)sendCustomTrackEventWithName:(NSString *)eventName andNumber:(NSNumber *)number andVariable:(NSDictionary<NSString *, NSObject *> *)variable
{


    if ([self isOnlyCoreKit]) {
        [self sendGIOFakePageEvent];
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:variable];
    [GrowingCustomTrackEvent sendEventWithName:eventName andNumber:number andVariable:dict];
}

- (BOOL)isOnlyCoreKit {
    return !NSClassFromString(@"GrowingHeatMapManager");
}

- (void)sendGIOFakePageEvent {
    if ([self isOnlyCoreKit]) {
        GrowingEvent *eventPage = [[GrowingEvent alloc] init];
        eventPage.dataDict[@"t"] = @"page";
        eventPage.dataDict[@"p"] = @"GIOFakePage";
        
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation != UIInterfaceOrientationUnknown) {
            eventPage.dataDict[@"o"] = UIInterfaceOrientationIsPortrait(orientation) ? @"portrait" : @"landscape";
        }
        eventPage.dataDict[@"tl"] = @"";
        eventPage.dataDict[@"ptm"] = eventPage.dataDict[@"tm"];
        [GrowingEventManager shareInstance].lastPageEvent = [[GrowingEvent alloc] initWithUUID:eventPage.uuid data:eventPage.dataDict];
        [[GrowingEventManager shareInstance] addEvent:eventPage
                                             thisNode:nil
                                          triggerNode:nil
                                          withContext:nil];
    }
}

- (void)sendVisitorEvent:(NSDictionary<NSString *, NSObject *> *)variable {


    if ([variable isKindOfClass:[NSDictionary class]]) {
        if (![variable isValidDicVar]) {
            return ;
        }
        if (variable.count > 100 ) {
            GIOLogError(parameterValueErrorLog);
            return ;
        }
    }
    
    self.growingVistorVar = [variable mutableCopy];
    [GrowingVisitorEvent sendVisitorEvent:variable];
}

@end
