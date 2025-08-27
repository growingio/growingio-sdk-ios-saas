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
@class GrowingHTTPMessage;
@class GrowingHTTPServer;
@class GrowingWebSocketServer;
@protocol GrowingHTTPResponse;


#define GrowingHTTPConnectionDidDieNotification  @"GrowingHTTPConnectionDidDie"


#pragma mark -


@interface GrowingHTTPConfig : NSObject
{
	GrowingHTTPServer __unsafe_unretained *server;
	NSString __strong *documentRoot;
	dispatch_queue_t queue;
}

- (id)initWithServer:(GrowingHTTPServer *)server documentRoot:(NSString *)documentRoot;
- (id)initWithServer:(GrowingHTTPServer *)server documentRoot:(NSString *)documentRoot queue:(dispatch_queue_t)q;

@property (nonatomic, unsafe_unretained, readonly) GrowingHTTPServer *server;
@property (nonatomic, strong, readonly) NSString *documentRoot;
@property (nonatomic, readonly) dispatch_queue_t queue;

@end


#pragma mark -


@interface GrowingHTTPConnection : NSObject
{
	dispatch_queue_t connectionQueue;
	GrowingGCDAsyncSocket *asyncSocket;
	GrowingHTTPConfig *config;
	
	BOOL started;
	
	GrowingHTTPMessage *request;
	unsigned int numHeaderLines;
	
	BOOL sentResponseHeaders;
	
	NSString *nonce;
	long lastNC;
	
	NSObject<GrowingHTTPResponse> *GrowingHTTPResponse;
	
	NSMutableArray *ranges;
	NSMutableArray *ranges_headers;
	NSString *ranges_boundry;
	int rangeIndex;
	
	UInt64 requestContentLength;
	UInt64 requestContentLengthReceived;
	UInt64 requestChunkSize;
	UInt64 requestChunkSizeReceived;
  
	NSMutableArray *responseDataSizes;
}

- (id)initWithAsyncSocket:(GrowingGCDAsyncSocket *)newSocket configuration:(GrowingHTTPConfig *)aConfig;

- (void)start;
- (void)stop;

- (void)startConnection;

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path;
- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path;

- (BOOL)isSecureServer;
- (NSArray *)sslIdentityAndCertificates;

- (BOOL)isPasswordProtected:(NSString *)path;
- (BOOL)useDigestAccessAuthentication;
- (NSString *)realm;
- (NSString *)passwordForUser:(NSString *)username;

- (NSDictionary *)parseParams:(NSString *)query;
- (NSDictionary *)parseGetParams;

- (NSString *)requestURI;

- (NSArray *)directoryIndexFileNames;
- (NSString *)filePathForURI:(NSString *)path;
- (NSString *)filePathForURI:(NSString *)path allowDirectory:(BOOL)allowDirectory;
- (NSObject<GrowingHTTPResponse> *)GrowingHTTPResponseForMethod:(NSString *)method URI:(NSString *)path;
- (GrowingWebSocketServer *)webSocketServerForURI:(NSString *)path;

- (void)prepareForBodyWithSize:(UInt64)contentLength;
- (void)processBodyData:(NSData *)postDataChunk;
- (void)finishBody;

- (void)handleVersionNotSupported:(NSString *)version;
- (void)handleAuthenticationFailed;
- (void)handleResourceNotFound;
- (void)handleInvalidRequest:(NSData *)data;
- (void)handleUnknownMethod:(NSString *)method;

- (NSData *)preprocessResponse:(GrowingHTTPMessage *)response;
- (NSData *)preprocessErrorResponse:(GrowingHTTPMessage *)response;

- (void)finishResponse;

- (BOOL)shouldDie;
- (void)die;

@end

@interface GrowingHTTPConnection (AsynchronousGrowingHTTPResponse)
- (void)responseHasAvailableData:(NSObject<GrowingHTTPResponse> *)sender;
- (void)responseDidAbort:(NSObject<GrowingHTTPResponse> *)sender;
@end
