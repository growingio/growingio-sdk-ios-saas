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


#ifndef Growing_LEGACY_MACROS
    #define Growing_LEGACY_MACROS 0
#endif

#import "GrowingLog.h"

#import <pthread.h>
#import <objc/runtime.h>
#import <sys/qos.h>

#if TARGET_OS_IOS
    #import <UIKit/UIDevice.h>
    #import <UIKit/UIApplication.h>
#elif !defined(Growing_CLI) && __has_include(<AppKit/NSApplication.h>)
    #import <AppKit/NSApplication.h>
#endif


#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif








#ifndef Growing_DEBUG
    #define Growing_DEBUG 0
#endif

#define NSLogDebug(frmt, ...) do{ if(Growing_DEBUG) NSLog((frmt), ##__VA_ARGS__); } while(0)












#ifndef GrowingLOG_MAX_QUEUE_SIZE
    #define GrowingLOG_MAX_QUEUE_SIZE 1000 
#endif







static void *const GlobalLoggingQueueIdentityKey = (void *)&GlobalLoggingQueueIdentityKey;

@interface GrowingLoggerNode : NSObject
{
    
    @public
    id <GrowingLogger> _logger;
    GrowingLogLevel _level;
    dispatch_queue_t _loggerQueue;
}

@property (nonatomic, readonly) id <GrowingLogger> logger;
@property (nonatomic, readonly) GrowingLogLevel level;
@property (nonatomic, readonly) dispatch_queue_t loggerQueue;

+ (instancetype)nodeWithLogger:(id <GrowingLogger>)logger
                   loggerQueue:(dispatch_queue_t)loggerQueue
                         level:(GrowingLogLevel)level;

@end



#pragma mark -


@interface GrowingLog ()



@property (nonatomic, strong) NSMutableArray *_loggers;

@end

@implementation GrowingLog


static dispatch_queue_t _loggingQueue;



static dispatch_group_t _loggingGroup;



static dispatch_semaphore_t _queueSemaphore;


static NSUInteger _numProcessors;


+ (instancetype)sharedInstance {
    static id sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}


+ (void)initialize {
    static dispatch_once_t GrowingLogOnceToken;

    dispatch_once(&GrowingLogOnceToken, ^{
        NSLogDebug(@"GrowingLog: Using grand central dispatch");

        _loggingQueue = dispatch_queue_create("growing.cocoaLumberjack", NULL);
        _loggingGroup = dispatch_group_create();

        void *nonNullValue = GlobalLoggingQueueIdentityKey; 
        dispatch_queue_set_specific(_loggingQueue, GlobalLoggingQueueIdentityKey, nonNullValue, NULL);

        _queueSemaphore = dispatch_semaphore_create(GrowingLOG_MAX_QUEUE_SIZE);

        
        

        _numProcessors = MAX([NSProcessInfo processInfo].processorCount, (NSUInteger) 1);

        NSLogDebug(@"GrowingLog: numProcessors = %@", @(_numProcessors));
    });
}


- (instancetype)init {
    self = [super init];

    if (self) {
        self._loggers = [[NSMutableArray alloc] initWithCapacity:4];

#if TARGET_OS_IOS
        NSString *notificationName = UIApplicationWillTerminateNotification;
#else
        NSString *notificationName = nil;

        
#if !defined(Growing_CLI) && __has_include(<AppKit/NSApplication.h>)
        if (NSApp) {
            notificationName = NSApplicationWillTerminateNotification;
        }
#endif

        if (!notificationName) {
            
            
            __weak __auto_type weakSelf = self;
            atexit_b (^{
                [weakSelf applicationWillTerminate:nil];
            });
        }

#endif 

        if (notificationName) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillTerminate:)
                                                         name:notificationName
                                                       object:nil];
        }
    }

    return self;
}


+ (dispatch_queue_t)loggingQueue {
    return _loggingQueue;
}


#pragma mark Notifications


- (void)applicationWillTerminate:(NSNotification * __attribute__((unused)))notification {
    [self flushLog];
}


#pragma mark Logger Management


+ (void)addLogger:(id <GrowingLogger>)logger {
    [self.sharedInstance addLogger:logger];
}

- (void)addLogger:(id <GrowingLogger>)logger {
    [self addLogger:logger withLevel:GrowingLogLevelAll]; 
}

