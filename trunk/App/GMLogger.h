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

// ===========================================================================
//
//                             [ DEPRECATED ]
//
// This class has been deprecated and is no longer being supported. The
// functionality provided by this class has been moved into the Google Toolbox.
// GTMLogger is located at
//
//     //depot/googlemac/opensource/google-toolbox-for-mac/Foundation
//
// ===========================================================================

// Key Abstractions
// ----------------
//
// This file declares multiple classes and protocols that are used by the
// GMLogger logging system. The 4 main abstractions used in this file are the
// following:
//
//   * logger (GMLogger) - The main logging class that users interact with. It
//   has methods for logging at different levels and uses a log writer, a log
//   formatter, and a log filter to get the job done.
//
//   * log writer (GMLogWriter) - Writes a given string to some log file, where
//   a "log file" can be a physical file on disk, a POST over HTTP to some URL,
//   or even some in-memory structure (e.g., a ring buffer).
//
//   * log formatter (GMLogFormatter) - Given a format string and arguments as
//   a va_list, returns a single formatted NSString. A "formatted string" could
//   be a string with the date prepended, a string with values in a CSV format,
//   or even a string of XML.
//
//   * log filter (GMLogFilter) - Given a formatted log message as an NSString
//   and the level at which the message is to be logged, this class will decide
//   whether the given message should be logged or not. This is a flexible way
//   to filter out messages logged at a certain level, messages that contain
//   certain text, or filter nothing out at all. This gives the caller the
//   flexibility to dynamically enable debug logging in Release builds.
//
// A class diagram showing the relationship between these key abstractions can
// be found at: http://www.corp.google.com/eng/designdocs/maceng/GMLogger.png
//
// This file also declares some classes to handle the common log writer, log
// formatter, and log filter cases. Callers can also create their own writers,
// formatters, and filters and they can even build them on top of the ones
// declared here. Keep in mind that your custom writer/formatter/filter may be
// called from multiple threads, so it must be thread-safe.

#import <Foundation/Foundation.h>

// Predeclaration of used protocols that are declared later in this file.
@protocol GMLogWriter, GMLogFormatter, GMLogFilter;

