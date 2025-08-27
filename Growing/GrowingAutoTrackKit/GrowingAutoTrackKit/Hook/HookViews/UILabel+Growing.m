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


#import "UILabel+Growing.h"
#import "FoSwizzling.h"
#import "UIView+Growing.h"
#import "GrowingAutoTrackEvent.h"
#import "UIView+GrowingNode.h"
#import <mach-o/getsect.h>
#import "GrowingJavascriptCore.h"

FoHookInstance(UILabel,@selector(setText:),void,NSString *text)
{
    NSString *oldText = self.text;
    FoHookOrgin(text);
    if (![oldText isKindOfClass:[NSString class]] && oldText != nil) {
        return ;
    }
    if (self.text != oldText && ![self.text isEqualToString:oldText] )
    {
        if (oldText.length)
        {
            [GrowingTextChangeEvent sendEventWithNode:self andEventType:GrowingEventTypeUIChangeText];
        }
        else
        {
            [GrowingTextChangeEvent sendEventWithNode:self andEventType:GrowingEventTypeUISetText];
        }
    }
}
FoHookEnd