+ (void)addLogger:(id <GrowingLogger>)logger withLevel:(GrowingLogLevel)level {
    [self.sharedInstance addLogger:logger withLevel:level];
}

- (void)addLogger:(id <GrowingLogger>)logger withLevel:(GrowingLogLevel)level {
    if (!logger) {
        return;
    }

    dispatch_async(_loggingQueue, ^{ @autoreleasepool {
        [self lt_addLogger:logger level:level];
    } });
}

+ (void)removeLogger:(id <GrowingLogger>)logger {
    [self.sharedInstance removeLogger:logger];
}

- (void)removeLogger:(id <GrowingLogger>)logger {
    if (!logger) {
        return;
    }

    dispatch_async(_loggingQueue, ^{ @autoreleasepool {
        [self lt_removeLogger:logger];
    } });
}

+ (void)removeAllLoggers {
    [self.sharedInstance removeAllLoggers];
}

- (void)removeAllLoggers {
    dispatch_async(_loggingQueue, ^{ @autoreleasepool {
        [self lt_removeAllLoggers];
    } });
}

+ (NSArray<id<GrowingLogger>> *)allLoggers {
    return [self.sharedInstance allLoggers];
}

- (NSArray<id<GrowingLogger>> *)allLoggers {
    __block NSArray *theLoggers;

    dispatch_sync(_loggingQueue, ^{ @autoreleasepool {
        theLoggers = [self lt_allLoggers];
    } });

    return theLoggers;
}

+ (NSArray<GrowingLoggerInformation *> *)allLoggersWithLevel {
    return [self.sharedInstance allLoggersWithLevel];
}

- (NSArray<GrowingLoggerInformation *> *)allLoggersWithLevel {
    __block NSArray *theLoggersWithLevel;

    dispatch_sync(_loggingQueue, ^{ @autoreleasepool {
        theLoggersWithLevel = [self lt_allLoggersWithLevel];
    } });

    return theLoggersWithLevel;
}


#pragma mark - Master Logging


- (void)queueLogMessage:(GrowingLogMessage *)logMessage asynchronously:(BOOL)asyncFlag {
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    


    
    
    
    
    
    
    
    
    

    dispatch_block_t logBlock = ^{
        dispatch_semaphore_wait(_queueSemaphore, DISPATCH_TIME_FOREVER);
        
        
        @autoreleasepool {
            [self lt_log:logMessage];
        }
    };

    if (asyncFlag) {
        dispatch_async(_loggingQueue, logBlock);
    } else if (dispatch_get_specific(GlobalLoggingQueueIdentityKey)) {
        
        logBlock();
    } else {
        dispatch_sync(_loggingQueue, logBlock);
    }
}

+ (void)log:(BOOL)asynchronous
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ... {
    va_list args;

    if (format) {
        va_start(args, format);

        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];

        va_end(args);

        va_start(args, format);

        [self log:asynchronous
          message:message
            level:level
             flag:flag
          context:context
             file:file
         function:function
             line:line
              tag:tag];

        va_end(args);
    }
}

- (void)log:(BOOL)asynchronous
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ... {
    va_list args;

    if (format) {
        va_start(args, format);

        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];

        va_end(args);

        va_start(args, format);

        [self log:asynchronous
          message:message
            level:level
             flag:flag
          context:context
             file:file
         function:function
             line:line
              tag:tag];

        va_end(args);
    }
}

+ (void)log:(BOOL)asynchronous
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format
       args:(va_list)args {
    [self.sharedInstance log:asynchronous level:level flag:flag context:context file:file function:function line:line tag:tag format:format args:args];
}

- (void)log:(BOOL)asynchronous
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format
       args:(va_list)args {
    if (format) {
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        [self log:asynchronous
          message:message
            level:level
             flag:flag
          context:context
             file:file
         function:function
             line:line
              tag:tag];
    }
}

