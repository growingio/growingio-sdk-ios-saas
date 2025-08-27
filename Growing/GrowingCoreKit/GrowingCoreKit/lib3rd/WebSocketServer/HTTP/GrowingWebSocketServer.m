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


#import "GrowingWebSocketServer.h"
#import "GrowingHTTPMessage.h"
#import "GrowingGCDAsyncSocket.h"
#import "GrowingDDNumber.h"
#import "GrowingDDData.h"
#import "GrowingHTTPLogging.h"
#import "GrowingDispatchManager.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif



static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; 

#define TIMEOUT_NONE          -1
#define TIMEOUT_REQUEST_BODY  10

#define TAG_HTTP_REQUEST_BODY      100
#define TAG_HTTP_RESPONSE_HEADERS  200
#define TAG_HTTP_RESPONSE_BODY     201

#define TAG_PREFIX                 300
#define TAG_MSG_PLUS_SUFFIX        301
#define TAG_MSG_WITH_LENGTH        302
#define TAG_MSG_MASKING_KEY        303
#define TAG_PAYLOAD_PREFIX         304
#define TAG_PAYLOAD_LENGTH         305
#define TAG_PAYLOAD_LENGTH16       306
#define TAG_PAYLOAD_LENGTH64       307

#define WS_OP_CONTINUATION_FRAME   0
#define WS_OP_TEXT_FRAME           1
#define WS_OP_BINARY_FRAME         2
#define WS_OP_CONNECTION_CLOSE     8
#define WS_OP_PING                 9
#define WS_OP_PONG                 10






static inline BOOL WS_PAYLOAD_IS_MASKED(UInt8 frame)
{
	return (frame & 0x80) ? YES : NO;
}

static inline NSUInteger WS_PAYLOAD_LENGTH(UInt8 frame)
{
	return frame & 0x7F;
}

@interface GrowingWebSocketServer (PrivateAPI)

- (void)readRequestBody;
- (void)sendResponseBody;
- (void)sendResponseHeaders;

@end


#pragma mark -


@implementation GrowingWebSocketServer
{
	BOOL isRFC6455;
	BOOL nextFrameMasked;
	NSUInteger nextOpCode;
	NSData *maskingKey;
}

+ (BOOL)isGrowingWebSocketServerRequest:(GrowingHTTPMessage *)request
{
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	NSString *upgradeHeaderValue = [request headerField:@"Upgrade"];
	NSString *connectionHeaderValue = [request headerField:@"Connection"];
	
	BOOL isGrowingWebSocketServer = YES;
	
	if (!upgradeHeaderValue || !connectionHeaderValue) {
		isGrowingWebSocketServer = NO;
	}
	else if (![upgradeHeaderValue caseInsensitiveCompare:@"WebSocket"] == NSOrderedSame) {
		isGrowingWebSocketServer = NO;
	}
	else if ([connectionHeaderValue rangeOfString:@"Upgrade" options:NSCaseInsensitiveSearch].location == NSNotFound) {
		isGrowingWebSocketServer = NO;
	}
		
	return isGrowingWebSocketServer;
}

+ (BOOL)isVersion76Request:(GrowingHTTPMessage *)request
{
	NSString *key1 = [request headerField:@"Sec-WebSocket-Key1"];
	NSString *key2 = [request headerField:@"Sec-WebSocket-Key2"];
	
	BOOL isVersion76;
	
	if (!key1 || !key2) {
		isVersion76 = NO;
	}
	else {
		isVersion76 = YES;
	}
		
	return isVersion76;
}

+ (BOOL)isRFC6455Request:(GrowingHTTPMessage *)request
{
	NSString *key = [request headerField:@"Sec-WebSocket-Key"];
	BOOL isRFC6455 = (key != nil);

	return isRFC6455;
}


#pragma mark Setup and Teardown


@synthesize GrowingWebSocketServerQueue;

