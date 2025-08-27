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


#import "GrowingHTTPServer.h"
#import "GrowingGCDAsyncSocket.h"
#import "GrowingHTTPConnection.h"
#import "GrowingWebSocketServer.h"
#import "GrowingHTTPLogging.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@interface GrowingHTTPServer (PrivateAPI)

- (void)unpublishBonjour;
- (void)publishBonjour;

+ (void)startBonjourThreadIfNeeded;
+ (void)performBonjourBlock:(dispatch_block_t)block;

@end


#pragma mark -


@implementation GrowingHTTPServer


- (id)init
{
	if ((self = [super init]))
	{
		
		
		serverQueue = dispatch_queue_create("GrowingHTTPServer", NULL);
		connectionQueue = dispatch_queue_create("GrowingHTTPConnection", NULL);
		
		IsOnServerQueueKey = &IsOnServerQueueKey;
		IsOnConnectionQueueKey = &IsOnConnectionQueueKey;
		
		void *nonNullUnusedPointer = (__bridge void *)self; 
		
		dispatch_queue_set_specific(serverQueue, IsOnServerQueueKey, nonNullUnusedPointer, NULL);
		dispatch_queue_set_specific(connectionQueue, IsOnConnectionQueueKey, nonNullUnusedPointer, NULL);
		
		
		asyncSocket = [[GrowingGCDAsyncSocket alloc] initWithDelegate:self delegateQueue:serverQueue];
		
		
		connectionClass = [GrowingHTTPConnection self];
		
		
		interface = nil;
		
		
		
		port = 0;
		
		
		
		
		domain = @"local.";
		
		
		
		
		
		name = @"";
		
		
		connections = [[NSMutableArray alloc] init];
		GrowingWebSocketServers  = [[NSMutableArray alloc] init];
		
		connectionsLock = [[NSLock alloc] init];
		GrowingWebSocketServersLock  = [[NSLock alloc] init];
		
		
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(connectionDidDie:)
		                                             name:GrowingHTTPConnectionDidDieNotification
		                                           object:nil];
		
		
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(GrowingWebSocketServerDidDie:)
		                                             name:GrowingWebSocketServerDidDieNotification
		                                           object:nil];
		
		isRunning = NO;
	}
	return self;
}


- (void)dealloc
{
	
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	
	[self stop];
	
	
	
	#if !OS_OBJECT_USE_OBJC
	dispatch_release(serverQueue);
	dispatch_release(connectionQueue);
	#endif
	
	[asyncSocket setDelegate:nil delegateQueue:NULL];
}


#pragma mark Server Configuration



- (NSString *)documentRoot
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = documentRoot;
	});
	
	return result;
}

- (void)setDocumentRoot:(NSString *)value
{
	
	
	
	if (value && ![value isKindOfClass:[NSString class]])
	{
		return;
	}
	
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		documentRoot = valueCopy;
	});
	
}


- (Class)connectionClass
{
	__block Class result;
	
	dispatch_sync(serverQueue, ^{
		result = connectionClass;
	});
	
	return result;
}

- (void)setConnectionClass:(Class)value
{	
	dispatch_async(serverQueue, ^{
		connectionClass = value;
	});
}


- (NSString *)interface
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = interface;
	});
	
	return result;
}

- (void)setInterface:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		interface = valueCopy;
	});
	
}


- (UInt16)port
{
	__block UInt16 result;
	
	dispatch_sync(serverQueue, ^{
		result = port;
	});
	
    return result;
}

- (UInt16)listeningPort
{
	__block UInt16 result;
	
	dispatch_sync(serverQueue, ^{
		if (isRunning)
			result = [asyncSocket localPort];
		else
			result = 0;
	});
	
	return result;
}

- (void)setPort:(UInt16)value
{
	dispatch_async(serverQueue, ^{
		port = value;
	});
}


- (NSString *)domain
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = domain;
	});
	
    return result;
}

- (void)setDomain:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		domain = valueCopy;
	});
	
}


