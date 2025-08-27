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
#import "GrowingEventListItem.h"
#import "GrowingChildContentPanel.h"



@protocol GrowingEventListAction <NSObject>

- (void)eventlist_addElementFromItem:(GrowingEventListItem*)item
                chartStyle:(GrowingChildContentPanelStyle)style
                  forPanel:(GrowingChildContentPanel*)panel;

- (BOOL)eventlist_item:(GrowingEventListItem*)item
      canShowWithStyle:(GrowingChildContentPanelStyle)style;

- (UIImage*)eventlist_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode
                                         thisNode:(id<GrowingNode>)thisNode
                                             item:(GrowingEventListItem*)item;

- (UIImage*)replay_screenShotWithTriggerNode:(id<GrowingNode>)triggerNode
                                      thisNode:(id<GrowingNode>)thisNode
                                          item:(GrowingEventListItem*)item;

@end

GrowingEventAction(GrowingEventListAction)
