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

// Traditionally, assert failure means app death.  In this spirit,
// GMAssert() will log and then call assert() (which calls abort,
// which kills the app).  For a GUI app, unannounced vaporization from
// an abort() is a bad user experience, and silent errors are
// unfriendly.  This class is a replacement for GMLogger's
// GMLogWriter, which allows us (for example) to intercept a
// GMAssert's log.  Once we have it, we can display a dialog informing
// the user of the fatal error and imminent app death.  This class
// also displays GMLogger error-level messages in a dialog but (unlike
// asserts) errors do not cause us to terminate the app.
@interface MBAlertWriter : NSObject <GMLogWriter> {
 @private
  // We save the original log writer so we can call it for non-aborts.
  id<GMLogWriter> originalWriter_;
  // Alert failure means bad news, like allocation failure.  We
  // preallocate an alert to help minimize the chance we hit more
  // problems before death.
  NSAlert *alert_;
}

// Install an MBAlertWriter as the GMLogger's default log writer.
+ (void)install;

// Designated initializer.  |w| is the original writer we should call
// if we chose to not intercept this message (e.g. if it's not an
// alert or error message).  If |w| is nil, use the [GMLogger
// sharedLogger]'s current writer.  |alert| is an allocated NSAlert
// object to be used to display an error or alert message.  If |alert|
// is nil, create an NSAlert.
- (id)initWithOriginalWriter:(id<GMLogWriter>)w alert:(NSAlert *)alert;

// Using our alert_ member, configure it with |title| and |msg| and
// run it modally.  We currently do not support a "continue anyway"
// mechanism for alerts, or a "stop telling me" mechanism for error
// messages.
- (void)alertWithTitle:(NSString *)title message:(NSString *)msg;

// MBAlertWriter will call this method when it wants to terminate.
- (void)terminate;

@end

