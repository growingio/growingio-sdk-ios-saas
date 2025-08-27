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

@class GrowingGCDAsyncSocket;
@class GrowingWebSocketServer;

#if TARGET_OS_IPHONE
  #if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000 
    #define IMPLEMENTED_PROTOCOLS <NSNetServiceDelegate>
  #else
    #define IMPLEMENTED_PROTOCOLS 
  #endif
#else
  #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060 
    #define IMPLEMENTED_PROTOCOLS <NSNetServiceDelegate>
  #else
    #define IMPLEMENTED_PROTOCOLS 
  #endif
#endif


@interface GrowingHTTPServer : NSObject IMPLEMENTED_PROTOCOLS
{
	
	GrowingGCDAsyncSocket *asyncSocket;
	
	
	dispatch_queue_t serverQueue;
	dispatch_queue_t connectionQueue;
	void *IsOnServerQueueKey;
	void *IsOnConnectionQueueKey;
	
	
	NSString *documentRoot;
	Class connectionClass;
	NSString *interface;
	UInt16 port;
	
	
	NSNetService *netService;
	NSString *domain;
	NSString *type;
	NSString *name;
	NSString *publishedName;
	NSDictionary *txtRecordDictionary;
	
	
	NSMutableArray *connections;
	NSMutableArray *GrowingWebSocketServers;
	NSLock *connectionsLock;
	NSLock *GrowingWebSocketServersLock;
	
	BOOL isRunning;
}


- (NSString *)documentRoot;
- (void)setDocumentRoot:(NSString *)value;


- (Class)connectionClass;
- (void)setConnectionClass:(Class)value;


- (NSString *)interface;
- (void)setInterface:(NSString *)value;


- (UInt16)port;
- (UInt16)listeningPort;
- (void)setPort:(UInt16)value;


- (NSString *)domain;
- (void)setDomain:(NSString *)value;


- (NSString *)name;
- (NSString *)publishedName;
- (void)setName:(NSString *)value;


- (NSString *)type;
- (void)setType:(NSString *)value;


- (void)republishBonjour;


- (NSDictionary *)TXTRecordDictionary;
- (void)setTXTRecordDictionary:(NSDictionary *)dict;


- (BOOL)start:(NSError **)errPtr;


- (void)stop;
- (void)stop:(BOOL)keepExistingConnections;

- (BOOL)isRunning;

- (void)addGrowingWebSocketServer:(GrowingWebSocketServer *)ws;

- (NSUInteger)numberOfGrowingHTTPConnections;
- (NSUInteger)numberOfGrowingWebSocketServerConnections;

@end
