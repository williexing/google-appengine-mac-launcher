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

// In general, Cocoa has many mechanisms to modify UI behavior without
// the need for subclassing (delegation, informal protocols, etc).
// Although contextual menus can be added without subclassing
// (e.g. [NSResponder setMenu]), the API is inadequate.  For example,
// there is no way to switch the menu at runtime based on click
// position.  In fact, the example in Hillegass recommends subclassing
// for contextual menus.
// Although I could use the NSMenuValidation protocol to select
// enabling/disabling, I've chosen to do them in here since it's a tad
// simpler.
@interface MBMainTableView : NSTableView {
 @protected
  // Our favorite controller
  IBOutlet MBProjectArrayController *projectArrayController_;
  
  // Menu when right-clicked on a project (e.g. run)
  IBOutlet NSMenu *projectMenu_;

  // Menu when right-clicked NOT on a project (add project etc)
  IBOutlet NSMenu *mainViewMenu_;
}
@end




