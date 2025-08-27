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


#import "MBProgressHUD+Growing.h"
#import "FoSwizzling.h"
#import "UIView+Growing.h"
#import "GrowingEventManager.h"
#import "UIView+GrowingNode.h"
#import "UIControl+Growing.h"
#import <mach-o/getsect.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstancePlus("MBProgressHUDRoundedButton", UIButton *, @selector(intrinsicContentSize), CGSize)
#pragma clang diagnostic pop
{
    CGSize originSize = FoHookOrgin();
    if ([self.allTargets count] == 1 && [[self.allTargets anyObject] isKindOfClass:[GrowingUIControlObserver class]]){
        return CGSizeZero;
    } else {
        return originSize;
    }
}
FoHookEnd

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
FoHookInstancePlus("BJLMBProgressHUDRoundedButton", UIButton *, @selector(intrinsicContentSize), CGSize)
#pragma clang diagnostic pop
{
    CGSize originSize = FoHookOrgin();
    if ([self.allTargets count] == 1 && [[self.allTargets anyObject] isKindOfClass:[GrowingUIControlObserver class]]){
        return CGSizeZero;
    } else {
        return originSize;
    }
}
FoHookEnd
