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
#import "MBAddAppController.h"

// Wrapper class for the "Add New..." controller as defined in our
// nib.  Methods are convenience routines for extracting information
// from the dialog and clearing it when we're done.  All data members
// are set by the nib loading process.
@interface MBAddNewAppController : MBAddAppController {
 @private
  IBOutlet NSTextField *nameField_;
  IBOutlet NSTextField *directoryField_;
  IBOutlet NSTextField *directoryExplanationField_;
}
- (id)initWithPort:(NSString *)port;

// Getters.  Return the values in the "name" and "directory" fields of
// the dialog.  "name" will be the project name; directory will be
// it's location.
- (NSString *)name;
- (NSString *)directory;

// Setters corresponding to the above getters.
- (void)setName:(NSString *)name;
- (void)setDirectory:(NSString *)directory;

// Called when an update may be needed for directoryExplanationField_.
- (IBAction)updateDirectoryExplanation:(id)sender;
@end
