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

#import <Foundation/Foundation.h>

// MBLogFilter is a line-oriented filter with regexp triggers.
// Data sent to the filter with a call to processString: will be processed.
//
// Hooks:
//   [logFilter addGenericHook:callback forRegex:@"^ERROR:.*"];
// This will invoke the 'callback' NSInvocation when a line starting with
// "ERROR" is received.
//
// This class is now only used for hooks on the log output of dev_appserver.
@interface MBLogFilter : NSObject {
 @private
  // Hooks
  NSMutableArray *hooks_;  // array of dictionaries with keys: regex, callback
}

// The designated initialiser. outputPipe may be nil, in which case the data
// will be dropped after the hooks are run.
- (id)init;

// The following are one-shot callbacks. The callback is retained, and then
// released after it is invoked. You can add multiple hooks for the same regex
// or event.

// Most generic hook. The callback will be executed if a line matches the
// given regex. See GMRegex for the regexp language supported.
- (void)addGenericHook:(NSInvocation *)callback forRegex:(NSString *)regex;

// Hook for a project finished starting.
- (void)addProjectLaunchCompleteCallback:(NSInvocation *)callback;

// Input is a string from our owner (e.g. a running task).
// Output is our filtered result, which may be the same as input.
// This is called for all lines of test running through the filter.
- (NSString *)processString:(NSString *)output;

@end
