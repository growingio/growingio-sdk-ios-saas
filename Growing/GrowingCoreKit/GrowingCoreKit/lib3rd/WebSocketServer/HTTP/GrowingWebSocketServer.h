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

@class GrowingHTTPMessage;
@class GrowingGCDAsyncSocket;


#define GrowingWebSocketServerDidDieNotification  @"GrowingWebSocketServerDidDie"

@interface GrowingWebSocketServer : NSObject
{
	dispatch_queue_t GrowingWebSocketServerQueue;
	
	GrowingHTTPMessage *request;
	GrowingGCDAsyncSocket *asyncSocket;
	
	NSData *term;
	
	BOOL isStarted;
	BOOL isOpen;
	BOOL isVersion76;
	
	id __unsafe_unretained delegate;
}

+ (BOOL)isGrowingWebSocketServerRequest:(GrowingHTTPMessage *)request;

- (id)initWithRequest:(GrowingHTTPMessage *)request socket:(GrowingGCDAsyncSocket *)socket;


@property ( unsafe_unretained) id delegate;


@property (nonatomic, readonly) dispatch_queue_t GrowingWebSocketServerQueue;


- (void)start;
- (void)stop;


- (void)sendMessage:(NSString *)msg;


- (void)sendData:(NSData *)msg;


- (void)didOpen;
- (void)didReceiveMessage:(NSString *)msg;
- (void)didClose;

@end


#pragma mark -




@protocol GrowingWebSocketServerDelegate
@optional

- (void)webSocketServerDidOpen:(GrowingWebSocketServer *)ws;

- (void)webSocketServer:(GrowingWebSocketServer *)ws didReceiveMessage:(NSString *)msg;

- (void)webSocketServerDidClose:(GrowingWebSocketServer *)ws;

@end
