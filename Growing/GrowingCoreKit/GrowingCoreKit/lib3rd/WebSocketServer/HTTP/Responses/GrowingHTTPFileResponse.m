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


#import "GrowingHTTPFileResponse.h"
#import "GrowingHTTPConnection.h"
#import "GrowingHTTPLogging.h"

#import <unistd.h>
#import <fcntl.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#define NULL_FD  -1


@implementation GrowingHTTPFileResponse

- (id)initWithFilePath:(NSString *)fpath forConnection:(GrowingHTTPConnection *)parent
{
	if((self = [super init]))
	{
		connection = parent; 
		
		fileFD = NULL_FD;
		filePath = [[fpath copy] stringByResolvingSymlinksInPath];
		if (filePath == nil)
		{
			return nil;
		}
		
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
		if (fileAttributes == nil)
		{
			return nil;
		}
		
		fileLength = (UInt64)[[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
		fileOffset = 0;
		
		aborted = NO;
		
		
		
	}
	return self;
}

- (void)abort
{
	[connection responseDidAbort:self];
	aborted = YES;
}

- (BOOL)openFile
{
	fileFD = open([filePath UTF8String], O_RDONLY);
	if (fileFD == NULL_FD)
	{
		[self abort];
		return NO;
	}
		
	return YES;
}

- (BOOL)openFileIfNeeded
{
	if (aborted)
	{
		
		
		
		return NO;
	}
	
	if (fileFD != NULL_FD)
	{
		
		return YES;
	}
	
	return [self openFile];
}

- (UInt64)contentLength
{
	return fileLength;
}

- (UInt64)offset
{
	return fileOffset;
}

- (void)setOffset:(UInt64)offset
{
	if (![self openFileIfNeeded])
	{
		
		
		return;
	}
	
	fileOffset = offset;
	
	off_t result = lseek(fileFD, (off_t)offset, SEEK_SET);
	if (result == -1)
	{		
		[self abort];
	}
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	if (![self openFileIfNeeded])
	{
		
		
		return nil;
	}
	
	
	
	
	
	
	UInt64 bytesLeftInFile = fileLength - fileOffset;
	
	NSUInteger bytesToRead = (NSUInteger)MIN(length, bytesLeftInFile);
	
	
	
	
	if (buffer == NULL || bufferSize < bytesToRead)
	{
		bufferSize = bytesToRead;
		buffer = reallocf(buffer, (size_t)bufferSize);
		
		if (buffer == NULL)
		{
			[self abort];
			return nil;
		}
	}
	
	
		
	ssize_t result = read(fileFD, buffer, bytesToRead);
	
	
	
	if (result < 0)
	{
		[self abort];
		return nil;
	}
	else if (result == 0)
	{
		[self abort];
		return nil;
	}
	else 
	{
		fileOffset += result;
		
		return [NSData dataWithBytes:buffer length:result];
	}
}

- (BOOL)isDone
{
	BOOL result = (fileOffset == fileLength);
		
	return result;
}

- (NSString *)filePath
{
	return filePath;
}

- (void)dealloc
{
	if (fileFD != NULL_FD)
	{
		close(fileFD);
	}
	
	if (buffer)
		free(buffer);
}

@end
