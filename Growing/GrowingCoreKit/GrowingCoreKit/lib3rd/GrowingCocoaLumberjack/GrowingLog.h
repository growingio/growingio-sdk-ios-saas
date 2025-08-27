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


#if __has_include(<CocoaLumberjack/GrowingLegacyMacros.h>)
    
    #ifndef Growing_LEGACY_MACROS
        #define Growing_LEGACY_MACROS 1
    #endif
    
    #import "GrowingLegacyMacros.h"
#endif


#import "GrowingLoggerNames.h"

#if OS_OBJECT_USE_OBJC
    #define DISPATCH_QUEUE_REFERENCE_TYPE strong
#else
    #define DISPATCH_QUEUE_REFERENCE_TYPE assign
#endif

@class GrowingLogMessage;
@class GrowingLoggerInformation;
@protocol GrowingLogger;
@protocol GrowingLogFormatter;

NS_ASSUME_NONNULL_BEGIN




typedef NS_OPTIONS(NSUInteger, GrowingLogFlag){
    
    GrowingLogFlagError      = (1 << 0),

    
    GrowingLogFlagWarning    = (1 << 1),

    
    GrowingLogFlagInfo       = (1 << 2),

    
    GrowingLogFlagDebug      = (1 << 3),

    
    GrowingLogFlagVerbose    = (1 << 4)
};


typedef NS_ENUM(NSUInteger, GrowingLogLevel){
    
    GrowingLogLevelOff       = 0,

    
    GrowingLogLevelError     = (GrowingLogFlagError),

    
    GrowingLogLevelWarning   = (GrowingLogLevelError   | GrowingLogFlagWarning),

    
    GrowingLogLevelInfo      = (GrowingLogLevelWarning | GrowingLogFlagInfo),

    
    GrowingLogLevelDebug     = (GrowingLogLevelInfo    | GrowingLogFlagDebug),

    
    GrowingLogLevelVerbose   = (GrowingLogLevelDebug   | GrowingLogFlagVerbose),

    
    GrowingLogLevelAll       = NSUIntegerMax
};


FOUNDATION_EXTERN NSString * __nullable GrowingExtractFileNameWithoutExtension(const char *filePath, BOOL copy);


#define GIO_THIS_FILE         (GrowingExtractFileNameWithoutExtension(__FILE__, NO))


#define GIO_THIS_METHOD       NSStringFromSelector(_cmd)



#pragma mark -



@interface GrowingLog : NSObject


@property (class, nonatomic, strong, readonly) GrowingLog *sharedInstance;


@property (class, nonatomic, DISPATCH_QUEUE_REFERENCE_TYPE, readonly) dispatch_queue_t loggingQueue;


+ (void)log:(BOOL)asynchronous
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(nullable const char *)function
       line:(NSUInteger)line
        tag:(nullable id)tag
     format:(NSString *)format, ... NS_FORMAT_FUNCTION(9,10);


- (void)log:(BOOL)asynchronous
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(nullable const char *)function
       line:(NSUInteger)line
        tag:(nullable id)tag
     format:(NSString *)format, ... NS_FORMAT_FUNCTION(9,10);


+ (void)log:(BOOL)asynchronous
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(nullable const char *)function
       line:(NSUInteger)line
        tag:(nullable id)tag
     format:(NSString *)format
       args:(va_list)argList NS_SWIFT_NAME(log(asynchronous:level:flag:context:file:function:line:tag:format:arguments:));


- (void)log:(BOOL)asynchronous
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(nullable const char *)function
       line:(NSUInteger)line
        tag:(nullable id)tag
     format:(NSString *)format
       args:(va_list)argList NS_SWIFT_NAME(log(asynchronous:level:flag:context:file:function:line:tag:format:arguments:));


+ (void)log:(BOOL)asynchronous
    message:(GrowingLogMessage *)logMessage NS_SWIFT_NAME(log(asynchronous:message:));


- (void)log:(BOOL)asynchronous
    message:(GrowingLogMessage *)logMessage NS_SWIFT_NAME(log(asynchronous:message:));


+ (void)flushLog;


- (void)flushLog;




+ (void)addLogger:(id <GrowingLogger>)logger;


- (void)addLogger:(id <GrowingLogger>)logger;


+ (void)addLogger:(id <GrowingLogger>)logger withLevel:(GrowingLogLevel)level;


- (void)addLogger:(id <GrowingLogger>)logger withLevel:(GrowingLogLevel)level;


+ (void)removeLogger:(id <GrowingLogger>)logger;


- (void)removeLogger:(id <GrowingLogger>)logger;


+ (void)removeAllLoggers;


- (void)removeAllLoggers;


@property (class, nonatomic, copy, readonly) NSArray<id<GrowingLogger>> *allLoggers;


@property (nonatomic, copy, readonly) NSArray<id<GrowingLogger>> *allLoggers;


@property (class, nonatomic, copy, readonly) NSArray<GrowingLoggerInformation *> *allLoggersWithLevel;


@property (nonatomic, copy, readonly) NSArray<GrowingLoggerInformation *> *allLoggersWithLevel;




@property (class, nonatomic, copy, readonly) NSArray<Class> *registeredClasses;


@property (class, nonatomic, copy, readonly) NSArray<NSString*> *registeredClassNames;


