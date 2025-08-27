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
#import <Security/Security.h>
#import <Security/SecureTransport.h>
#import <dispatch/dispatch.h>

@class GrowingGCDAsyncReadPacket;
@class GrowingGCDAsyncWritePacket;
@class GrowingGCDAsyncSocketPreBuffer;

#if TARGET_OS_IPHONE

  

  #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000 
  
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= 50000 

      #define IS_SECURE_TRANSPORT_AVAILABLE      YES
      #define SECURE_TRANSPORT_MAYBE_AVAILABLE   1
      #define SECURE_TRANSPORT_MAYBE_UNAVAILABLE 0

    #else                                         

      #ifndef NSFoundationVersionNumber_iPhoneOS_5_0
        #define NSFoundationVersionNumber_iPhoneOS_5_0 881.00
      #endif

      #define IS_SECURE_TRANSPORT_AVAILABLE     (NSFoundationVersionNumber >= NSFoundationVersionNumber_iPhoneOS_5_0)
      #define SECURE_TRANSPORT_MAYBE_AVAILABLE   1
      #define SECURE_TRANSPORT_MAYBE_UNAVAILABLE 1

    #endif

  #else                                        

    #define IS_SECURE_TRANSPORT_AVAILABLE      NO
    #define SECURE_TRANSPORT_MAYBE_AVAILABLE   0
    #define SECURE_TRANSPORT_MAYBE_UNAVAILABLE 1

  #endif

#else

  

  #define IS_SECURE_TRANSPORT_AVAILABLE      YES
  #define SECURE_TRANSPORT_MAYBE_AVAILABLE   1
  #define SECURE_TRANSPORT_MAYBE_UNAVAILABLE 0

#endif

extern NSString *const GrowingGCDAsyncSocketException;
extern NSString *const GrowingGCDAsyncSocketErrorDomain;

extern NSString *const GrowingGCDAsyncSocketQueueName;
extern NSString *const GrowingGCDAsyncSocketThreadName;

#if SECURE_TRANSPORT_MAYBE_AVAILABLE
extern NSString *const GrowingGCDAsyncSocketSSLCipherSuites;
#if TARGET_OS_IPHONE
extern NSString *const GrowingGCDAsyncSocketSSLProtocolVersionMin;
extern NSString *const GrowingGCDAsyncSocketSSLProtocolVersionMax;
#else
extern NSString *const GrowingGCDAsyncSocketSSLDiffieHellmanParameters;
#endif
#endif

enum GrowingGCDAsyncSocketError
{
	GrowingGCDAsyncSocketNoError = 0,           
	GrowingGCDAsyncSocketBadConfigError,        
	GrowingGCDAsyncSocketBadParamError,         
	GrowingGCDAsyncSocketConnectTimeoutError,   
	GrowingGCDAsyncSocketReadTimeoutError,      
	GrowingGCDAsyncSocketWriteTimeoutError,     
	GrowingGCDAsyncSocketReadMaxedOutError,     
	GrowingGCDAsyncSocketClosedError,           
	GrowingGCDAsyncSocketOtherError,            
};
typedef enum GrowingGCDAsyncSocketError GrowingGCDAsyncSocketError;


#pragma mark -


@interface GrowingGCDAsyncSocket : NSObject


- (id)init;
- (id)initWithSocketQueue:(dispatch_queue_t)sq;
- (id)initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq;
- (id)initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq;

#pragma mark Configuration

- (id)delegate;
- (void)setDelegate:(id)delegate;
- (void)synchronouslySetDelegate:(id)delegate;

- (dispatch_queue_t)delegateQueue;
- (void)setDelegateQueue:(dispatch_queue_t)delegateQueue;
- (void)synchronouslySetDelegateQueue:(dispatch_queue_t)delegateQueue;

- (void)getDelegate:(id *)delegatePtr delegateQueue:(dispatch_queue_t *)delegateQueuePtr;
- (void)setDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)synchronouslySetDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;


- (BOOL)isIPv4Enabled;
- (void)setIPv4Enabled:(BOOL)flag;

- (BOOL)isIPv6Enabled;
- (void)setIPv6Enabled:(BOOL)flag;

- (BOOL)isIPv4PreferredOverIPv6;
- (void)setPreferIPv4OverIPv6:(BOOL)flag;


- (id)userData;
- (void)setUserData:(id)arbitraryUserData;

#pragma mark Accepting


- (BOOL)acceptOnPort:(uint16_t)port error:(NSError **)errPtr;


- (BOOL)acceptOnInterface:(NSString *)interface port:(uint16_t)port error:(NSError **)errPtr;

#pragma mark Connecting


- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port error:(NSError **)errPtr;


- (BOOL)connectToHost:(NSString *)host
               onPort:(uint16_t)port
          withTimeout:(NSTimeInterval)timeout
                error:(NSError **)errPtr;


- (BOOL)connectToHost:(NSString *)host
               onPort:(uint16_t)port
         viaInterface:(NSString *)interface
          withTimeout:(NSTimeInterval)timeout
                error:(NSError **)errPtr;


- (BOOL)connectToAddress:(NSData *)remoteAddr error:(NSError **)errPtr;


- (BOOL)connectToAddress:(NSData *)remoteAddr withTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr;


