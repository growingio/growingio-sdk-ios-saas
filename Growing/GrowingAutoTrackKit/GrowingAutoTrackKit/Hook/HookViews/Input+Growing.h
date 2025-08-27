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

UISearchBar * getGrowingSearchBar(UIView *self);

@class GrowingInputNotificationObserver;
@interface UITextField (Growing)

@property (nonatomic, strong) NSString *growingHook_oldText;
@property (nonatomic, strong) GrowingInputNotificationObserver *growingHook_InputObserver;
@property (nonatomic, strong) NSNumber *growingHook_textChangeNumber;

@end

@interface UITextField (GrowingNode)

@end

@class GrowingInputNotificationObserver;
@interface UISearchBar (Growing)

@property (nonatomic, strong) NSString *growingHook_oldText;
@property (nonatomic, strong) NSNumber *growingHook_textChangeNumber;

@end

@interface UISearchBar (GrowingNode)

@end

@class GrowingInputNotificationObserver;
@interface UITextView (Growing)

@property (nonatomic, strong) NSString *growingHook_oldText;
@property (nonatomic, strong) GrowingInputNotificationObserver *growingHook_InputObserver;
@property (nonatomic, strong) NSNumber *growingHook_textChangeNumber;

@end

@interface UITextView (GrowingNode)

@end
