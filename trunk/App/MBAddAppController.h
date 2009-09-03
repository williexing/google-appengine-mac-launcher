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

// Base class for launcher dialog controllers which are used to add a
// Engine application to the project window, such as "add
// existing" and "add new" (MBAddExistingController,
// MBAddNewController).  Shared functionality includes a "browse for
// folder" mechanism.
@interface MBAddAppController : NSWindowController {
 @private
  // "Port:" field in the UI (e.g. 8000)
  // TODO(jrg): Add an NSNumberFormatter to this view, with
  // [formatter setMinimum:8000]
  // [formatter setMaximum:10000]
  // [formatter setAllowsFloats:NO]
  IBOutlet NSTextField *portField_;

  // and as passed into the init routine
  NSString *port_;
  // TODO(jrg): outlet for the runtime, currently hard-coded to "GoogleAppEngine 1.0"
}

// designated initializer.
- (id)initWithWindowNibName:(NSString *)nibname port:(NSString *)port;

// IB action from the "Browse..." button
- (IBAction)selectDirectory:(id)sender;

// Buttons can be hooked directly to a cancel action (via -[NSApp
// stop:]), but there is no equivilent success action in
// NSApplication.  ([NSApplication stopModalWithCode:] can't be used
// as an IBAction since the arg type doesn't match).  Thus, we make
// our own.
- (IBAction)stopModalWithSuccess:(id)sender;

// Return a title to be used for the "Browse..." dialog.  Subclasses
// should override this if they want to specify the title of this
// dialog.
- (NSString *)browseControllerTitle;

// Tell this object which directory to use for the project.  May be
// called implicitly from use of [self selectDirectory:], perhaps
// triggered by a "Browse..." button in the UI.  Subclasses should
// override this, since there is no "generic" field in this base class
// for a directory/path. This implementation will assert if called, hence the
// noreturn attribute.
- (void)setDirectoryFromBrowse:(NSString *)path;

// get/set the port value.
- (NSString *)port;
- (void)setPort:(NSString *)port;

@end

// These should only be overridden for unit testing
@interface MBAddAppController (UnitTestMethods)

// Return an autoreleased NSOpenPanel to be used for directory
// selection.
- (NSOpenPanel *)openPanel;

@end  // MBAddAppController (UnitTestMethods)