- (id)initWithRequest:(GrowingHTTPMessage *)aRequest socket:(GrowingGCDAsyncSocket *)socket
{	
	if (aRequest == nil)
	{
		return nil;
	}
	
	if ((self = [super init]))
	{
		
		GrowingWebSocketServerQueue = dispatch_queue_create("GrowingWebSocketServer", NULL);
		request = aRequest;
		
		asyncSocket = socket;
		[asyncSocket setDelegate:self delegateQueue:GrowingWebSocketServerQueue];
		
		isOpen = NO;
		isVersion76 = [[self class] isVersion76Request:request];
		isRFC6455 = [[self class] isRFC6455Request:request];
		
		term = [[NSData alloc] initWithBytes:"\xFF" length:1];
	}
	return self;
}

- (void)dealloc
{
	
	#if !OS_OBJECT_USE_OBJC
	dispatch_release(GrowingWebSocketServerQueue);
	#endif
	
	[asyncSocket setDelegate:nil delegateQueue:NULL];
	[asyncSocket disconnect];
}

- (id)delegate
{
	__block id result = nil;
	
	dispatch_sync(GrowingWebSocketServerQueue, ^{
		result = delegate;
	});
	
	return result;
}

- (void)setDelegate:(id)newDelegate
{
	dispatch_async(GrowingWebSocketServerQueue, ^{
		delegate = newDelegate;
	});
}


#pragma mark Start and Stop



- (void)start
{
	
	
	
	dispatch_async(GrowingWebSocketServerQueue, ^{ @autoreleasepool {
		
		if (isStarted) return;
		isStarted = YES;
		
		if (isVersion76)
		{
			[self readRequestBody];
		}
		else
		{
			[self sendResponseHeaders];
			[self didOpen];
		}
	}});
}


- (void)stop
{
	
	
	
	dispatch_async(GrowingWebSocketServerQueue, ^{ @autoreleasepool {
		
		[asyncSocket disconnect];
	}});
}


#pragma mark HTTP Response


- (void)readRequestBody
{
	NSAssert(isVersion76, @"GrowingWebSocketServer version 75 doesn't contain a request body");
	
	[asyncSocket readDataToLength:8 withTimeout:TIMEOUT_NONE tag:TAG_HTTP_REQUEST_BODY];
}

- (NSString *)originResponseHeaderValue
{
	NSString *origin = [request headerField:@"Origin"];
	
	if (origin == nil)
	{
		NSString *port = [NSString stringWithFormat:@"%hu", [asyncSocket localPort]];
		
		return [NSString stringWithFormat:@"http://localhost:%@", port];
	}
	else
	{
		return origin;
	}
}

- (NSString *)locationResponseHeaderValue
{
	
	NSString *location;
	
	NSString *scheme = [asyncSocket isSecure] ? @"wss" : @"ws";
	NSString *host = [request headerField:@"Host"];
	
	NSString *requestUri = [[request url] relativeString];
	
	if (host == nil)
	{
		NSString *port = [NSString stringWithFormat:@"%hu", [asyncSocket localPort]];
		
		location = [NSString stringWithFormat:@"%@://localhost:%@%@", scheme, port, requestUri];
	}
	else
	{
		location = [NSString stringWithFormat:@"%@://%@%@", scheme, host, requestUri];
	}
	
	return location;
}

- (NSString *)secGrowingWebSocketServerKeyResponseHeaderValue {
	NSString *key = [request headerField: @"Sec-WebSocket-Key"];
	NSString *guid = @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	return [[key stringByAppendingString: guid] dataUsingEncoding: NSUTF8StringEncoding].growing_sha1Digest.growing_base64Encoded;
}

