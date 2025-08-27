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


#import "GrowingHTTPMessage.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


@implementation GrowingHTTPMessage

- (id)initEmptyRequest
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateEmpty(NULL, YES);
	}
	return self;
}

- (id)initRequestWithMethod:(NSString *)method URL:(NSURL *)url version:(NSString *)version
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateRequest(NULL,
		                                    (__bridge CFStringRef)method,
		                                    (__bridge CFURLRef)url,
		                                    (__bridge CFStringRef)version);
	}
	return self;
}

- (id)initResponseWithStatusCode:(NSInteger)code description:(NSString *)description version:(NSString *)version
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateResponse(NULL,
		                                      (CFIndex)code,
		                                      (__bridge CFStringRef)description,
		                                      (__bridge CFStringRef)version);
	}
	return self;
}

- (void)dealloc
{
	if (message)
	{
		CFRelease(message);
	}
}

- (BOOL)appendData:(NSData *)data
{
	return CFHTTPMessageAppendBytes(message, [data bytes], [data length]);
}

- (BOOL)isHeaderComplete
{
	return CFHTTPMessageIsHeaderComplete(message);
}

- (NSString *)version
{
	return (__bridge_transfer NSString *)CFHTTPMessageCopyVersion(message);
}

- (NSString *)method
{
	return (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod(message);
}

- (NSURL *)url
{
	return (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL(message);
}

- (NSInteger)statusCode
{
	return (NSInteger)CFHTTPMessageGetResponseStatusCode(message);
}

- (NSDictionary *)allHeaderFields
{
	return (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(message);
}

- (NSString *)headerField:(NSString *)headerField
{
	return (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue(message, (__bridge CFStringRef)headerField);
}

- (void)setHeaderField:(NSString *)headerField value:(NSString *)headerFieldValue
{
	CFHTTPMessageSetHeaderFieldValue(message,
	                                 (__bridge CFStringRef)headerField,
	                                 (__bridge CFStringRef)headerFieldValue);
}

- (NSData *)messageData
{
	return (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(message);
}

- (NSData *)body
{
	return (__bridge_transfer NSData *)CFHTTPMessageCopyBody(message);
}

- (void)setBody:(NSData *)body
{
	CFHTTPMessageSetBody(message, (__bridge CFDataRef)body);
}

@end