// GMLogger
//
// GMLogger is the primary user-facing class for an object-oriented logging
// system. It is built on the concept of log formatters (GMLogFormatter), log
// writers (GMLogWriter), and log filters (GMLogFilter). When a message is sent
// to a GMLogger to log a message, the message is formatted using the log
// formatter, then the log filter is consulted to see if the message should be
// logged, and if so, the message is sent to the log writer to be written out.
//
// GMLogger is intended to be a flexible and thread-safe logging solution. Its
// flexibility comes from the fact that GMLogger instances can be customized
// with user defined formatters, filters, and writers. And these writers,
// filters, and formatters can be combined, stacked, and customized in arbitrary
// ways to suit the needs at hand. For example, multiple writers can be used at
// the same time, and a GMLogger instance can even be used as another GMLogger's
// writer. This allows for arbitrarily deep logging trees.
//
// A standard GMLogger uses a writer that sends messages to standard out, a
// formatter that smacks a timestamp and a few other bits of interesting
// information on the message, and a filter that filters out debug messages from
// release builds. Using the standard log settings, a log message will look like
// the following:
//
//   2007-12-30 10:29:24.177 myapp[4588/0xa07d0f60] [lvl=1] foo=<Foo: 0x123>
//
// The output contains the date and time of the log message, the name of the
// process followed by its process ID/thread ID, the log level at which the
// message was logged (in the previous example the level was 1: kGMLoggerLevelDebug),
// and finally, the user-specified log message itself (in this case, the log
// message was @"foo=%@", foo).
//
// Multiple instances of GMLogger can be created, each configured their own way.
// Though GMLogger is not a singleton (in the GoF sense), it does provide access
// to a shared (i.e., globally accessible) GMLogger instance. This makes it
// convenient for all code in a process to use the same GMLogger instance. The
// shared GMLogger instance can also be configured in an arbitrary, and these
// configuration changes will affect all code that logs through the shared
// instance.
//
// Log Levels
// ----------
// GMLogger has 3 different log levels: Debug, Info, and Error. GMLogger doesn't
// take any special action based on the log level; it simply forwards this
// information on to formatters, filters, and writers, each of which may
// optionally take action based on the level. Since log level filtering is
// performed at runtime, log messages are typically not filtered out at compile
// time.  The exception to this rule is that calls to the GMLoggerDebug() macro
// *ARE* filtered out of non-DEBUG builds. This is to be backwards compatible
// with behavior that many developers are currently used to. Note that this
// means that GMLoggerDebug(@"hi") will be compiled out of Release builds, but
// [[GMLogger sharedLogger] logDebug:@"hi"] will NOT be compiled out.
//
// Standard loggers are created with the GMLogLevelFilter log filter, which
// filters out certain log messages based on log level, and some other settings.
//
// In addition to the -logDebug:, -logInfo:, and -logError: methods defined on
// GMLogger itself, there are also C macros that make usage of the shared
// GMLogger instance very convenient. These macros are:
//
//   GMLoggerDebug(...)
//   GMLoggerInfo(...)
//   GMLoggerError(...)
//
// Again, a notable feature of these macros is that GMLogDebug() calls *will be
// compiled out of non-DEBUG builds*.
//
// Standard Loggers
// ----------------
// GMLogger has the concept of "standard loggers". A standard logger is simply a
// logger that is pre-configured with some standard/common writer, formatter,
// and filter combination. Standard loggers are created using the creation
// methods beginning with "standard". The alternative to a standard logger is a
// regular logger, which will send messages to stdout, with no special
// formatting, and no filtering.
//
// How do I use GMLogger?
// ----------------------
// The typical way you will want to use GMLogger is to simply use the
// GMLogger*() macros for logging from code. That way we can easily make changes
// to the GMLogger class and simply update the macros accordingly. Only your
// application startup code (perhaps, somewhere in main()) should use the
// GMLogger class directly in order to configure the shared logger, which all
// of the code using the macros will be using. Again, this is just the typical
// situation.
//
// To be complete, there are cases where you may want to use GMLogger directly,
// or even create separate GMLogger instances for some reason. That's fine, too.
//
// Examples
// --------
// The following show some common GMLogger use cases.
//
// 1. You want to log something as simply as possible. Also, this call will only
//    appear in debug builds. In non-DEBUG builds it will be completely removed.
//
//      GMLoggerDebug(@"foo = %@", foo);
//
// 2. The previous example is similar to the following. The major difference is
//    that the previous call (example 1) will be compiled out of Release builds
//    but this statement will not be compiled out.
//
//      [[GMLogger sharedLogger] logDebug:@"foo = %@", foo];
//
// 3. Send all logging output from the shared logger to a file. We do this by
//    creating an NSFileHandle for writing associated with a file, and setting
//    that file handle as the logger's writer.
//
//      NSFileHandle *f = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/f.log"
//                                                          create:YES];
//      [[GMLogger sharedLogger] setWriter:f];
//      GMLoggerError(@"hi");  // This will be sent to /tmp/f.log
//
// 4. Create a new GMLogger that will log to a file. This example differs from
//    the previous one because here we create a new GMLogger that is different
//    from the shared logger.
//
//      GMLogger *logger = [GMLogger standardLoggerWithPath:@"/tmp/temp.log"];
//      [logger logInfo:@"hi temp log file"];
//
// 5. Create a logger that writes to stdout and does NOT do any formatting to
//    the log message. This might be useful, for example, when writing a help
//    screen for a command-line tool to standard output.
//
//      GMLogger *logger = [GMLogger logger];
//      [logger logInfo:@"%@ version 0.1 usage", progName];
//
// 6. Send log output to stdout AND to a log file. The trick here is that
//    NSArrays function as composite log writers, which means when an array is
//    set as the log writer, it forwards all logging messages to all of its
//    contained GMLogWriters.
//
//      // Create array of GMLogWriters
//      NSArray *writers = [NSArray arrayWithObjects:
//          [NSFileHandle fileHandleForWritingAtPath:@"/tmp/f.log" create:YES],
//          [NSFileHandle fileHandleWithStandardOutput], nil];
//
//      GMLogger *logger = [GMLogger standardLogger];
//      [logger setWriter:writers];
//      [logger logInfo:@"hi"];  // Output goes to stdout and /tmp/f.log
//
// 7. Send log output to both standard error and ASL. This example exploits the
//    fact that GMLoggers themselves can be used as GMLogWriters. This way a
//    GMLogWriter+GMLogFormatter combo can be combined with a different log
//    writer and a different log formatter. In this case, the stderr logger will
//    use the GMLogStandardFormatter formatter which will prepend timestamp
//    info, but the ASL logger will use the basic formatter, which will not do
//    any timestamping (because ASL will handle this for us).
//
//      NSArray *writers = [NSArray arrayWithObjects:
//          [GMLogger standardLoggerWithStderr],
//          [GMLogger standardLoggerWithASL], nil];
//
//      GMLogger *logger = [GMLogger logger];
//      [logger setWriter:writers];
//      [logger logInfo:@"hi"];
//
// For futher details on log writers, formatters, and filters, see the
// documentation below.
@interface GMLogger : NSObject {
 @private
  id<GMLogWriter> writer_;
  id<GMLogFormatter> formatter_;
  id<GMLogFilter> filter_;
}

