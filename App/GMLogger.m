/* Copyright 2009 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#import "GMLogger.h"
#import <fcntl.h>
#import <unistd.h>
#import <stdlib.h>
#import <asl.h>
#import <pthread.h>

// We define a trivial assertion macro here to avoid the dependency on GMLog
#ifdef DEBUG
  #define GMLOGGER_ASSERT(expr) assert(expr)
#else
  #define GMLOGGER_ASSERT(expr)
#endif

@interface GMLogger (PrivateMethods)
- (void)logInternalFunc:(const char *)func
                 format:(NSString *)fmt
                 valist:(va_list)args
                  level:(GMLoggerLevel)level;
@end

// Reference to the shared GMLogger instance. This is not a singleton, it's just
// an easy reference to one shared instance.
static GMLogger *gSharedLogger = nil;

@implementation GMLogger

// Returns a pointer to the shared logger instance. If none exists, a standard
// logger is created and returned.
+ (id)sharedLogger {
  @synchronized(self) {
    if (gSharedLogger == nil) {
      gSharedLogger = [[self standardLogger] retain];
    }
    GMLOGGER_ASSERT(gSharedLogger != nil);
  }
  return [[gSharedLogger retain] autorelease];
}

+ (void)setSharedLogger:(GMLogger *)logger {
  @synchronized(self) {
    [gSharedLogger autorelease];
    gSharedLogger = [logger retain];
  }
}

+ (id)standardLogger {
  id<GMLogWriter> writer = [NSFileHandle fileHandleWithStandardOutput];
  id<GMLogFormatter> fmtr = [[[GMLogStandardFormatter alloc] init] autorelease];
  id<GMLogFilter> filter = [[[GMLogLevelFilter alloc] init] autorelease];
  return [self loggerWithWriter:writer formatter:fmtr filter:filter];
}

+ (id)standardLoggerWithStderr {
  id me = [self standardLogger];
  [me setWriter:[NSFileHandle fileHandleWithStandardError]];
  return me;
}

+ (id)standardLoggerWithASL {
  id me = [self standardLogger];
  [me setWriter:[[[GMLogASLWriter alloc] init] autorelease]];
  [me setFormatter:[[[GMLogBasicFormatter alloc] init] autorelease]];
  return me;
}

+ (id)standardLoggerWithPath:(NSString *)path {
  NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path create:YES];
  if (fh == nil) return nil;
  id me = [self standardLogger];
  [me setWriter:fh];
  return me;
}

+ (id)loggerWithWriter:(id<GMLogWriter>)writer
             formatter:(id<GMLogFormatter>)formatter
                filter:(id<GMLogFilter>)filter {
  return [[[self alloc] initWithWriter:writer
                             formatter:formatter
                                filter:filter] autorelease];
}

+ (id)logger {
  return [[[self alloc] init] autorelease];
}

- (id)init {
  return [self initWithWriter:nil formatter:nil filter:nil];
}

- (id)initWithWriter:(id<GMLogWriter>)writer
           formatter:(id<GMLogFormatter>)formatter
              filter:(id<GMLogFilter>)filter {
  if ((self = [super init])) {
    [self setWriter:writer];
    [self setFormatter:formatter];
    [self setFilter:filter];
    GMLOGGER_ASSERT(formatter_ != nil);
    GMLOGGER_ASSERT(filter_ != nil);
    GMLOGGER_ASSERT(writer_ != nil);
  }
  return self;
}

- (void)dealloc {
  GMLOGGER_ASSERT(writer_ != nil);
  GMLOGGER_ASSERT(formatter_ != nil);
  GMLOGGER_ASSERT(filter_ != nil);
  [writer_ release];
  [formatter_ release];
  [filter_ release];
  [super dealloc];
}

- (id<GMLogWriter>)writer {
  GMLOGGER_ASSERT(writer_ != nil);
  return [[writer_ retain] autorelease];
}

- (void)setWriter:(id<GMLogWriter>)writer {
  @synchronized(self) {
    [writer_ autorelease];
    if (writer == nil)
      writer_ = [[NSFileHandle fileHandleWithStandardOutput] retain];
    else
      writer_ = [writer retain];
  }
  GMLOGGER_ASSERT(writer_ != nil);
}

- (id<GMLogFormatter>)formatter {
  GMLOGGER_ASSERT(formatter_ != nil);
  return [[formatter_ retain] autorelease];
}

- (void)setFormatter:(id<GMLogFormatter>)formatter {
  @synchronized(self) {
    [formatter_ autorelease];
    if (formatter == nil)
      formatter_ = [[GMLogBasicFormatter alloc] init];
    else
      formatter_ = [formatter retain];
  }
  GMLOGGER_ASSERT(formatter_ != nil);
}

- (id<GMLogFilter>)filter {
  GMLOGGER_ASSERT(filter_ != nil);
  return [[filter_ retain] autorelease];
}

- (void)setFilter:(id<GMLogFilter>)filter {
  @synchronized(self) {
    [filter_ autorelease];
    if (filter == nil)
      filter_ = [[GMLogNoFilter alloc] init];
    else
      filter_ = [filter retain];
  }
  GMLOGGER_ASSERT(filter_ != nil);
}

- (void)logDebug:(NSString *)fmt, ... {
  va_list args;
  va_start(args, fmt);
  [self logInternalFunc:NULL format:fmt valist:args level:kGMLoggerLevelDebug];
  va_end(args);
}

- (void)logInfo:(NSString *)fmt, ... {
  va_list args;
  va_start(args, fmt);
  [self logInternalFunc:NULL format:fmt valist:args level:kGMLoggerLevelInfo];
  va_end(args);
}

- (void)logError:(NSString *)fmt, ... {
  va_list args;
  va_start(args, fmt);
  [self logInternalFunc:NULL format:fmt valist:args level:kGMLoggerLevelError];
  va_end(args);
}

- (void)logAssert:(NSString *)fmt, ... {
  va_list args;
  va_start(args, fmt);
  [self logInternalFunc:NULL format:fmt valist:args level:kGMLoggerLevelAssert];
  va_end(args);
}

@end  // GMLogger


@implementation GMLogger (GMLoggerMacroHelpers)

- (void)logFuncDebug:(const char *)func msg:(NSString *)fmt, ... {
  va_list args;
  va_start(args, fmt);
  [self logInternalFunc:func format:fmt valist:args level:kGMLoggerLevelDebug];
  va_end(args);
}

- (void)logFuncInfo:(const char *)func msg:(NSString *)fmt, ... {
  va_list args;
  va_start(args, fmt);
  [self logInternalFunc:func format:fmt valist:args level:kGMLoggerLevelInfo];
  va_end(args);
}

- (void)logFuncError:(const char *)func msg:(NSString *)fmt, ... {
  va_list args;
  va_start(args, fmt);
  [self logInternalFunc:func format:fmt valist:args level:kGMLoggerLevelError];
  va_end(args);
}

- (void)logFuncAssert:(const char *)func msg:(NSString *)fmt, ... {
  va_list args;
  va_start(args, fmt);
  [self logInternalFunc:func format:fmt valist:args level:kGMLoggerLevelAssert];
  va_end(args);
}

@end  // GMLoggerMacroHelpers


@implementation GMLogger (PrivateMethods)
- (void)logInternalFunc:(const char *)func
                 format:(NSString *)fmt
                 valist:(va_list)args
                  level:(GMLoggerLevel)level {
  GMLOGGER_ASSERT(formatter_ != nil);
  GMLOGGER_ASSERT(filter_ != nil);
  GMLOGGER_ASSERT(writer_ != nil);

  NSString *fname = func ? [NSString stringWithUTF8String:func] : nil;
  NSString *msg = [formatter_ stringForFunc:fname
                                 withFormat:fmt
                                     valist:args
                                      level:level];
  if (msg && [filter_ filterAllowsMessage:msg level:level])
    [writer_ logMessage:msg level:level];
}
@end  // PrivateMethods


@implementation NSFileHandle (GMFileHandleLogWriter)

+ (id)fileHandleForLoggingAtPath:(NSString *)path mode:(mode_t)mode {
  int fd = -1;
  if (path) {
    int flags = O_WRONLY | O_APPEND | O_CREAT;
    fd = open([path fileSystemRepresentation], flags, mode);
  }
  if (fd == -1) return nil;
  return [[[self alloc] initWithFileDescriptor:fd
                                closeOnDealloc:YES] autorelease];
}

+ (id)fileHandleForWritingAtPath:(NSString *)path create:(BOOL)shouldCreate {
  if (shouldCreate && path != nil) {
    // Open then close the file, which will create it if it didn't exist
    int fd = open([path fileSystemRepresentation], O_CREAT, 0644);
    if (fd != -1) close(fd);
  }
  return [self fileHandleForWritingAtPath:path];
}

- (void)logMessage:(NSString *)msg level:(GMLoggerLevel)level {
  @synchronized(self) {
    NSString *line = [NSString stringWithFormat:@"%@\n", msg];
    [self writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
  }
}

@end  // GMFileHandleLogWriter


@implementation NSArray (GMArrayCompositeLogWriter)
- (void)logMessage:(NSString *)msg level:(GMLoggerLevel)level {
  @synchronized(self) {
    id<GMLogWriter> child = nil;
    NSEnumerator *childEnumerator = [self objectEnumerator];
    while ((child = [childEnumerator nextObject])) {
      if ([child conformsToProtocol:@protocol(GMLogWriter)])
        [child logMessage:msg level:level];
    }
  }
}
@end  // GMArrayCompositeLogWriter


@implementation GMLogger (GMLoggerLogWriter)
- (void)logMessage:(NSString *)msg level:(GMLoggerLevel)level {
  switch (level) {
    case kGMLoggerLevelDebug:
      [self logDebug:msg];
      break;
    case kGMLoggerLevelInfo:
      [self logInfo:msg];
      break;
    case kGMLoggerLevelError:
      [self logError:msg];
      break;
    case kGMLoggerLevelAssert:
      [self logAssert:msg];
      break;
    default:
      // Ignore the message.
      break;
  }
}
@end  // GMLoggerLogWriter


// Helper class used by GMLogASLWriter to create an ASL client and write to the
// ASL log. This class is need to make management/cleanup of the aslclient work
// in a multithreaded environment. You'll need one of these GMLoggerASLClient
// per thread.
@interface GMLoggerASLClient : NSObject {
 @private
  aslclient client_;
}
- (void)log:(NSString *)msg level:(GMLoggerLevel)level;
@end

@implementation GMLoggerASLClient

- (id)init {
  if ((self = [super init])) {
    NSLog(@"opening asl");
    client_ = asl_open(NULL, NULL, 0);
    GMLOGGER_ASSERT(client_ != NULL);
  }
  return self;
}

- (void)dealloc {
  GMLOGGER_ASSERT(client_ != NULL);
  NSLog(@"closing asl");

  if (client_) asl_close(client_);
  [super dealloc];
}

- (void)log:(NSString *)msg level:(GMLoggerLevel)level {
  if (msg == nil) return;
  // Map the GMLoggerLevel level to an ASL level.
  int aslLevel = (level == kGMLoggerLevelError) ? ASL_LEVEL_ERR : ASL_LEVEL_NOTICE;
  GMLOGGER_ASSERT(client_ != NULL);
  asl_log(client_, NULL, aslLevel, "%s", [msg UTF8String]);
}

@end  // GMLoggerASLClient


@implementation GMLogASLWriter
- (void)logMessage:(NSString *)msg level:(GMLoggerLevel)level {
  static NSString *const kASLClientKey = @"GMLoggerASLClientKey";

  // Lookup the ASL client in the thread-local storage dictionary
  NSMutableDictionary *tls = [[NSThread currentThread] threadDictionary];
  GMLoggerASLClient *client = [tls objectForKey:kASLClientKey];

  // If the ASL client wasn't found (e.g., the first call from this thread),
  // then create it and store it in the thread-local storage dictionary
  if (client == nil) {
    client = [[[GMLoggerASLClient alloc] init] autorelease];
    [tls setObject:client forKey:kASLClientKey];
  }

  GMLOGGER_ASSERT(client != nil);
  [client log:msg level:level];
}
@end  // GMLogASLWriter


@implementation GMLogBasicFormatter
- (NSString *)stringForFunc:(NSString *)func
                 withFormat:(NSString *)fmt
                     valist:(va_list)args
                      level:(GMLoggerLevel)level {
  // Performance note: since we always have to create a new NSString from the
  // returned CFStringRef, we may want to do a quick check here to see if |fmt|
  // contains a '%', and if not, simply return 'fmt'.
  CFStringRef cfmsg = NULL;
  cfmsg = CFStringCreateWithFormatAndArguments(kCFAllocatorDefault,
                                               NULL,  // format options
                                               (CFStringRef)fmt,
                                               args);
  NSString *msg = nil;
  if (cfmsg) {
    // We explicitly convert the CFString to an NSString because it's not safe
    // to autorelease a CFType in a garbage collected world.
    msg = [NSString stringWithString:(NSString *)cfmsg];
    CFRelease(cfmsg);
  }
  return msg;
}
@end  // GMLogBasicFormatter


@implementation GMLogStandardFormatter

- (id)init {
  if ((self = [super init])) {
    dateFormatter_ = [[NSDateFormatter alloc] init];
    [dateFormatter_ setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter_ setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
  }
  return self;
}

- (void)dealloc {
  [dateFormatter_ release];
  [super dealloc];
}

- (NSString *)stringForFunc:(NSString *)func
                 withFormat:(NSString *)fmt
                     valist:(va_list)args
                      level:(GMLoggerLevel)level {
  GMLOGGER_ASSERT(dateFormatter_ != nil);
  NSString *tstamp = [dateFormatter_ stringFromDate:[NSDate date]];
  NSProcessInfo *pinfo = [NSProcessInfo processInfo];
  return [NSString stringWithFormat:@"%@ %@[%d/%p] [lvl=%d] %@ %@", tstamp,
          [pinfo processName], [pinfo processIdentifier], pthread_self(),
          level, (func ? func : @"(no func)"),
          [super stringForFunc:func withFormat:fmt valist:args level:level]];
}

@end  // GMLogStandardFormatter


@implementation GMLogLevelFilter

// Check the environment and the user preferences for the GMVerboseLogging key
// to see if verbose logging has been enabled. The environment variable will
// override the defaults setting, so check the environment first.
static BOOL IsVerboseLoggingEnabled(void) {
  static NSString *const kVerboseLoggingKey = @"GMVerboseLogging";

  const char *env = getenv([kVerboseLoggingKey UTF8String]);
  if (env && env[0]) {
    return (strtol(env, NULL, 10) != 0);
  }

  return [[NSUserDefaults standardUserDefaults] boolForKey:kVerboseLoggingKey];
}

// In DEBUG builds, log everything. If we're not in a debug build we'll assume
// that we're in a Release build.
- (BOOL)filterAllowsMessage:(NSString *)msg level:(GMLoggerLevel)level {
#if DEBUG
  return YES;
#endif

  BOOL allow = YES;

  switch (level) {
    case kGMLoggerLevelDebug:
      allow = NO;
      break;
    case kGMLoggerLevelInfo:
      allow = (IsVerboseLoggingEnabled() == YES);
      break;
    case kGMLoggerLevelError:
      allow = YES;
      break;
    case kGMLoggerLevelAssert:
      allow = YES;
      break;
    default:
      allow = YES;
      break;
  }

  return allow;
}

@end  // GMLogLevelFilter


@implementation GMLogNoFilter
- (BOOL)filterAllowsMessage:(NSString *)msg level:(GMLoggerLevel)level {
  return YES;  // Allow everything through
}
@end  // GMLogNoFilter