+ (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag {
    [self.sharedInstance log:asynchronous message:message level:level flag:flag context:context file:file function:function line:line tag:tag];
}

- (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(GrowingLogLevel)level
       flag:(GrowingLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag {
    GrowingLogMessage *logMessage = [[GrowingLogMessage alloc] initWithMessage:message
                                                               level:level
                                                                flag:flag
                                                             context:context
                                                                file:[NSString stringWithFormat:@"%s", file]
                                                            function:[NSString stringWithFormat:@"%s", function]
                                                                line:line
                                                                 tag:tag
                                                             options:(GrowingLogMessageOptions)0
                                                           timestamp:nil];

    [self queueLogMessage:logMessage asynchronously:asynchronous];
}

+ (void)log:(BOOL)asynchronous message:(GrowingLogMessage *)logMessage {
    [self.sharedInstance log:asynchronous message:logMessage];
}

- (void)log:(BOOL)asynchronous message:(GrowingLogMessage *)logMessage {
    [self queueLogMessage:logMessage asynchronously:asynchronous];
}

+ (void)flushLog {
    [self.sharedInstance flushLog];
}

- (void)flushLog {
    dispatch_sync(_loggingQueue, ^{ @autoreleasepool {
        [self lt_flush];
    } });
}


#pragma mark Registered Dynamic Logging


+ (BOOL)isRegisteredClass:(Class)class {
    SEL getterSel = @selector(gioLogLevel);
    SEL setterSel = @selector(gioSetLogLevel:);

#if TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR

    
    
    
    
    
    
    

    BOOL result = NO;

    unsigned int methodCount, i;
    Method *methodList = class_copyMethodList(object_getClass(class), &methodCount);

    if (methodList != NULL) {
        BOOL getterFound = NO;
        BOOL setterFound = NO;

        for (i = 0; i < methodCount; ++i) {
            SEL currentSel = method_getName(methodList[i]);

            if (currentSel == getterSel) {
                getterFound = YES;
            } else if (currentSel == setterSel) {
                setterFound = YES;
            }

            if (getterFound && setterFound) {
                result = YES;
                break;
            }
        }

        free(methodList);
    }

    return result;

#else 

    
    
    
    

    Method getter = class_getClassMethod(class, getterSel);
    Method setter = class_getClassMethod(class, setterSel);

    if ((getter != NULL) && (setter != NULL)) {
        return YES;
    }

    return NO;

#endif 
}

+ (NSArray *)registeredClasses {

    
    
    
    
    
    
    
    
    
    

    NSUInteger numClasses = 0;
    Class *classes = NULL;

    while (numClasses == 0) {

        numClasses = (NSUInteger)MAX(objc_getClassList(NULL, 0), 0);

        
        

        NSUInteger bufferSize = numClasses;

        classes = numClasses ? (Class *)calloc(bufferSize, sizeof(Class)) : NULL;
        if (classes == NULL) {
            return @[]; 
        }

        numClasses = (NSUInteger)MAX(objc_getClassList(classes, (int)bufferSize),0);

        if (numClasses > bufferSize || numClasses == 0) {
            
            free(classes);
            classes = NULL;
            numClasses = 0;
        }
    }

    

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:numClasses];

    for (NSUInteger i = 0; i < numClasses; i++) {
        Class class = classes[i];

        if ([self isRegisteredClass:class]) {
            [result addObject:class];
        }
    }

    free(classes);

    return result;
}

+ (NSArray *)registeredClassNames {
    NSArray *registeredClasses = [self registeredClasses];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[registeredClasses count]];

    for (Class class in registeredClasses) {
        [result addObject:NSStringFromClass(class)];
    }
    return result;
}

+ (GrowingLogLevel)levelForClass:(Class)aClass {
    if ([self isRegisteredClass:aClass]) {
        return [aClass gioLogLevel];
    }
    return (GrowingLogLevel)-1;
}

+ (GrowingLogLevel)levelForClassWithName:(NSString *)aClassName {
    Class aClass = NSClassFromString(aClassName);

    return [self levelForClass:aClass];
}

+ (void)setLevel:(GrowingLogLevel)level forClass:(Class)aClass {
    if ([self isRegisteredClass:aClass]) {
        [aClass gioSetLogLevel:level];
    }
}

+ (void)setLevel:(GrowingLogLevel)level forClassWithName:(NSString *)aClassName {
    Class aClass = NSClassFromString(aClassName);
    [self setLevel:level forClass:aClass];
}


#pragma mark Logging Thread


- (void)lt_addLogger:(id <GrowingLogger>)logger level:(GrowingLogLevel)level {
    
    

    for (GrowingLoggerNode *node in self._loggers) {
        if (node->_logger == logger
            && node->_level == level) {
            
            return;
        }
    }

    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    dispatch_queue_t loggerQueue = NULL;
    if ([logger respondsToSelector:@selector(loggerQueue)]) {
        
        loggerQueue = logger.loggerQueue;
    }

    if (loggerQueue == nil) {
        
        
        const char *loggerQueueName = NULL;

        if ([logger respondsToSelector:@selector(loggerName)]) {
            loggerQueueName = logger.loggerName.UTF8String;
        }

        loggerQueue = dispatch_queue_create(loggerQueueName, NULL);
    }

    GrowingLoggerNode *loggerNode = [GrowingLoggerNode nodeWithLogger:logger loggerQueue:loggerQueue level:level];
    [self._loggers addObject:loggerNode];

    if ([logger respondsToSelector:@selector(didAddLoggerInQueue:)]) {
        dispatch_async(loggerNode->_loggerQueue, ^{ @autoreleasepool {
            [logger didAddLoggerInQueue:loggerNode->_loggerQueue];
        } });
    } else if ([logger respondsToSelector:@selector(didAddLogger)]) {
        dispatch_async(loggerNode->_loggerQueue, ^{ @autoreleasepool {
            [logger didAddLogger];
        } });
    }
}

- (void)lt_removeLogger:(id <GrowingLogger>)logger {
    

    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    GrowingLoggerNode *loggerNode = nil;

    for (GrowingLoggerNode *node in self._loggers) {
        if (node->_logger == logger) {
            loggerNode = node;
            break;
        }
    }

    if (loggerNode == nil) {
        NSLogDebug(@"GrowingLog: Request to remove logger which wasn't added");
        return;
    }

    
    if ([logger respondsToSelector:@selector(willRemoveLogger)]) {
        dispatch_async(loggerNode->_loggerQueue, ^{ @autoreleasepool {
            [logger willRemoveLogger];
        } });
    }

    
    [self._loggers removeObject:loggerNode];
}

- (void)lt_removeAllLoggers {
    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    
    for (GrowingLoggerNode *loggerNode in self._loggers) {
        if ([loggerNode->_logger respondsToSelector:@selector(willRemoveLogger)]) {
            dispatch_async(loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger willRemoveLogger];
            } });
        }
    }

    

    [self._loggers removeAllObjects];
}

