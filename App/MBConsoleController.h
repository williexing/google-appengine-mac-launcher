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

#import <Cocoa/Cocoa.h>
#import "MBEngineTask.h"
@class MBProject;

// AN MBConsoleController is a controller for the console window which
// displays output from a Engine task; ; the file handle is a
// combined stdout/stderr.  there is one MBConsoleController for each
// MBEngineTask.
@interface MBConsoleController
  : NSWindowController <MBEngineTaskOutputReceiver> {
 @private
  NSString *name_;
  MBProject *project_;
  IBOutlet NSTextView *textView_;
  MBEngineTask *task_;
}

// Designated initializer.
- (id)initWithName:(NSString *)name;
- (IBAction)orderFront:(id)sender;

// Clear all text from the console window.  The first method is an
// IBAction version.
// TODO(jrg): the IBAction is not currently hooked up to UI.
- (IBAction)clearText:(id)sender;
- (void)clear;

// Add a string to the text view.  Normally all text is expected to
// come from our MBEngineTask, but our controller may want to add some
// headers (e.g. "restarting process...") or footers ("process died
// with return code 1") which would not normally be output from the
// file handle itself.
- (void)appendString:(NSString *)string;
- (void)appendString:(NSString *)string attributes:(NSDictionary *)attributes;

// Set the MBEngineTask that will provide us text.
- (void)setEngineTask:(MBEngineTask *)task;

@end


