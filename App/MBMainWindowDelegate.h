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

// This delegate of the main window handles cut and paste.
// It is instantiated (and connected to the window) in the nib.
@interface MBMainWindowDelegate : NSObject {
 @protected
  IBOutlet MBProjectArrayController *projectController_;
}

// Separated out to make unit testing easier.
// Return the C&P pasteobard to use.
- (NSPasteboard *)pasteboard;

- (IBAction)cut:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;
@end