- (NSString *)name
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = name;
	});
	
	return result;
}

- (NSString *)publishedName
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		
		if (netService == nil)
		{
			result = nil;
		}
		else
		{
			
			dispatch_block_t bonjourBlock = ^{
				result = [[netService name] copy];
			};
			
			[[self class] performBonjourBlock:bonjourBlock];
		}
	});
	
	return result;
}

- (void)setName:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		name = valueCopy;
	});
	
}


- (NSString *)type
{
	__block NSString *result;
	
	dispatch_sync(serverQueue, ^{
		result = type;
	});
	
	return result;
}

- (void)setType:(NSString *)value
{
	NSString *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
		type = valueCopy;
	});
	
}


- (NSDictionary *)TXTRecordDictionary
{
	__block NSDictionary *result;
	
	dispatch_sync(serverQueue, ^{
		result = txtRecordDictionary;
	});
	
	return result;
}

- (void)setTXTRecordDictionary:(NSDictionary *)value
{
	NSDictionary *valueCopy = [value copy];
	
	dispatch_async(serverQueue, ^{
	
		txtRecordDictionary = valueCopy;
		
		
		if (netService)
		{
			NSNetService *theNetService = netService;
			NSData *txtRecordData = nil;
			if (txtRecordDictionary)
				txtRecordData = [NSNetService dataFromTXTRecordDictionary:txtRecordDictionary];
			
			dispatch_block_t bonjourBlock = ^{
				[theNetService setTXTRecordData:txtRecordData];
			};
			
			[[self class] performBonjourBlock:bonjourBlock];
		}
	});
	
}


#pragma mark Server Control


- (BOOL)start:(NSError **)errPtr
{
	__block BOOL success = YES;
	__block NSError *err = nil;
	
	dispatch_sync(serverQueue, ^{ @autoreleasepool {
		
		success = [asyncSocket acceptOnInterface:interface port:port error:&err];
		if (success)
		{
			isRunning = YES;
			[self publishBonjour];
		}
		else
		{
		}
	}});
	
	if (errPtr)
		*errPtr = err;
	
	return success;
}

- (void)stop
{
	[self stop:NO];
}

- (void)stop:(BOOL)keepExistingConnections
{
	
	dispatch_sync(serverQueue, ^{ @autoreleasepool {
		
		
		[self unpublishBonjour];
		
		
		[asyncSocket disconnect];
		isRunning = NO;
		
		if (!keepExistingConnections)
		{
			
			[connectionsLock lock];
			for (GrowingHTTPConnection *connection in connections)
			{
				[connection stop];
			}
			[connections removeAllObjects];
			[connectionsLock unlock];
			
			
			[GrowingWebSocketServersLock lock];
			for (GrowingWebSocketServer *GrowingWebSocketServer in GrowingWebSocketServers)
			{
				[GrowingWebSocketServer stop];
			}
			[GrowingWebSocketServers removeAllObjects];
			[GrowingWebSocketServersLock unlock];
		}
	}});
}

- (BOOL)isRunning
{
	__block BOOL result;
	
	dispatch_sync(serverQueue, ^{
		result = isRunning;
	});
	
	return result;
}

- (void)addGrowingWebSocketServer:(GrowingWebSocketServer *)ws
{
	[GrowingWebSocketServersLock lock];
	
	[GrowingWebSocketServers addObject:ws];
	
	[GrowingWebSocketServersLock unlock];
}


#pragma mark Server Status



- (NSUInteger)numberOfGrowingHTTPConnections
{
	NSUInteger result = 0;
	
	[connectionsLock lock];
	result = [connections count];
	[connectionsLock unlock];
	
	return result;
}


- (NSUInteger)numberOfGrowingWebSocketServerConnections
{
	NSUInteger result = 0;
	
	[GrowingWebSocketServersLock lock];
	result = [GrowingWebSocketServers count];
	[GrowingWebSocketServersLock unlock];
	
	return result;
}


#pragma mark Incoming Connections


