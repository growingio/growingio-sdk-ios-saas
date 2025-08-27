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


#import "GrowingWebViewJavascriptMessage.h"
#import "GrowingAspect.h"
#import "GrowingCoreKit.h"
#import "GrowingEventManager.h"
#import "GrowingDeviceInfo.h"
#import "GrowingCoreKit.h"
#import "GrowingInstance.h"
#import "NSString+GrowingHelper.h"
#import "GrowingEventManager.h"
#import "GrowingManualTrackEvent.h"
#import "GrowingInstance.h"

#define FIELD_SEPARATOR @"::"

NSString *const kGrowingJavascriptMessageTypeKey = @"messageType";
NSString *const kGrowingJavascriptMessageDataKey = @"data";


NSString *const kGrowingJavascriptMessageType_dispatchEvent = @"dispatchEvent";
NSString *const kGrowingJavascriptMessageType_setNativeUserId = @"setNativeUserId";
NSString *const kGrowingJavascriptMessageType_clearNativeUserId = @"clearNativeUserId";


@implementation GrowingWebViewJavascriptMessage

+ (void)handleJavascriptBridgeMessage:(NSString *)message {
    NSLog(@"handleJavascriptBridgeMessage: %@", message);
    if (message == nil || message.length == 0) {
        return;
    }
    NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *messageDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"jsonString解析失败:%@", error);
        return;
    }
    NSString *messageType = messageDic[kGrowingJavascriptMessageTypeKey];
    NSString *messageData = messageDic[kGrowingJavascriptMessageDataKey];
    if ([kGrowingJavascriptMessageType_dispatchEvent isEqualToString:messageType]) {
        [self dispatchEvent:messageData];
    } else if ([kGrowingJavascriptMessageType_setNativeUserId isEqualToString:messageType]) {
        [Growing setUserId:messageData];
    } else if ([kGrowingJavascriptMessageType_clearNativeUserId isEqualToString:messageType]) {
        [Growing clearUserId];
    }
}

+ (void)dispatchEvent:(NSString *)event {
    NSDictionary *eventDic = [event growingHelper_dictionaryObject];
    NSString *eventType = eventDic[@"t"];
    if ([@"evar" isEqualToString:eventType]) {
        NSDictionary *variable = eventDic[@"var"];
        if (variable != nil)
        {
            [Growing setEvar:variable];
        }
    }
    else if ([@"cstm" isEqualToString:eventType]) {
        NSString *eventName = eventDic[@"n"];
        NSDictionary *variable = eventDic[@"var"];
        if (variable == nil){
            [Growing track:eventName];
        }
        else{
            [Growing track:eventName withVariable:variable];
        }
    }
    else if ([@"ppl" isEqualToString:eventType]) {
        NSDictionary *variable = eventDic[@"var"];
        if (variable != nil)
        {
            [Growing setPeopleVariable:variable];
        }
    }
    else if ([@"vstr" isEqualToString:eventType]) {
        
        NSDictionary *visitor = eventDic[@"var"];
        if (visitor != nil)
        {
           [Growing setVisitor:visitor ];
        }
    }
}

@end
