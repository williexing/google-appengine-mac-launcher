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
@class MBProjectArrayController;
@class MBTaskArrayController;

// MBMainWindow is the main window for the launcher which displays a
// summary of the projects "owned" by us.  In MVC, this is the main V
// for MBProjects.
//
// Since the launcher needs to run on OSX 10.4, we can't define the
// NSToolbar in the nib (new in 10.5).  This subclass of NSWindow
// takes care of creating and filling it's own toolbar to allow for
// 10.4 compatibility.  For convenience, an MBMainWindow is also the
// NSToolbar's delegate.
@interface MBMainWindow : NSWindow {
 @private
  // The target for our toolbar actions (the projects controller).
  IBOutlet MBProjectArrayController *toolbarTarget_;

  // Array of valid NSToolbarItems.  Needed by an NSToolbarDelegate,
  // which we are.
  NSArray *toolbarItems_;

  // Array of valid NSToolbarItem identifiers.  Needed by an
  // NSToolbarDelegate, which we are.
  NSArray *validToolbarItems_;

  // Array of DEFAULT NSToolbarItem identifiers.  Needed by an
  // NSToolbarDelegate, which we are.
  NSArray *defaultToolbarItems_;
}

// Return the identifier for our toolbar.
- (NSString *)toolbarIdentifier;

@end
