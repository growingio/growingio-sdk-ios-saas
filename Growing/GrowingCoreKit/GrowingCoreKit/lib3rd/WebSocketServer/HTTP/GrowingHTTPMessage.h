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

#if TARGET_OS_IPHONE
  
  #import <CFNetwork/CFNetwork.h>
#endif

#define HTTPVersion1_0  ((NSString *)kCFHTTPVersion1_0)
#define HTTPVersion1_1  ((NSString *)kCFHTTPVersion1_1)


@interface GrowingHTTPMessage : NSObject
{
	CFHTTPMessageRef message;
}

- (id)initEmptyRequest;

- (id)initRequestWithMethod:(NSString *)method URL:(NSURL *)url version:(NSString *)version;

- (id)initResponseWithStatusCode:(NSInteger)code description:(NSString *)description version:(NSString *)version;

- (BOOL)appendData:(NSData *)data;

- (BOOL)isHeaderComplete;

- (NSString *)version;

- (NSString *)method;
- (NSURL *)url;

- (NSInteger)statusCode;

- (NSDictionary *)allHeaderFields;
- (NSString *)headerField:(NSString *)headerField;

- (void)setHeaderField:(NSString *)headerField value:(NSString *)headerFieldValue;

- (NSData *)messageData;

- (NSData *)body;
- (void)setBody:(NSData *)body;

@end