- (GrowingHTTPConfig *)config
{
	
	
	
	
	
	
	
	
	
	
	
	return [[GrowingHTTPConfig alloc] initWithServer:self documentRoot:documentRoot queue:connectionQueue];
}

- (void)socket:(GrowingGCDAsyncSocket *)sock didAcceptNewSocket:(GrowingGCDAsyncSocket *)newSocket
{
	GrowingHTTPConnection *newConnection = (GrowingHTTPConnection *)[[connectionClass alloc] initWithAsyncSocket:newSocket
	                                                                                 configuration:[self config]];
	[connectionsLock lock];
	[connections addObject:newConnection];
	[connectionsLock unlock];
	
	[newConnection start];
}


#pragma mark Bonjour


- (void)publishBonjour
{
	NSAssert(dispatch_get_specific(IsOnServerQueueKey) != NULL, @"Must be on serverQueue");
	
	if (type)
	{
		netService = [[NSNetService alloc] initWithDomain:domain type:type name:name port:[asyncSocket localPort]];
		[netService setDelegate:self];
		
		NSNetService *theNetService = netService;
		NSData *txtRecordData = nil;
		if (txtRecordDictionary)
			txtRecordData = [NSNetService dataFromTXTRecordDictionary:txtRecordDictionary];
		
		dispatch_block_t bonjourBlock = ^{
			
			[theNetService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
			[theNetService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
			[theNetService publish];
			
			
			
			if (txtRecordData)
			{
				[theNetService setTXTRecordData:txtRecordData];
			}
		};
		
		[[self class] startBonjourThreadIfNeeded];
		[[self class] performBonjourBlock:bonjourBlock];
	}
}

- (void)unpublishBonjour
{
	NSAssert(dispatch_get_specific(IsOnServerQueueKey) != NULL, @"Must be on serverQueue");
	
	if (netService)
	{
		NSNetService *theNetService = netService;
		
		dispatch_block_t bonjourBlock = ^{
			
			[theNetService stop];
		};
		
		[[self class] performBonjourBlock:bonjourBlock];
		
		netService = nil;
	}
}


- (void)republishBonjour
{
	dispatch_async(serverQueue, ^{
		
		[self unpublishBonjour];
		[self publishBonjour];
	});
}


- (void)netServiceDidPublish:(NSNetService *)ns
{
	
	
	
}


- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	
	
	
	
}


#pragma mark Notifications



- (void)connectionDidDie:(NSNotification *)notification
{
	
	
	[connectionsLock lock];
	
	[connections removeObject:[notification object]];
	
	[connectionsLock unlock];
}


- (void)GrowingWebSocketServerDidDie:(NSNotification *)notification
{
	
	
	[GrowingWebSocketServersLock lock];
	
	[GrowingWebSocketServers removeObject:[notification object]];
	
	[GrowingWebSocketServersLock unlock];
}


#pragma mark Bonjour Thread




static NSThread *bonjourThread;

+ (void)startBonjourThreadIfNeeded
{
	
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		
		
		bonjourThread = [[NSThread alloc] initWithTarget:self
		                                        selector:@selector(bonjourThread)
		                                          object:nil];
		[bonjourThread start];
	});
}

+ (void)bonjourThread
{
	@autoreleasepool {
			
		
		
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
		[NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]
		                                 target:self
		                               selector:@selector(donothingatall:)
		                               userInfo:nil
		                                repeats:YES];
#pragma clang diagnostic pop

		[[NSRunLoop currentRunLoop] run];
			
	}
}

+ (void)executeBonjourBlock:(dispatch_block_t)block
{
	
	NSAssert([NSThread currentThread] == bonjourThread, @"Executed on incorrect thread");
	
	block();
}

+ (void)performBonjourBlock:(dispatch_block_t)block
{
	
	[self performSelector:@selector(executeBonjourBlock:)
	             onThread:bonjourThread
	           withObject:block
	        waitUntilDone:YES];
}

@end