+ (GrowingLogLevel)levelForClass:(Class)aClass;


+ (GrowingLogLevel)levelForClassWithName:(NSString *)aClassName;


+ (void)setLevel:(GrowingLogLevel)level forClass:(Class)aClass;


+ (void)setLevel:(GrowingLogLevel)level forClassWithName:(NSString *)aClassName;

@end


#pragma mark -



@protocol GrowingLogger <NSObject>


- (void)logMessage:(GrowingLogMessage *)logMessage NS_SWIFT_NAME(log(message:));


@property (nonatomic, strong, nullable) id <GrowingLogFormatter> logFormatter;

@optional


- (void)didAddLogger;


- (void)didAddLoggerInQueue:(dispatch_queue_t)queue;


- (void)willRemoveLogger;


- (void)flush;


@property (nonatomic, DISPATCH_QUEUE_REFERENCE_TYPE, readonly) dispatch_queue_t loggerQueue;


@property (copy, nonatomic, readonly) GrowingLoggerName loggerName;

@end


#pragma mark -



@protocol GrowingLogFormatter <NSObject>
@required


- (nullable NSString *)formatLogMessage:(GrowingLogMessage *)logMessage NS_SWIFT_NAME(format(message:));

@optional


- (void)didAddToLogger:(id <GrowingLogger>)logger;


- (void)didAddToLogger:(id <GrowingLogger>)logger inQueue:(dispatch_queue_t)queue;


- (void)willRemoveFromLogger:(id <GrowingLogger>)logger;

@end


#pragma mark -



@protocol GrowingRegisteredDynamicLogging


@property (class, nonatomic, readwrite, setter=gioSetLogLevel:) GrowingLogLevel gioLogLevel;

@end


#pragma mark -


#ifndef NS_DESIGNATED_INITIALIZER
    #define NS_DESIGNATED_INITIALIZER
#endif


typedef NS_OPTIONS(NSInteger, GrowingLogMessageOptions){
    
    GrowingLogMessageCopyFile        = 1 << 0,
    
    GrowingLogMessageCopyFunction    = 1 << 1,
    
    GrowingLogMessageDontCopyMessage = 1 << 2
};


@interface GrowingLogMessage : NSObject <NSCopying>
{
    
    @public
    NSString *_message;
    GrowingLogLevel _level;
    GrowingLogFlag _flag;
    NSInteger _context;
    NSString *_file;
    NSString *_fileName;
    NSString *_function;
    NSUInteger _line;
    id _tag;
    GrowingLogMessageOptions _options;
    NSDate * _timestamp;
    NSString *_threadID;
    NSString *_threadName;
    NSString *_queueLabel;
    NSUInteger _qos;
}


- (instancetype)init NS_DESIGNATED_INITIALIZER;


- (instancetype)initWithMessage:(NSString *)message
                          level:(GrowingLogLevel)level
                           flag:(GrowingLogFlag)flag
                        context:(NSInteger)context
                           file:(NSString *)file
                       function:(nullable NSString *)function
                           line:(NSUInteger)line
                            tag:(nullable id)tag
                        options:(GrowingLogMessageOptions)options
                      timestamp:(nullable NSDate *)timestamp NS_DESIGNATED_INITIALIZER;




@property (readonly, nonatomic) NSString *message;
@property (readonly, nonatomic) GrowingLogLevel level;
@property (readonly, nonatomic) GrowingLogFlag flag;
@property (readonly, nonatomic) NSInteger context;
@property (readonly, nonatomic) NSString *file;
@property (readonly, nonatomic) NSString *fileName;
@property (readonly, nonatomic, nullable) NSString * function;
@property (readonly, nonatomic) NSUInteger line;
@property (readonly, nonatomic, nullable) id tag;
@property (readonly, nonatomic) GrowingLogMessageOptions options;
@property (readonly, nonatomic) NSDate *timestamp;
@property (readonly, nonatomic) NSString *threadID; 
@property (readonly, nonatomic, nullable) NSString *threadName;
@property (readonly, nonatomic) NSString *queueLabel;
@property (readonly, nonatomic) NSUInteger qos API_AVAILABLE(macos(10.10), ios(8.0));

@end


#pragma mark -



@interface GrowingAbstractLogger : NSObject <GrowingLogger>
{
    
    @public
    id <GrowingLogFormatter> _logFormatter;
    dispatch_queue_t _loggerQueue;
}

@property (nonatomic, strong, nullable) id <GrowingLogFormatter> logFormatter;
@property (nonatomic, DISPATCH_QUEUE_REFERENCE_TYPE) dispatch_queue_t loggerQueue;




@property (nonatomic, readonly, getter=isOnGlobalLoggingQueue)  BOOL onGlobalLoggingQueue;


@property (nonatomic, readonly, getter=isOnInternalLoggerQueue) BOOL onInternalLoggerQueue;

@end


#pragma mark -


@interface GrowingLoggerInformation : NSObject

@property (nonatomic, readonly) id <GrowingLogger> logger;
@property (nonatomic, readonly) GrowingLogLevel level;

+ (instancetype)informationWithLogger:(id <GrowingLogger>)logger
                             andLevel:(GrowingLogLevel)level;

@end

NS_ASSUME_NONNULL_END