- (BOOL)connectToAddress:(NSData *)remoteAddr
            viaInterface:(NSString *)interface
             withTimeout:(NSTimeInterval)timeout
                   error:(NSError **)errPtr;

#pragma mark Disconnecting


- (void)disconnect;


- (void)disconnectAfterReading;


- (void)disconnectAfterWriting;


- (void)disconnectAfterReadingAndWriting;

#pragma mark Diagnostics


- (BOOL)isDisconnected;
- (BOOL)isConnected;


- (NSString *)connectedHost;
- (uint16_t)connectedPort;

- (NSString *)localHost;
- (uint16_t)localPort;


- (NSData *)connectedAddress;
- (NSData *)localAddress;


- (BOOL)isIPv4;
- (BOOL)isIPv6;


- (BOOL)isSecure;

#pragma mark Reading















- (void)readDataWithTimeout:(NSTimeInterval)timeout tag:(long)tag;


- (void)readDataWithTimeout:(NSTimeInterval)timeout
					 buffer:(NSMutableData *)buffer
			   bufferOffset:(NSUInteger)offset
						tag:(long)tag;


- (void)readDataWithTimeout:(NSTimeInterval)timeout
                     buffer:(NSMutableData *)buffer
               bufferOffset:(NSUInteger)offset
                  maxLength:(NSUInteger)length
                        tag:(long)tag;


- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;


- (void)readDataToLength:(NSUInteger)length
             withTimeout:(NSTimeInterval)timeout
                  buffer:(NSMutableData *)buffer
            bufferOffset:(NSUInteger)offset
                     tag:(long)tag;


- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;


- (void)readDataToData:(NSData *)data
           withTimeout:(NSTimeInterval)timeout
                buffer:(NSMutableData *)buffer
          bufferOffset:(NSUInteger)offset
                   tag:(long)tag;


- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout maxLength:(NSUInteger)length tag:(long)tag;


- (void)readDataToData:(NSData *)data
           withTimeout:(NSTimeInterval)timeout
                buffer:(NSMutableData *)buffer
          bufferOffset:(NSUInteger)offset
             maxLength:(NSUInteger)length
                   tag:(long)tag;


- (float)progressOfReadReturningTag:(long *)tagPtr bytesDone:(NSUInteger *)donePtr total:(NSUInteger *)totalPtr;

#pragma mark Writing


- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;


- (float)progressOfWriteReturningTag:(long *)tagPtr bytesDone:(NSUInteger *)donePtr total:(NSUInteger *)totalPtr;

#pragma mark Security


- (void)startTLS:(NSDictionary *)tlsSettings;

#pragma mark Advanced


- (BOOL)autoDisconnectOnClosedReadStream;
- (void)setAutoDisconnectOnClosedReadStream:(BOOL)flag;


- (void)markSocketQueueTargetQueue:(dispatch_queue_t)socketQueuesPreConfiguredTargetQueue;
- (void)unmarkSocketQueueTargetQueue:(dispatch_queue_t)socketQueuesPreviouslyConfiguredTargetQueue;


- (void)performBlock:(dispatch_block_t)block;


- (int)socketFD;
- (int)socket4FD;
- (int)socket6FD;

#if TARGET_OS_IPHONE


- (CFReadStreamRef)readStream;
- (CFWriteStreamRef)writeStream;


- (BOOL)enableBackgroundingOnSocket;

#endif

#if SECURE_TRANSPORT_MAYBE_AVAILABLE


- (SSLContextRef)sslContext;

#endif

#pragma mark Utilities


+ (NSString *)hostFromAddress:(NSData *)address;
+ (uint16_t)portFromAddress:(NSData *)address;
+ (BOOL)getHost:(NSString **)hostPtr port:(uint16_t *)portPtr fromAddress:(NSData *)address;


+ (NSData *)CRLFData;   
+ (NSData *)CRData;     
+ (NSData *)LFData;     
+ (NSData *)ZeroData;   

@end


#pragma mark -


@protocol GrowingGCDAsyncSocketDelegate
@optional


- (dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GrowingGCDAsyncSocket *)sock;


- (void)socket:(GrowingGCDAsyncSocket *)sock didAcceptNewSocket:(GrowingGCDAsyncSocket *)newSocket;


- (void)socket:(GrowingGCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port;


- (void)socket:(GrowingGCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;


- (void)socket:(GrowingGCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag;


- (void)socket:(GrowingGCDAsyncSocket *)sock didWriteDataWithTag:(long)tag;


- (void)socket:(GrowingGCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag;


- (NSTimeInterval)socket:(GrowingGCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                                                                 elapsed:(NSTimeInterval)elapsed
                                                               bytesDone:(NSUInteger)length;


- (NSTimeInterval)socket:(GrowingGCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                                                                  elapsed:(NSTimeInterval)elapsed
                                                                bytesDone:(NSUInteger)length;


- (void)socketDidCloseReadStream:(GrowingGCDAsyncSocket *)sock;


- (void)socketDidDisconnect:(GrowingGCDAsyncSocket *)sock withError:(NSError *)err;


- (void)socketDidSecure:(GrowingGCDAsyncSocket *)sock;

@end
