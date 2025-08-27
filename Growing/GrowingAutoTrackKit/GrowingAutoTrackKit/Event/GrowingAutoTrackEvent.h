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
#import "GrowingEvent.h"
#import "GrowingManualTrackEvent.h"
#import "GrowingNode.h"
@class GrowingJavascriptCore;


@interface GrowingPageEvent : GrowingEvent

@property (nonatomic, assign) BOOL isResend;

+ (void)resendPageEvent;
+ (void)resendPageEventForCS1Change;
+ (void)sendEventWithController:(UIViewController* _Nonnull)controller;
+ (void)resendEventWithController:(UIViewController* _Nonnull)controller;
+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict;

+ (void)sendPage:(NSString *_Nullable)page;

@end


@interface GrowingImpressionEvent : GrowingEvent
+ (void)sendEventWithNode:(id<GrowingNode> _Nonnull)node
             andEventType:(GrowingEventType)eventType;

+ (void)sendEventsWithJavascriptCore:(GrowingJavascriptCore * _Nonnull)javascriptCore
                            andNodes:(NSArray<GrowingDullNode *> * _Nonnull)nodes
                           eventType:(GrowingEventType)eventType
                     andPageDataDict:(NSDictionary* _Nonnull)pageData;
@end

@interface GrowingNewCellNoTrackEvent : GrowingEvent
+ (void)sendEventWithNode:(id<GrowingNode> _Nonnull)node
             andEventType:(GrowingEventType)eventType;
@end

@interface GrowingTextChangeEvent : GrowingImpressionEvent
@end

@interface GrowingTextEditContentChangeEvent : GrowingTextChangeEvent
@end

@interface GrowingClickEvent : GrowingImpressionEvent
@end


@interface GrowingSubmitEvent : GrowingClickEvent
@end

@interface GrowingTapEvent : GrowingClickEvent
@end

@interface GrowingDoubleClickEvent : GrowingClickEvent
@end

@interface GrowingLongPressEvent : GrowingClickEvent
@end

@interface GrowingTouchDownEvent : GrowingClickEvent
@end

@interface GrowingViewHideEvent : GrowingEvent

+ (void)sendEventWithNode:(id<GrowingNode> _Nonnull)node
             andEventType:(GrowingEventType)eventType;

@end

@interface GrowingPvarEvent : GrowingCustomRootEvent
+ (void)sendPvarEvent:(UIViewController * _Nonnull)viewController;

+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict;
@end

@interface GrowingEvarEvent (AutoTrackKit)

+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict;

@end

@interface GrowingCustomTrackEvent (AutoTrackKit)

+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict;

@end

@interface GrowingPeopleVarEvent (AutoTrackKit)

+ (void)sendEventWithJavascriptCore:(GrowingJavascriptCore* _Nonnull)javascriptCore
                    andPageDataDict:(NSDictionary* _Nonnull)pageDataDict;

@end
