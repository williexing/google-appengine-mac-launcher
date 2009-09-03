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

// Controller (in the MVC model) for Preferences (e.g. pick the
// external editor).
// Model is thru NSUserDefaults.
// View is a special preference window.
@interface MBPreferenceController : NSWindowController {
  IBOutlet NSTextField *python_;
  IBOutlet NSTextField *editor_;
  IBOutlet NSButton *editDirectory_;
}

// Return a singleton
+ (MBPreferenceController *)sharedController;

// IBActions for setting preferences from the UI.
- (IBAction)setPython:(id)sender;
- (IBAction)setEditor:(id)sender;

// Opens a selection panel, triggered from "Select..." button
- (IBAction)selectEditorApplication:(id)sender;

// Return an autoreleased NSOpenPanel to be used for directory
// selection.  Factored out to make unit tests easier.
- (NSOpenPanel *)openPanel;

@end


