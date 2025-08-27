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


#import "GrowingDispatchManager.h"
#import "GrowingCocoaLumberjack.h"

@implementation GrowingDispatchManager

+ (void)dispatchInMainThread:(void (^_Nullable)(void))block
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (void)trackApiSel:(SEL)selector dispatchInMainThread:(void (^_Nullable)(void))block {
    
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
        block();
    } else {
        GIOLogWarn(@"!!!: 埋点相关API-\"%@\"，请在主线程里调用.", NSStringFromSelector(selector));
        dispatch_async(dispatch_get_main_queue(), block);
    }
    
}


@end