- (void)sendResponseHeaders
{
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

	
	GrowingHTTPMessage *wsResponse = [[GrowingHTTPMessage alloc] initResponseWithStatusCode:101
	                                                              description:@"Web Socket Protocol Handshake"
	                                                                  version:HTTPVersion1_1];
	
	[wsResponse setHeaderField:@"Upgrade" value:@"WebSocket"];
	[wsResponse setHeaderField:@"Connection" value:@"Upgrade"];
	
	
	
	
	
	
	
	
	
	
	NSString *originValue = [self originResponseHeaderValue];
	NSString *locationValue = [self locationResponseHeaderValue];
	
	NSString *originField = isVersion76 ? @"Sec-WebSocket-Origin" : @"WebSocket-Origin";
	NSString *locationField = isVersion76 ? @"Sec-WebSocket-Location" : @"WebSocket-Location";
	
	[wsResponse setHeaderField:originField value:originValue];
	[wsResponse setHeaderField:locationField value:locationValue];
	
	NSString *acceptValue = [self secGrowingWebSocketServerKeyResponseHeaderValue];
	if (acceptValue) {
		[wsResponse setHeaderField: @"Sec-WebSocket-Accept" value: acceptValue];
	}

	NSData *responseHeaders = [wsResponse messageData];
	
	[asyncSocket writeData:responseHeaders withTimeout:TIMEOUT_NONE tag:TAG_HTTP_RESPONSE_HEADERS];
}

- (NSData *)processKey:(NSString *)key
{	
	unichar c;
	NSUInteger i;
	NSUInteger length = [key length];
	
	
	
	
	NSMutableString *numStr = [NSMutableString stringWithCapacity:10];
	long long numSpaces = 0;
	
	for (i = 0; i < length; i++)
	{
		c = [key characterAtIndex:i];
		
		if (c >= '0' && c <= '9')
		{
			[numStr appendFormat:@"%C", c];
		}
		else if (c == ' ')
		{
			numSpaces++;
		}
	}
	
	long long num = strtoll([numStr UTF8String], NULL, 10);
	
	long long resultHostNum;
	
	if (numSpaces == 0)
		resultHostNum = 0;
	else
		resultHostNum = num / numSpaces;
	
	
	
	
	
	UInt32 result = OSSwapHostToBigInt32((uint32_t)resultHostNum);
	
	return [NSData dataWithBytes:&result length:4];
}

- (void)sendResponseBody:(NSData *)d3
{
	NSAssert(isVersion76, @"GrowingWebSocketServer version 75 doesn't contain a response body");
	NSAssert([d3 length] == 8, @"Invalid requestBody length");
	
	NSString *key1 = [request headerField:@"Sec-WebSocket-Key1"];
	NSString *key2 = [request headerField:@"Sec-WebSocket-Key2"];
	
	NSData *d1 = [self processKey:key1];
	NSData *d2 = [self processKey:key2];
	
	
	
	NSMutableData *d0 = [NSMutableData dataWithCapacity:(4+4+8)];
	[d0 appendData:d1];
	[d0 appendData:d2];
	[d0 appendData:d3];
	
	
	
	NSData *responseBody = [d0 growing_md5Digest];
	
	[asyncSocket writeData:responseBody withTimeout:TIMEOUT_NONE tag:TAG_HTTP_RESPONSE_BODY];
	
}


#pragma mark Core Functionality


- (void)didOpen
{
	
	
	
	
	
	
	
	[asyncSocket readDataToLength:1 withTimeout:TIMEOUT_NONE tag:(isRFC6455 ? TAG_PAYLOAD_PREFIX : TAG_PREFIX)];
	
    [GrowingDispatchManager dispatchInMainThread:^{
        
        if ([self->delegate respondsToSelector:@selector(webSocketServerDidOpen:)])
        {
            [self->delegate webSocketServerDidOpen:self];
        }
    }];
}

- (void)sendMessage:(NSString *)msg
{	
	NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
	[self sendData:msgData];
}

- (void)sendData:(NSData *)msgData
{
    NSMutableData *data = nil;
	
	if (isRFC6455)
	{
		NSUInteger length = msgData.length;
		if (length <= 125)
		{
			data = [NSMutableData dataWithCapacity:(length + 2)];
			[data appendBytes: "\x81" length:1];
			UInt8 len = (UInt8)length;
			[data appendBytes: &len length:1];
			[data appendData:msgData];
		}
		else if (length <= 0xFFFF)
		{
			data = [NSMutableData dataWithCapacity:(length + 4)];
			[data appendBytes: "\x81\x7E" length:2];
			UInt16 len = (UInt16)length;
			[data appendBytes: (UInt8[]){len >> 8, len & 0xFF} length:2];
			[data appendData:msgData];
		}
		else
		{
			data = [NSMutableData dataWithCapacity:(length + 10)];
			[data appendBytes: "\x81\x7F" length:2];
			[data appendBytes: (UInt8[]){0, 0, 0, 0, (UInt8)(length >> 24), (UInt8)(length >> 16), (UInt8)(length >> 8), length & 0xFF} length:8];
			[data appendData:msgData];
		}
	}
	else
	{
		data = [NSMutableData dataWithCapacity:([msgData length] + 2)];
        
		[data appendBytes:"\x00" length:1];
		[data appendData:msgData];
		[data appendBytes:"\xFF" length:1];
	}
	
	
	
	[asyncSocket writeData:data withTimeout:TIMEOUT_NONE tag:0];
}

