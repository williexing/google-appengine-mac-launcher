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

#import "MBMainTableView.h"
#import "MBProjectArrayController.h"

// TODO(jrg): rename this header MBConstants.h (or something), since
// it's used for both the toolbar and contextual menus.  The name is
// no longer accurate.
#import "MBToolbar.h"

@implementation MBMainTableView

// Split out to make unit testing easier.
- (BOOL)anyRunning {
  return ([projectArrayController_ isAnySelectedProjectInState:kMBProjectRun] ||
          [projectArrayController_ isAnySelectedProjectInState:kMBProjectProductionRun]);
}

// Split out to make unit testing easier.
- (BOOL)anyStopped {
  return [projectArrayController_ isAnySelectedProjectInState:kMBProjectStop];
}

// Return a contextual menu, suitable for projects, which has
// appropriate disabling of options which aren't relevant for the
// selection.
- (NSMenu *)configuredProjectMenu {
  // First, enable everything (reset).
  NSArray *items = [projectMenu_ itemArray];
  NSEnumerator *ienum = [items objectEnumerator];
  NSMenuItem *item = nil;
  while ((item = [ienum nextObject])) {
    [item setEnabled:YES];
  }

  // If nothing is running, disable stop/browse/SDK Console.
  if ([self anyRunning] == NO) {
    [[projectMenu_ itemWithTitle:kMBTStop] setEnabled:NO];
    [[projectMenu_ itemWithTitle:kMBTBrowse] setEnabled:NO];
    [[projectMenu_ itemWithTitle:kMBTSDKConsole] setEnabled:NO];
  }

  // If nothing is stopped, disable run/prod run.
  if ([self anyStopped] == NO) {
    [[projectMenu_ itemWithTitle:kMBTRun] setEnabled:NO];
    [[projectMenu_ itemWithTitle:kMBTRunStrict] setEnabled:NO];
  }

  // Finally, return the menu.
  return projectMenu_;
}

// Override default behavior to return a contextual menu for the
// specified event.  Thanks to
// http://www.cocoadev.com/index.pl?RightClickSelectInTableView
- (NSMenu *)menuForEvent:(NSEvent *)theEvent {

  BOOL currentRowIsSelected = NO;

  // Assumption: left mouse only gets us here on control-click; normal
  // left-click doesn't trigger a menuForEvent: call.  (That's true
  // experimentally but perhaps I need more checks to eliminate other
  // cases I haven't thought of?)
  if (([theEvent type] == NSRightMouseDown) ||
      ([theEvent type] == NSLeftMouseDown)) {
    // Get the current selections for the outline view. 
    NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
    
    // Select the row that was clicked before showing the menu for the event
    NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow]
                                   fromView:nil];
    int row = [self rowAtPoint:mousePoint];
    
    // Figure out if the row that was just clicked on is currently selected
    if ([selectedRowIndexes containsIndex:row] == NO) {
      [self selectRow:row byExtendingSelection:NO];
    }
    // Else that row is currently selected, so don't change anything.
    // Or it's over a row with no data (not selectable).
    if ([self isRowSelected:row]) {
      currentRowIsSelected = YES;
    }
  }

  // If we're over a project, return the project menu.
  // Else return a basic 'add projects' menu.
  if (currentRowIsSelected) {
    return [self configuredProjectMenu];
  } else {
    return mainViewMenu_;
  }
}

@end