- (NSArray *)lt_allLoggers {
    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    NSMutableArray *theLoggers = [NSMutableArray new];

    for (GrowingLoggerNode *loggerNode in self._loggers) {
        [theLoggers addObject:loggerNode->_logger];
    }

    return [theLoggers copy];
}

- (NSArray *)lt_allLoggersWithLevel {
    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    NSMutableArray *theLoggersWithLevel = [NSMutableArray new];

    for (GrowingLoggerNode *loggerNode in self._loggers) {
        [theLoggersWithLevel addObject:[GrowingLoggerInformation informationWithLogger:loggerNode->_logger
                                                                         andLevel:loggerNode->_level]];
    }

    return [theLoggersWithLevel copy];
}

- (void)lt_log:(GrowingLogMessage *)logMessage {
    

    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    if (_numProcessors > 1) {
        
        
        
        
        
        

        for (GrowingLoggerNode *loggerNode in self._loggers) {
            

            if (!(logMessage->_flag & loggerNode->_level)) {
                continue;
            }

            dispatch_group_async(_loggingGroup, loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger logMessage:logMessage];
            } });
        }

        dispatch_group_wait(_loggingGroup, DISPATCH_TIME_FOREVER);
    } else {
        

        for (GrowingLoggerNode *loggerNode in self._loggers) {
            

            if (!(logMessage->_flag & loggerNode->_level)) {
                continue;
            }

#if Growing_DEBUG
            
            if (loggerNode->_loggerQueue == NULL) {
              
              NSLogDebug(@"GrowingLog: current node has loggerQueue == NULL");
            }
            else {
              dispatch_async(loggerNode->_loggerQueue, ^{
                if (dispatch_get_specific(GlobalLoggingQueueIdentityKey)) {
                  
                  NSLogDebug(@"GrowingLog: current node has loggerQueue == globalLoggingQueue");
                }
              });
            }
#endif
            
            dispatch_sync(loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger logMessage:logMessage];
            } });
        }
    }

    
    

    
    
    
    
    
    
    
    
    
    

    dispatch_semaphore_signal(_queueSemaphore);
}

