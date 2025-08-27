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


#import "GrowingHTTPRedirectResponse.h"
#import "GrowingHTTPLogging.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif




@implementation GrowingHTTPRedirectResponse

- (id)initWithPath:(NSString *)path
{
	if ((self = [super init]))
	{
		redirectPath = [path copy];
	}
	return self;
}

- (UInt64)contentLength
{
	return 0;
}

- (UInt64)offset
{
	return 0;
}

- (void)setOffset:(UInt64)offset
{
	
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	return nil;
}

- (BOOL)isDone
{
	return YES;
}

- (NSDictionary *)httpHeaders
{	
	return [NSDictionary dictionaryWithObject:redirectPath forKey:@"Location"];
}

- (NSInteger)status
{
	return 302;
}

- (void)dealloc
{
	
}

@end
