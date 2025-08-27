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


#import "GrowingHTTPDynamicFileResponse.h"
#import "GrowingHTTPConnection.h"
#import "GrowingHTTPLogging.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#define NULL_FD  -1


@implementation GrowingHTTPDynamicFileResponse

- (id)initWithFilePath:(NSString *)fpath
         forConnection:(GrowingHTTPConnection *)parent
             separator:(NSString *)separatorStr
 replacementDictionary:(NSDictionary *)dict
{
	if ((self = [super initWithFilePath:fpath forConnection:parent]))
	{		
		separator = [separatorStr dataUsingEncoding:NSUTF8StringEncoding];
		replacementDict = dict;
	}
	return self;
}

- (BOOL)isChunked
{
	return YES;
}

- (UInt64)contentLength
{
	
	
		
	return 0;
}

- (void)setOffset:(UInt64)offset
{
	
	
	
}

- (BOOL)isDone
{
	BOOL result = (readOffset == fileLength) && (readBufferOffset == 0);
		
	return result;
}

- (void)processReadBuffer
{
	
	
	
	NSUInteger bufLen = readBufferOffset;
	NSUInteger sepLen = [separator length];
	
	
	
	
	NSUInteger offset = 0;
	NSUInteger stopOffset = (bufLen > sepLen) ? bufLen - sepLen + 1 : 0;
	
	
	
	
	
	
	
	
	BOOL found1 = NO;
	BOOL found2 = NO;
	
	NSUInteger s1 = 0;
	NSUInteger s2 = 0;
	
	const void *sep = [separator bytes];
	
	while (offset < stopOffset)
	{
		const void *subBuffer = readBuffer + offset;
		
		if (memcmp(subBuffer, sep, sepLen) == 0)
		{
			if (!found1)
			{
				
				
				found1 = YES;
				s1 = offset;
				offset += sepLen;
				
			}
			else
			{
				
				
				found2 = YES;
				s2 = offset;
				offset += sepLen;
				
			}
			
			if (found1 && found2)
			{
				
				
				
				NSRange fullRange = NSMakeRange(s1, (s2 - s1 + sepLen));
				NSRange strRange = NSMakeRange(s1 + sepLen, (s2 - s1 - sepLen));
				
				
				
				
				
				void *strBuf = readBuffer + strRange.location;
				NSUInteger strLen = strRange.length;
				
				NSString *key = [[NSString alloc] initWithBytes:strBuf length:strLen encoding:NSUTF8StringEncoding];
				if (key)
				{
					
					
					id value = [replacementDict objectForKey:key];
					if (value)
					{
						
						
												
						NSData *v = [[value description] dataUsingEncoding:NSUTF8StringEncoding];
						NSUInteger vLength = [v length];
						
						if (fullRange.length == vLength)
						{
							
							
							
							
							memcpy(readBuffer + fullRange.location, [v bytes], vLength);
						}
						else 
						{
							NSInteger diff = (NSInteger)vLength - (NSInteger)fullRange.length;
							
							if (diff > 0)
							{
								
								
								
								if (diff > (readBufferSize - bufLen))
								{
									NSUInteger inc = MAX(diff, 256);
									
									readBufferSize += inc;
									readBuffer = reallocf(readBuffer, readBufferSize);
								}
							}
							
							
							
							
							
							
							
							
							
							
							
							
							
							
							void *src = readBuffer + fullRange.location + fullRange.length;
							void *dst = readBuffer + fullRange.location + vLength;
							
							NSUInteger remaining = bufLen - (fullRange.location + fullRange.length);
							
							memmove(dst, src, remaining);
							
							
							
							
							
							
							
							
							memcpy(readBuffer + fullRange.location, [v bytes], vLength);
							
							
							
							bufLen     += diff;
							offset     += diff;
							stopOffset += diff;
						}
					}
					
				}
				
				found1 = found2 = NO;
			}
		}
		else
		{
			offset++;
		}
	}
	
	
	
	
	if (readOffset == fileLength)
	{
		
		
		
		data = [[NSData alloc] initWithBytes:readBuffer length:bufLen];
		readBufferOffset = 0;
	}
	else
	{
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		NSUInteger available;
		if (found1)
		{
			
			available = s1;
		}
		else
		{
			
			available = stopOffset;
		}
		
		
		
		data = [[NSData alloc] initWithBytes:readBuffer length:available];
		
		
		
		
		NSUInteger remaining = bufLen - available;
		
		memmove(readBuffer, readBuffer + available, remaining);
		readBufferOffset = remaining;
	}
	
	[connection responseHasAvailableData:self];
}

- (void)dealloc
{
	
}

@end