//
// Accessors for the shared logger instance
//

// Returns a shared/global standard GMLogger instance. Callers should typically
// use this method to get a GMLogger instance, unless they explicitly want their
// own instance to configure for their own needs. This is the only method that
// returns a shared instance; all the rest return new GMLogger instances.
+ (id)sharedLogger;

// Sets the shared logger instance to |logger|. Future calls to +sharedLogger
// will return |logger| instead.
+ (void)setSharedLogger:(GMLogger *)logger;

//
// Creation methods
//

// Returns a new autoreleased GMLogger instance that will log to stdout, use the
// GMLogStandardFormatter, and the GMLogLevelFilter filter.
+ (id)standardLogger;

// Same as +standardLogger, but logs to stderr.
+ (id)standardLoggerWithStderr;

// Returns a new autoreleased GMLogger instance that will log to ASL, will use
// the GMLogBasicFormatter, and will use the GMLogLevelFilter filter. This
// logger uses the basic formatter because ASL handles timestamping of the
// messages automatically.
+ (id)standardLoggerWithASL;

// Returns a new standard GMLogger instance with a log writer that will
// write to the file at |path|, and will use the GMLogStandardFormatter and
// GMLogLevelFilter classes. If |path| does not exist, it will be created.
+ (id)standardLoggerWithPath:(NSString *)path;

// Returns an autoreleased GMLogger instance that will use the specified
// |writer|, |formatter|, and |filter|.
+ (id)loggerWithWriter:(id<GMLogWriter>)writer
             formatter:(id<GMLogFormatter>)formatter
                filter:(id<GMLogFilter>)filter;

// Returns an autoreleased GMLogger instance that logs to stdout, with the basic
// formatter, and no filter. The returned logger differs from the logger
// returned by +standardLogger because this one does not do any filtering and
// does not do any special log formatting; this is the difference between a
// "regular" logger and a "standard" logger.
+ (id)logger;

// Designated initializer. This method returns a GMLogger initialized with the
// specified |writer|, |formatter|, and |filter|. See the setter methods below
// for what values will be used if nil is passed for a parameter.
- (id)initWithWriter:(id<GMLogWriter>)writer
           formatter:(id<GMLogFormatter>)formatter
              filter:(id<GMLogFilter>)filter;

//
// Logging  methods
//

// Logs a message at the debug level (kGMLoggerLevelDebug).
- (void)logDebug:(NSString *)fmt, ...;
// Logs a message at the info level (kGMLoggerLevelInfo).
- (void)logInfo:(NSString *)fmt, ...;
// Logs a message at the error level (kGMLoggerLevelError).
- (void)logError:(NSString *)fmt, ...;
// Logs a message at the assert level (kGMLoggerLevelAssert).
- (void)logAssert:(NSString *)fmt, ...;

//
// Accessors
//

// Accessor methods for the log writer. If the log writer is set to nil,
// [NSFileHandle fileHandleWithStandardOutput] is used.
- (id<GMLogWriter>)writer;
- (void)setWriter:(id<GMLogWriter>)writer;

// Accessor methods for the log formatter. If the log formatter is set to nil,
// GMLogBasicFormatter is used. This formatter will format log messages in a
// plain printf style.
- (id<GMLogFormatter>)formatter;
- (void)setFormatter:(id<GMLogFormatter>)formatter;

// Accessor methods for the log filter. If the log filter is set to nil,
// GMLogNoFilter is used, which allows all log messages through.
- (id<GMLogFilter>)filter;
- (void)setFilter:(id<GMLogFilter>)filter;

@end

// Helper functions that are used by the convenience GMLogger*() macros that
// enable the logging of function names.
@interface GMLogger (GMLoggerMacroHelpers)
- (void)logFuncDebug:(const char *)func msg:(NSString *)fmt, ...;
- (void)logFuncInfo:(const char *)func msg:(NSString *)fmt, ...;
- (void)logFuncError:(const char *)func msg:(NSString *)fmt, ...;
- (void)logFuncAssert:(const char *)func msg:(NSString *)fmt, ...;
@end

// Convenience macros that log to the shared GMLogger instance. These macros
// are how users should typically log to GMLogger. Notice that GMLoggerDebug()
// calls will be compiled out of non-Debug builds.
#define GMLoggerDebug(...)  \
  [[GMLogger sharedLogger] logFuncDebug:__func__ msg:__VA_ARGS__]
#define GMLoggerInfo(...)   \
  [[GMLogger sharedLogger] logFuncInfo:__func__ msg:__VA_ARGS__]
#define GMLoggerError(...)  \
  [[GMLogger sharedLogger] logFuncError:__func__ msg:__VA_ARGS__]
#define GMLoggerAssert(...) \
  [[GMLogger sharedLogger] logFuncAssert:__func__ msg:__VA_ARGS__]

