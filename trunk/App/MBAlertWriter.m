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

#import "MBAlertWriter.h"


@implementation MBAlertWriter

static BOOL gInstalled = NO;
+ (void)install {
  @synchronized(self) {
    if (gInstalled == NO) {
       MBAlertWriter *writer = [[[MBAlertWriter alloc] init] autorelease];
      [[GMLogger sharedLogger] setWriter:writer];

      // For a GUI app displaying an error dialog, we simply don't care
      // about date and time (it happened right now!), process and thread
      // id, etc.
      [[GMLogger sharedLogger] setFormatter:nil];

      gInstalled = YES;
    }
  }
}

- (id)init {
  return [self initWithOriginalWriter:nil alert:nil];
}

- (id)initWithOriginalWriter:(id<GMLogWriter>)w alert:(NSAlert *)alert {
  if ((self = [super init])) {
    if (w == nil)
      w = [[GMLogger sharedLogger] writer];
    if (alert == nil) {
      alert = [[[NSAlert alloc] init] autorelease];
      [alert_ addButtonWithTitle:@"OK"];
    }
    originalWriter_ = [w retain];
    alert_ = [alert retain];
  }
  return self;
}

- (void)dealloc {
  [[GMLogger sharedLogger] setWriter:nil];  // can't be us anymore!
  [originalWriter_ release];
  [alert_ release];
  [super dealloc];
}

- (void)alertWithTitle:(NSString *)title message:(NSString *)msg {
  [alert_ setMessageText:title];
  [alert_ setInformativeText:msg];
  [alert_ runModal];
}

// Split out in a seperate method so it can be overridden for testing
- (void)terminate {
  [NSApp terminate:self];
}

- (void)logMessage:(NSString *)msg level:(GMLoggerLevel)level {
  switch (level) {
    case kGMLoggerLevelAssert:
      [self alertWithTitle:@"Fatal Error" message:msg];
      [self terminate];
      break;
    case kGMLoggerLevelError:
      [self alertWithTitle:@"Error" message:msg];
      break;
    default:
      // TODO(jrg): perhaps use the original formatter as well?
      [originalWriter_ logMessage:msg level:level];
      break;
  }
}

@end