- (void)lt_flush {
    
    
    
    

    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    for (GrowingLoggerNode *loggerNode in self._loggers) {
        if ([loggerNode->_logger respondsToSelector:@selector(flush)]) {
            dispatch_group_async(_loggingGroup, loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger flush];
            } });
        }
    }

    dispatch_group_wait(_loggingGroup, DISPATCH_TIME_FOREVER);
}


#pragma mark Utilities


NSString * __nullable GrowingExtractFileNameWithoutExtension(const char *filePath, BOOL copy) {
    if (filePath == NULL) {
        return nil;
    }

    char *lastSlash = NULL;
    char *lastDot = NULL;

    char *p = (char *)filePath;

    while (*p != '\0') {
        if (*p == '/') {
            lastSlash = p;
        } else if (*p == '.') {
            lastDot = p;
        }

        p++;
    }

    char *subStr;
    NSUInteger subLen;

    if (lastSlash) {
        if (lastDot) {
            
            subStr = lastSlash + 1;
            subLen = (NSUInteger)(lastDot - subStr);
        } else {
            
            subStr = lastSlash + 1;
            subLen = (NSUInteger)(p - subStr);
        }
    } else {
        if (lastDot) {
            
            subStr = (char *)filePath;
            subLen = (NSUInteger)(lastDot - subStr);
        } else {
            
            subStr = (char *)filePath;
            subLen = (NSUInteger)(p - subStr);
        }
    }

    if (copy) {
        return [[NSString alloc] initWithBytes:subStr
                                        length:subLen
                                      encoding:NSUTF8StringEncoding];
    } else {
        
        
        

        return [[NSString alloc] initWithBytesNoCopy:subStr
                                              length:subLen
                                            encoding:NSUTF8StringEncoding
                                        freeWhenDone:NO];
    }
}

@end


#pragma mark -


@implementation GrowingLoggerNode

- (instancetype)initWithLogger:(id <GrowingLogger>)logger loggerQueue:(dispatch_queue_t)loggerQueue level:(GrowingLogLevel)level {
    if ((self = [super init])) {
        _logger = logger;

        if (loggerQueue) {
            _loggerQueue = loggerQueue;
            #if !OS_OBJECT_USE_OBJC
            dispatch_retain(loggerQueue);
            #endif
        }

        _level = level;
    }
    return self;
}

+ (instancetype)nodeWithLogger:(id <GrowingLogger>)logger loggerQueue:(dispatch_queue_t)loggerQueue level:(GrowingLogLevel)level {
    return [[self alloc] initWithLogger:logger loggerQueue:loggerQueue level:level];
}

- (void)dealloc {
    #if !OS_OBJECT_USE_OBJC
    if (_loggerQueue) {
        dispatch_release(_loggerQueue);
    }
    #endif
}

@end


#pragma mark -


@implementation GrowingLogMessage

- (instancetype)init {
    self = [super init];
    return self;
}

- (instancetype)initWithMessage:(NSString *)message
                          level:(GrowingLogLevel)level
                           flag:(GrowingLogFlag)flag
                        context:(NSInteger)context
                           file:(NSString *)file
                       function:(NSString *)function
                           line:(NSUInteger)line
                            tag:(id)tag
                        options:(GrowingLogMessageOptions)options
                      timestamp:(NSDate *)timestamp {
    if ((self = [super init])) {
        BOOL copyMessage = (options & GrowingLogMessageDontCopyMessage) == 0;
        _message      = copyMessage ? [message copy] : message;
        _level        = level;
        _flag         = flag;
        _context      = context;

        BOOL copyFile = (options & GrowingLogMessageCopyFile) != 0;
        _file = copyFile ? [file copy] : file;

        BOOL copyFunction = (options & GrowingLogMessageCopyFunction) != 0;
        _function = copyFunction ? [function copy] : function;

        _line         = line;
        _tag          = tag;
        _options      = options;
        _timestamp    = timestamp ?: [NSDate new];

        __uint64_t tid;
        if (pthread_threadid_np(NULL, &tid) == 0) {
            _threadID = [[NSString alloc] initWithFormat:@"%llu", tid];
        } else {
            _threadID = @"missing threadId";
        }
        _threadName   = NSThread.currentThread.name;

        
        _fileName = [_file lastPathComponent];
        NSUInteger dotLocation = [_fileName rangeOfString:@"." options:NSBackwardsSearch].location;
        if (dotLocation != NSNotFound)
        {
            _fileName = [_fileName substringToIndex:dotLocation];
        }

        
        _queueLabel = [[NSString alloc] initWithFormat:@"%s", dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];

        if (@available(macOS 10.10, iOS 8.0, *))
            _qos = (NSUInteger) qos_class_self();
    }
    return self;
}

