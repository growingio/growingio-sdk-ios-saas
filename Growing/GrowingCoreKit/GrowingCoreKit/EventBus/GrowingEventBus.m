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


#import "GrowingEventBus.h"
#import "GrowingMediator.h"
#import "GrowingEBEvent.h"
#import "GrowingEventBusMethodMap.h"
#import "GrowingDispatchManager.h"

@implementation GrowingEventBus

+ (void)send:(GrowingEBEvent *)event
{
    if (!event) {
        return;
    }
    
    NSDictionary *methodMap = [GrowingEventBusMethodMap methodMap];
    NSString *eventClassName = NSStringFromClass([event class]);
    
    NSArray *methodArray = methodMap[eventClassName];
    if (methodArray.count == 0) {
        return;
    }
    
    for (NSString *methodString in methodArray) {
        NSArray *array = [methodString componentsSeparatedByString:@"/"];
        if (array.count != 3) {
            continue;
        }
        NSString *className = array[0];
        BOOL isClassMethod = [array[1] isEqualToString:@"1"] ? YES : NO;
        NSString *selString = array[2];
        
        if (isClassMethod) {
            [GrowingDispatchManager dispatchInMainThread:^{
                [[GrowingMediator sharedInstance] performClass:className action:selString params:@{@"0":event}];
            }];
        } else {
            [GrowingDispatchManager dispatchInMainThread:^{
                Class aclass = NSClassFromString(className);
                if (aclass) {
                    id instance = [[aclass alloc] init];
                    [[GrowingMediator sharedInstance] performTarget:instance action:selString params:@{@"0":event}];
                }
            }];
        }
    }
}

@end