- (void)didReceiveMessage:(NSString *)msg
{
	
	
	
	
	
	
	
    [GrowingDispatchManager dispatchInMainThread:^{
        if ([self->delegate respondsToSelector:@selector(webSocketServer:didReceiveMessage:)])
        {
            [self->delegate webSocketServer:self didReceiveMessage:msg];
        }
    }];
	
}

- (void)didClose
{
	
	
	
	
	
	
    [GrowingDispatchManager dispatchInMainThread:^{
        if ([delegate respondsToSelector:@selector(webSocketServerDidClose:)])
        {
            [delegate webSocketServerDidClose:self];
        }
    }];
	
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowingWebSocketServerDidDieNotification object:self];
}

#pragma mark GrowingWebSocketServer Frame

- (BOOL)isValidGrowingWebSocketServerFrame:(UInt8)frame
{
	NSUInteger rsv =  frame & 0x70;
	NSUInteger opcode = frame & 0x0F;
	if (rsv || (3 <= opcode && opcode <= 7) || (0xB <= opcode && opcode <= 0xF))
	{
		return NO;
	}
	return YES;
}


#pragma mark AsyncSocket Delegate





















- (void)socket:(GrowingGCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    static BOOL fin = YES;
	
	if (tag == TAG_HTTP_REQUEST_BODY)
	{
		[self sendResponseHeaders];
		[self sendResponseBody:data];
		[self didOpen];
	}
	else if (tag == TAG_PREFIX)
	{
		UInt8 *pFrame = (UInt8 *)[data bytes];
		UInt8 frame = *pFrame;
		
		if (frame <= 0x7F)
		{
			[asyncSocket readDataToData:term withTimeout:TIMEOUT_NONE tag:TAG_MSG_PLUS_SUFFIX];
		}
		else
		{
			
			[self didClose];
		}
	}
	else if (tag == TAG_PAYLOAD_PREFIX)
	{
		UInt8 *pFrame = (UInt8 *)[data bytes];
		UInt8 frame = *pFrame;

		if ([self isValidGrowingWebSocketServerFrame: frame])
		{
			nextOpCode = (frame & 0x0F);
            const uint8_t *headerBuffer = data.bytes;
            fin = data.length > 0 ? (0x80 & headerBuffer[0]) : YES;
            headerBuffer = NULL;
			[asyncSocket readDataToLength:1 withTimeout:TIMEOUT_NONE tag:TAG_PAYLOAD_LENGTH];
		}
		else
		{
			
			[self didClose];
		}
	}
	else if (tag == TAG_PAYLOAD_LENGTH)
	{
		UInt8 frame = *(UInt8 *)[data bytes];
		BOOL masked = WS_PAYLOAD_IS_MASKED(frame);
		NSUInteger length = WS_PAYLOAD_LENGTH(frame);
		nextFrameMasked = masked;
		maskingKey = nil;
		if (length <= 125)
		{
			if (nextFrameMasked)
			{
				[asyncSocket readDataToLength:4 withTimeout:TIMEOUT_NONE tag:TAG_MSG_MASKING_KEY];
			}
			[asyncSocket readDataToLength:length withTimeout:TIMEOUT_NONE tag:TAG_MSG_WITH_LENGTH];
		}
		else if (length == 126)
		{
			[asyncSocket readDataToLength:2 withTimeout:TIMEOUT_NONE tag:TAG_PAYLOAD_LENGTH16];
		}
		else
		{
			[asyncSocket readDataToLength:8 withTimeout:TIMEOUT_NONE tag:TAG_PAYLOAD_LENGTH64];
		}
	}
	else if (tag == TAG_PAYLOAD_LENGTH16)
	{
		UInt8 *pFrame = (UInt8 *)[data bytes];
		NSUInteger length = ((NSUInteger)pFrame[0] << 8) | (NSUInteger)pFrame[1];
		if (nextFrameMasked) {
			[asyncSocket readDataToLength:4 withTimeout:TIMEOUT_NONE tag:TAG_MSG_MASKING_KEY];
		}
		[asyncSocket readDataToLength:length withTimeout:TIMEOUT_NONE tag:TAG_MSG_WITH_LENGTH];
	}
	else if (tag == TAG_PAYLOAD_LENGTH64)
	{
		

        UInt8 *pFrame = (UInt8 *)[data bytes];
        
        UInt64 length = ((UInt64)pFrame[0] << 8*7)
        |((UInt64)pFrame[1] << 8*6)
        |((UInt64)pFrame[2] << 8*5)
        |((UInt64)pFrame[3] << 8*4)
        |((UInt64)pFrame[4] << 8*3)
        |((UInt64)pFrame[5] << 8*2)
        |((UInt64)pFrame[6] << 8)
        |((UInt64)pFrame[7]);

        if (nextFrameMasked) {
            [asyncSocket readDataToLength:4 withTimeout:TIMEOUT_NONE tag:TAG_MSG_MASKING_KEY];
        }
        [asyncSocket readDataToLength:length withTimeout:TIMEOUT_NONE tag:TAG_MSG_WITH_LENGTH];
	}
	else if (tag == TAG_MSG_WITH_LENGTH)
	{
        static NSMutableData *appendData = nil;
        
		NSUInteger msgLength = [data length];
		if (nextFrameMasked && maskingKey) {
			NSMutableData *masked = data.mutableCopy;
			UInt8 *pData = (UInt8 *)masked.mutableBytes;
			UInt8 *pMask = (UInt8 *)maskingKey.bytes;
			for (NSUInteger i = 0; i < msgLength; i++)
			{
				pData[i] = pData[i] ^ pMask[i % 4];
			}
			data = masked;
		}
        
		if (fin && nextOpCode == WS_OP_TEXT_FRAME) {
			NSString *msg = [[NSString alloc] initWithBytes:[data bytes] length:msgLength encoding:NSUTF8StringEncoding];
			[self didReceiveMessage:msg];
            
        } else if (!fin && nextOpCode == WS_OP_TEXT_FRAME) {
            appendData = [NSMutableData dataWithData:data];

        } else if (!fin && nextOpCode == WS_OP_CONTINUATION_FRAME) {
            [appendData appendData:data];

        } else if (fin && nextOpCode == WS_OP_CONTINUATION_FRAME) {
            [appendData appendData:data];
            NSString *msg = [[NSString alloc] initWithBytes:[appendData bytes] length:[appendData length] encoding:NSUTF8StringEncoding];
            appendData = nil;
            [self didReceiveMessage:msg];

        } else {
			[self didClose];
			return;
		}

		
		[asyncSocket readDataToLength:1 withTimeout:TIMEOUT_NONE tag:TAG_PAYLOAD_PREFIX];
	}
	else if (tag == TAG_MSG_MASKING_KEY)
	{
		maskingKey = data.copy;
	}
	else
	{
		NSUInteger msgLength = [data length] - 1; 
		
		NSString *msg = [[NSString alloc] initWithBytes:[data bytes] length:msgLength encoding:NSUTF8StringEncoding];
		
		[self didReceiveMessage:msg];
		
		
		
		[asyncSocket readDataToLength:1 withTimeout:TIMEOUT_NONE tag:TAG_PREFIX];
	}
}

- (void)socketDidDisconnect:(GrowingGCDAsyncSocket *)sock withError:(NSError *)error
{
	
	[self didClose];
}

@end
