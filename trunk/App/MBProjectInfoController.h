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
@class MBProject;

// Controller for "Get Project Info" dialog.
@interface MBProjectInfoController : NSWindowController {
 @private
  IBOutlet NSTextField *nameField_;  // static (not editable)
  IBOutlet NSTextField *pathField_;  // static (not editable)
  IBOutlet NSTextField *portField_;
  IBOutlet NSButton *clearDSOnLaunchCheckBox_;
  IBOutlet NSTextField *extraFlagsField_;
  IBOutlet NSTextView *fullFlagsField_;
  MBProject *project_;
}

// Designated initializer
- (id)initWithProject:(MBProject *)project;

// Called to update the flag summary, merging checkboxes, extra flags, etc.
- (IBAction)updateFlagsSummary:(id)sender;

- (IBAction)stopModalWithSuccess:(id)sender;

@end


