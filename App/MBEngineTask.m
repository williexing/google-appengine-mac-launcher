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

#import "MBEngineTask.h"
#import "MBLogFilter.h"
#import "MBProject.h"

@interface MBEngineTask (Private)
- (void)startListening;
- (void)stopListening;
@end

@implementation MBEngineTask

+ (id)taskWithProject:(MBProject *)project {
  return [[[self alloc] initWithProject:project] autorelease];
}

- (id)init {
  return [self initWithProject:nil];
}

- (id)initWithProject:(MBProject *)project {
  if ((self = [super init])) {
    task_ = [[NSTask alloc] init];
    project_ = [project retain];

    NSPipe *pipe = [NSPipe pipe];

    // dev_appserver doesn't write anything to stdout; all is stderr.
    // We merge them together here so we don't lose anything if that
    // changes.
    // In the future, if dev_appserver writes to stdout, we may want
    // to display them differently (e.g. stderr=red, stdout=black).
    // If so we'd need 2 pipes right here.
    [task_ setStandardOutput:pipe];
    [task_ setStandardError:pipe];
  }
  return self;
}

- (void)dealloc {
  // With GC we would have a problem -- dealloc not called so long as
  // the notification center has a reference to me.
  [self stopListening];

  [task_ release];
  [filter_ release];
  [project_ release];
  [super dealloc];
}

- (void)setProject:(MBProject *)project {
  [project_ autorelease];
  project_ = [project retain];
}

- (MBProject *)project {
  return project_;
}

// Filter is created on-demand if needed.
- (MBLogFilter *)logFilter {
  if (filter_ == nil)
    filter_ = [[MBLogFilter alloc] init];
  return filter_;
}

- (void)setStandardInput:(NSString *)input {
  NSPipe *pipe = [NSPipe pipe];
  [task_ setStandardInput:pipe];
  const char *bytes = [input UTF8String];
  NSData *data = [NSData dataWithBytes:bytes length:strlen(bytes)];
  [[pipe fileHandleForWriting] writeData:data];
}

- (void)setOutputReceiver:(id<MBEngineTaskOutputReceiver>)receiver {
  receiver_ = receiver;  // weak -- no retain
}

// Start listening for data from our pipe.
- (void)startListening {
  NSFileHandle *handle = [[task_ standardOutput] fileHandleForReading];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(dataIsAvailable:)
                                               name:NSFileHandleReadCompletionNotification
                                             object:handle];
  [handle readInBackgroundAndNotify];
}

// Stop listening for data from our pipe.
// Called when we die to remove a reference to us from NSNotificationCenter
- (void)stopListening {
  NSFileHandle *handle = [[task_ standardOutput] fileHandleForReading];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSFileHandleReadCompletionNotification
                                                object:handle];
}

// Called from an NSNotification when we get input
- (void)dataIsAvailable:(NSNotification *)notification {
  if (receiver_) {
    NSData *data = [[notification userInfo]
                       objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding]
                         autorelease];

    // Give our filter a chance to see it... or change it.
    if (filter_)
      string = [filter_ processString:string];

    // Send it to our receiver.
    [receiver_ processString:string];
  }

  // we must always re-register
  NSFileHandle *handle = [[task_ standardOutput] fileHandleForReading];
  [handle readInBackgroundAndNotify];
}


// Want private; need to expose for task death notification
- (NSTask *)task {
  return task_;
}

// Quack like an NSTask
- (void)setLaunchPath:(NSString *)path {
  return [task_ setLaunchPath:path];
}

- (void)setArguments:(NSArray *)arguments {
  return [task_ setArguments:arguments];
}

- (void)setEnvironment:(NSDictionary *)dict {
  return [task_ setEnvironment:dict];
}

- (void)setCurrentDirectoryPath:(NSString *)path {
  return [task_ setCurrentDirectoryPath:path];
}

- (void)launch {
  [self startListening];
  [task_ launch];
}

- (void)interrupt {
  [task_ interrupt];
}

- (void)waitUntilExit {
  [task_ waitUntilExit];

  // Unfortunately, we may have notifications pending.  We pump the
  // event loop just to make sure they are processed before we stop
  // listening.  Ugh.
  // This ugliness happens easily in a unit test, since we do a quick
  // launch + waitUntilExit.  In real Launcher use processes death
  // itself happens on a notification.
  for (int x = 0; x < 2; x++) {
    NSDate *shortTimeFromNow = [NSDate dateWithTimeIntervalSinceNow:0.01];
    [[NSRunLoop currentRunLoop] runUntilDate:shortTimeFromNow];
  }

  [self stopListening];
}

@end