- (id)copyWithZone:(NSZone * __attribute__((unused)))zone {
    GrowingLogMessage *newMessage = [GrowingLogMessage new];

    newMessage->_message = _message;
    newMessage->_level = _level;
    newMessage->_flag = _flag;
    newMessage->_context = _context;
    newMessage->_file = _file;
    newMessage->_fileName = _fileName;
    newMessage->_function = _function;
    newMessage->_line = _line;
    newMessage->_tag = _tag;
    newMessage->_options = _options;
    newMessage->_timestamp = _timestamp;
    newMessage->_threadID = _threadID;
    newMessage->_threadName = _threadName;
    newMessage->_queueLabel = _queueLabel;
    newMessage->_qos = _qos;

    return newMessage;
}

@end



#pragma mark -


@implementation GrowingAbstractLogger

- (instancetype)init {
    if ((self = [super init])) {
        const char *loggerQueueName = NULL;

        if ([self respondsToSelector:@selector(loggerName)]) {
            loggerQueueName = self.loggerName.UTF8String;
        }

        _loggerQueue = dispatch_queue_create(loggerQueueName, NULL);

        
        
        
        
        
        
        
        
        
        
        
        
        

        void *key = (__bridge void *)self;
        void *nonNullValue = (__bridge void *)self;

        dispatch_queue_set_specific(_loggerQueue, key, nonNullValue, NULL);
    }

    return self;
}

- (void)dealloc {
    #if !OS_OBJECT_USE_OBJC

    if (_loggerQueue) {
        dispatch_release(_loggerQueue);
    }

    #endif
}

- (void)logMessage:(GrowingLogMessage * __attribute__((unused)))logMessage {
    
}

- (id <GrowingLogFormatter>)logFormatter {
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

    
    
    
    
    
    
    
    

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [GrowingLog loggingQueue];

    __block id <GrowingLogFormatter> result;

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(self->_loggerQueue, ^{
            result = self->_logFormatter;
        });
    });

    return result;
}

- (void)setLogFormatter:(id <GrowingLogFormatter>)logFormatter {
    

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_block_t block = ^{
        @autoreleasepool {
            if (self->_logFormatter != logFormatter) {
                if ([self->_logFormatter respondsToSelector:@selector(willRemoveFromLogger:)]) {
                    [self->_logFormatter willRemoveFromLogger:self];
                }

                self->_logFormatter = logFormatter;

                if ([self->_logFormatter respondsToSelector:@selector(didAddToLogger:inQueue:)]) {
                    [self->_logFormatter didAddToLogger:self inQueue:self->_loggerQueue];
                } else if ([self->_logFormatter respondsToSelector:@selector(didAddToLogger:)]) {
                    [self->_logFormatter didAddToLogger:self];
                }
            }
        }
    };

    dispatch_async(GrowingLog.loggingQueue, ^{
        dispatch_async(self->_loggerQueue, block);
    });
}

- (dispatch_queue_t)loggerQueue {
    return _loggerQueue;
}

- (NSString *)loggerName {
    return NSStringFromClass([self class]);
}

- (BOOL)isOnGlobalLoggingQueue {
    return (dispatch_get_specific(GlobalLoggingQueueIdentityKey) != NULL);
}

- (BOOL)isOnInternalLoggerQueue {
    void *key = (__bridge void *)self;

    return (dispatch_get_specific(key) != NULL);
}

@end


#pragma mark -


@interface GrowingLoggerInformation()
{
    
    @public
    id <GrowingLogger> _logger;
    GrowingLogLevel _level;
}

@end

@implementation GrowingLoggerInformation

- (instancetype)initWithLogger:(id <GrowingLogger>)logger andLevel:(GrowingLogLevel)level {
    if ((self = [super init])) {
        _logger = logger;
        _level = level;
    }
    return self;
}

+ (instancetype)informationWithLogger:(id <GrowingLogger>)logger andLevel:(GrowingLogLevel)level {
    return [[self alloc] initWithLogger:logger andLevel:level];
}

@end
