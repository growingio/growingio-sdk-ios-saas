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


#import "GrowingHTTPAsyncFileResponse.h"
#import "GrowingHTTPConnection.h"
#import "GrowingHTTPLogging.h"

#import <unistd.h>
#import <fcntl.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#define NULL_FD  -1



@implementation GrowingHTTPAsyncFileResponse

- (id)initWithFilePath:(NSString *)fpath forConnection:(GrowingHTTPConnection *)parent
{
	if ((self = [super init]))
	{
		connection = parent; 
		
		fileFD = NULL_FD;
		filePath = [fpath copy];
		if (filePath == nil)
		{
			return nil;
		}
		
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
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

- (void)processReadBuffer
{
	
	
	
	
	
	
	
	
	data = [[NSData alloc] initWithBytes:readBuffer length:readBufferOffset];
	
	
	readBufferOffset = 0;
	
	
	[connection responseHasAvailableData:self];
}

- (void)pauseReadSource
{
	if (!readSourceSuspended)
	{
		readSourceSuspended = YES;
		dispatch_suspend(readSource);
	}
}

- (void)resumeReadSource
{
	if (readSourceSuspended)
	{
		readSourceSuspended = NO;
		dispatch_resume(readSource);
	}
}

- (void)cancelReadSource
{
	dispatch_source_cancel(readSource);
	
	
	
	
	if (readSourceSuspended)
	{
		readSourceSuspended = NO;
		dispatch_resume(readSource);
	}
}

- (BOOL)openFileAndSetupReadSource
{
	
	fileFD = open([filePath UTF8String], (O_RDONLY | O_NONBLOCK));
	if (fileFD == NULL_FD)
	{
		return NO;
	}
		
	readQueue = dispatch_queue_create("GrowingHTTPAsyncFileResponse", NULL);
	readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fileFD, 0, readQueue);
	
	
	dispatch_source_set_event_handler(readSource, ^{
		
		
		
		
		
		
		
		unsigned long long _bytesAvailableOnFD = dispatch_source_get_data(readSource);
		
		UInt64 _bytesLeftInFile = fileLength - readOffset;
		
		NSUInteger bytesAvailableOnFD;
		NSUInteger bytesLeftInFile;
		
		bytesAvailableOnFD = (_bytesAvailableOnFD > NSUIntegerMax) ? NSUIntegerMax : (NSUInteger)_bytesAvailableOnFD;
		bytesLeftInFile    = (_bytesLeftInFile    > NSUIntegerMax) ? NSUIntegerMax : (NSUInteger)_bytesLeftInFile;
		
		NSUInteger bytesLeftInRequest = readRequestLength - readBufferOffset;
		
		NSUInteger bytesLeft = MIN(bytesLeftInRequest, bytesLeftInFile);
		
		NSUInteger bytesToRead = MIN(bytesAvailableOnFD, bytesLeft);
		
		
		
		
		if (readBuffer == NULL || bytesToRead > (readBufferSize - readBufferOffset))
		{
			readBufferSize = bytesToRead;
			readBuffer = reallocf(readBuffer, (size_t)bytesToRead);
			
			if (readBuffer == NULL)
			{
				[self pauseReadSource];
				[self abort];
				
				return;
			}
		}
		
		
				
		ssize_t result = read(fileFD, readBuffer + readBufferOffset, (size_t)bytesToRead);
		
		
		if (result < 0)
		{
			
			[self pauseReadSource];
			[self abort];
		}
		else if (result == 0)
		{
			
			[self pauseReadSource];
			[self abort];
		}
		else 
		{
			
			readOffset += result;
			readBufferOffset += result;
			
			[self pauseReadSource];
			[self processReadBuffer];
		}
		
	});
	
	int theFileFD = fileFD;
	#if !OS_OBJECT_USE_OBJC
	dispatch_source_t theReadSource = readSource;
	#endif
	
	dispatch_source_set_cancel_handler(readSource, ^{
		
		
		
		
		
		
		#if !OS_OBJECT_USE_OBJC
		dispatch_release(theReadSource);
		#endif
		close(theFileFD);
	});
	
	readSourceSuspended = YES;
	
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
	
	return [self openFileAndSetupReadSource];
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
	readOffset = offset;
	
	off_t result = lseek(fileFD, (off_t)offset, SEEK_SET);
	if (result == -1)
	{
		
		[self abort];
	}
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	
	if (data)
	{
		NSUInteger dataLength = [data length];
				
		fileOffset += dataLength;
		
		NSData *result = data;
		data = nil;
		
		return result;
	}
	else
	{
		if (![self openFileIfNeeded])
		{
			
			
			return nil;
		}
		
		dispatch_sync(readQueue, ^{
			
			NSAssert(readSourceSuspended, @"Invalid logic - perhaps GrowingHTTPConnection has changed.");
			
			readRequestLength = length;
			[self resumeReadSource];
		});
		
		return nil;
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

- (BOOL)isAsynchronous
{
	return YES;
}

- (void)connectionDidClose
{
	if (fileFD != NULL_FD)
	{
		dispatch_sync(readQueue, ^{
			
			
			connection = nil;
			
			
			
			
			
			[self cancelReadSource];
		});
	}
}

- (void)dealloc
{
	
	#if !OS_OBJECT_USE_OBJC
	if (readQueue) dispatch_release(readQueue);
	#endif
	
	if (readBuffer)
		free(readBuffer);
}

@end