// If we're not in a debug build, remove the GMLoggerDebug statements. This
// makes calls to GMLoggerDebug "compile out" of Release builds
#ifndef DEBUG
#undef GMLoggerDebug
#define GMLoggerDebug(...) do {} while(0)
#endif

// Log levels.
typedef enum {
  kGMLoggerLevelUnknown,
  kGMLoggerLevelDebug,
  kGMLoggerLevelInfo,
  kGMLoggerLevelError,
  kGMLoggerLevelAssert,
} GMLoggerLevel;


//
//   Log Writers
//

// Protocol to be implemented by a GMLogWriter instance.
@protocol GMLogWriter <NSObject>
// Writes the given log message to where the log writer is configured to write.
- (void)logMessage:(NSString *)msg level:(GMLoggerLevel)level;
@end

// Simple category on NSFileHandle that makes NSFileHandles valid log writers.
// This is convenient because something like, say, +fileHandleWithStandardError
// now becomes a valid log writer. Log messages are written to the file handle
// with a newline appended.
@interface NSFileHandle (GMFileHandleLogWriter) <GMLogWriter>
// Opens the file at |path| in append mode, and creates the file with |mode|
// if it didn't previously exist.
+ (id)fileHandleForLoggingAtPath:(NSString *)path mode:(mode_t)mode;
// Returns an NSFileHandle associated with the specified file, creating the file
// if necessary. The file will be created with mode 0644. It will not be opened
// in append mode.
+ (id)fileHandleForWritingAtPath:(NSString *)path create:(BOOL)shouldCreate;
@end

// This category makes NSArray a GMLogWriter that can be composed of other
// GMLogWriters. This is the classic Composite GoF design pattern. When the
// GMLogWriter -logMessage:level: message is sent to the array, the array
// forwards the message to all of its elements that implement the GMLogWriter
// protocol.
//
// This is useful in situations where you would like to send log output to
// multiple log writers at the same time. Simply create an NSArray of the log
// writers you wish to use, then set the array as the "writer" for your GMLogger
// instance.
@interface NSArray (GMArrayCompositeLogWriter) <GMLogWriter>
@end

// This category adapts the GMLogger interface so that it can be used as a log
// writer; it's an "adapter" in the GoF Adapter pattern sense.
//
// This is useful when  you want to configure a logger to log to a specific
// writer with a specific formatter and/or filter. But you want to also compose
// that with a different log writer that may have its own formatter and/or
// filter.
@interface GMLogger (GMLoggerLogWriter) <GMLogWriter>
@end

// A log writer that logs to the ASL (Apple System Log) facility.
@interface GMLogASLWriter : NSObject <GMLogWriter>
@end


//
//   Log Formatters
//

// Protocol to be implemented by a GMLogFormatter instance.
@protocol GMLogFormatter <NSObject>
// Returns a formatted string using the format specified in |fmt| and the va
// args specified in |args|.
- (NSString *)stringForFunc:(NSString *)func
                 withFormat:(NSString *)fmt
                     valist:(va_list)args
                      level:(GMLoggerLevel)level;
@end

// A basic log formatter that formats a string the same way that NSLog (or
// printf) would. It does not do anything fancy, nor does it add any data of its
// own.
@interface GMLogBasicFormatter : NSObject <GMLogFormatter>
@end

// A log formatter that formats the log string like the basic formatter, but
// also prepends a timestamp and some basic process info to the message, as
// shown in the following sample output.
//   2007-12-30 10:29:24.177 myapp[4588/0xa07d0f60] [lvl=1] log mesage here
@interface GMLogStandardFormatter : GMLogBasicFormatter {
 @private
  NSDateFormatter *dateFormatter_;  // yyyy-MM-dd HH:mm:ss.SSS
}
@end


//
//   Log Filters
//

// Protocol to be imlemented by a GMLogFilter instance.
@protocol GMLogFilter <NSObject>
// Returns YES if |msg| at |level| should be filtered out; NO otherwise.
- (BOOL)filterAllowsMessage:(NSString *)msg level:(GMLoggerLevel)level;
@end

// A log filter that filters messages at the kGMLoggerLevelDebug level out of
// non-debug builds. Messages at the kGMLoggerLevelInfo level are also filtered out
// of non-debug builds unless GMVerboseLogging is set in the environment or the
// processes's defaults. Messages at the kGMLoggerLevelError level are never
// filtered.
@interface GMLogLevelFilter : NSObject <GMLogFilter>
@end

// A simple log filter that does NOT filter anything out;
// -filterAllowsMessage:level will always return YES. This can be a convenient
// way to enable debug-level logging in release builds (if you so desire).
@interface GMLogNoFilter : NSObject <GMLogFilter>
@end

