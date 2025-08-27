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


#import "GrowingInputNotificationObserver.h"
#import "Input+Growing.h"
#import <UIKit/UIKit.h>
@implementation GrowingInputNotificationObserver


- (void)inputDidChange:(NSNotification *)notification
{
    id object = notification.object;
    if ([object isKindOfClass:NSClassFromString([@"UISearchBar" stringByAppendingString:@"TextField"])]) {
        UISearchBar *searchBar = getGrowingSearchBar(object);
        int changeNumber = searchBar.growingHook_textChangeNumber.intValue;
        searchBar.growingHook_textChangeNumber = [NSNumber numberWithInt:changeNumber + 1];
    } else if ([object isKindOfClass:[UITextField class]]) {
        int changeNumber = ((UITextField *)object).growingHook_textChangeNumber.intValue;
        ((UITextField *)object).growingHook_textChangeNumber = [NSNumber numberWithInt:changeNumber + 1];
    } else if ([object isKindOfClass:[UITextView class]]) {
        int changeNumber = ((UITextView *)object).growingHook_textChangeNumber.intValue;
        ((UITextView *)object).growingHook_textChangeNumber = [NSNumber numberWithInt:changeNumber + 1];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
