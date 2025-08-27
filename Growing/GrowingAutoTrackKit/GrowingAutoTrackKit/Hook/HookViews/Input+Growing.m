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


#import "Input+Growing.h"
#import "FoSwizzling.h"
#import "FoDefineProperty.h"
#import "GrowingNode.h"
#import "GrowingAutoTrackEvent.h"
#import "UIView+GrowingNode.h"


#define growingAttributesDonotTrackValue_getter_setter(theClass) \
- (BOOL)growingAttributesDonotTrackValue\
{\
    NSNumber * doNotTrackValue = [self growingAttributesDonotTrackValueObject];\
    if (doNotTrackValue == nil) {\
        return YES;\
    }\
    return [super growingAttributesDonotTrackValue];\
}

#define handleTextChange(input) \
if (![input.growingHook_oldText isEqualToString:input.text] && \
    [input.growingHook_textChangeNumber intValue]) {\
    input.growingHook_oldText = input.text;\
    [GrowingTextEditContentChangeEvent sendEventWithNode:input andEventType:GrowingEventTypeUIChangeText];\
}

UISearchBar * getGrowingSearchBar(UIView *self)
{
    UISearchBar *searchBar = (UISearchBar *)[[self superview] superview];
    if ([searchBar isKindOfClass:[UISearchBar class]]) {
        return searchBar;
    } else {
        searchBar = (UISearchBar *)[searchBar superview];
        if ([searchBar isKindOfClass:[UISearchBar class]]) {
            return searchBar;
        }
    }
    return nil;
}

#define handleInputBecomeFirstResponder(input)\
if (!input.isFirstResponder) {\
    if ([self isKindOfClass:NSClassFromString([@"UISearchBar" stringByAppendingString:@"TextField"])]) {\
        UISearchBar *searchBar = getGrowingSearchBar(self);\
        searchBar.growingHook_textChangeNumber = @0;\
    } else {\
        input.growingHook_textChangeNumber = @0;\
    }\
}

#define FoHookResignFirstResponder(theClass) \
FoHookInstance(theClass, @selector(resignFirstResponder), BOOL)\
{\
    if ([self isKindOfClass:NSClassFromString([@"UISearchBar" stringByAppendingString:@"TextField"])]) {\
        UISearchBar *searchBar = getGrowingSearchBar(self);\
        handleTextChange(searchBar)\
    } else if ([self isKindOfClass:[UITextField class]] && self.isSecureTextEntry) {\
        ;\
    } else {\
        handleTextChange(self)\
    }\
    return FoHookOrgin();\
}\
FoHookEnd

#define FoHookBecomeFirstResponder(theClass) \
FoHookInstance(theClass, @selector(becomeFirstResponder), BOOL)\
{\
    handleInputBecomeFirstResponder(self)\
    return FoHookOrgin();\
}\
FoHookEnd

#define GrowingNodeCategoryImplementation(controlClass) \
@implementation controlClass (GrowingNode)\
- (void)growingNodeOutChilds:(NSMutableArray *)childs outPaths:(NSMutableArray *)paths filterChildNode:(id<GrowingNode>)aNode{\
}\
- (void)growingNodeOutContainerChilds:(NSMutableArray *)childs outPaths:(NSMutableArray *)paths filterChildNode:(id<GrowingNode>)aNode{\
}\
- (BOOL)growingViewUserInteraction\
{\
    return !self.growingAttributesDonotTrackValue;\
}\
- (NSString *)growingViewContent\
{\
    if (self.growingAttributesDonotTrackValue &&     \
        ![self isKindOfClass:[UISearchBar class]]) { \
        return @"";                                  \
    } else if (self.text.length > 0) {               \
        return self.text;                            \
    } else {                                         \
        return self.accessibilityLabel;              \
    }\
}\
- (NSString *)growingNodeName\
{\
    if ([self isKindOfClass:[UITextField class]]) {\
        return @"输入框";\
    }\
    if ([self isKindOfClass:[UISearchBar class]]) {\
        return @"搜索框";\
    }\
    if ([self isKindOfClass:[UITextView class]]) {\
        return @"多行文本框";\
    }\
    return NSStringFromClass(self.class);\
}\
- (GrowingElementEventCategory)growingNodeEligibleEventCategory\
{\
    return GrowingElementEventCategoryContentChange;\
}\
@end

#define InputControlTrackImplementation(controlClass) \
@implementation controlClass (Growing)\
growingAttributesDonotTrackValue_getter_setter(controlClass);\
FoSafeStringPropertyImplementation(growingHook_oldText, setGrowingHook_oldText);\
FoPropertyImplementation(NSNumber*, growingHook_textChangeNumber, setGrowingHook_textChangeNumber);\
FoPropertyImplementation(GrowingInputNotificationObserver*, growingHook_InputObserver, setGrowingHook_InputObserver);\
@end;\
GrowingNodeCategoryImplementation(controlClass)

InputControlTrackImplementation(UITextField)
InputControlTrackImplementation(UISearchBar)
InputControlTrackImplementation(UITextView)

FoHookResignFirstResponder(UITextField)
FoHookResignFirstResponder(UITextView)
FoHookBecomeFirstResponder(UITextField)
FoHookBecomeFirstResponder(UITextView)

#import "GrowingInputNotificationObserver.h"
static void setNotification(UIView *self)
{
    GrowingInputNotificationObserver *observer = [[GrowingInputNotificationObserver alloc] init];
    if ([self isKindOfClass:[UITextField class]]) {
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(inputDidChange:) name:UITextFieldTextDidChangeNotification object:self];
            ((UITextField *)self).growingHook_InputObserver = observer;
    } else if ([self isKindOfClass:[UITextView class]]) {
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(inputDidChange:) name:UITextViewTextDidChangeNotification object:self];
        ((UITextView *)self).growingHook_InputObserver = observer;
    }
}

FoHookInstance(UITextField, @selector(init), id)
{
    id ret = FoHookOrgin();
    setNotification(ret);
    return ret;
}
FoHookEnd

FoHookInstance(UITextField, @selector(initWithFrame:), id, CGRect frame)
{
    id ret = FoHookOrgin(frame);
    setNotification(ret);
    return ret;
}
FoHookEnd

FoHookInstance(UITextField, @selector(initWithCoder:), id, NSCoder *coder)
{
    id ret = FoHookOrgin(coder);
    setNotification(ret);
    return ret;
}
FoHookEnd

FoHookInstance(UITextView, @selector(init), id)
{
    id ret = FoHookOrgin();
    setNotification(ret);
    return ret;
}
FoHookEnd

FoHookInstance(UITextView, @selector(initWithFrame:), id, CGRect frame)
{
    id ret = FoHookOrgin(frame);
    setNotification(ret);
    return ret;
}
FoHookEnd

FoHookInstance(UITextView, @selector(initWithCoder:), id, NSCoder *coder)
{
    id ret = FoHookOrgin(coder);
    setNotification(ret);
    return ret;
}
FoHookEnd
