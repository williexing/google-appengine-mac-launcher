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
#import "MBAddExistingAppController.h"
#import "MBAddNewAppController.h"
#import "MBProject.h"

@class MBTaskArrayController;
@class MBDeployController;

// The main C (in MVC) for the launcher.  Controller for an array of
// projects, the main group of static data.  Controller for the main
// project window, and most UI action (e.g. menus).
@interface MBProjectArrayController : NSArrayController {
  IBOutlet MBTaskArrayController *taskController_;
  IBOutlet NSView *mainProjectView_;
  IBOutlet NSTableView *mainTableView_;
  IBOutlet MBDeployController *deployController_;
}
// convenience
- (NSArray *)currentProjects;

// Find a port not used by any current project.
// If we have no projects, return 8000.
- (int)unusedProjectPort;

// Add a new project.  May fail if already there.
- (void)addProject:(MBProject *)project;

// Add a new project when only the directory name is known.
- (void)addProjectForDirectory:(NSString *)dirname;

// Remove a project.
- (void)removeProject:(MBProject *)project;

// Return the list of projects.
// Only exposed for unit testing.
- (NSArray *)projects;

// Called from the task controller.
- (void)deathForProject:(MBProject *)project;
- (void)unexpectedDeathForProject:(MBProject *)project;

// Actions from the toolbar or menu commands.
// Most are self-explanatory.
- (IBAction)runCurrentProjects:(id)sender;
- (IBAction)productionRunCurrentProjects:(id)sender;
- (IBAction)stopCurrentProjects:(id)sender;
- (IBAction)browseCurrentProjects:(id)sender;
- (IBAction)doConsoleForCurrentProjects:(id)sender;
- (IBAction)doAdminConsoleForCurrentProjects:(id)sender;
- (IBAction)infoOnCurrentProjects:(id)sender;
- (IBAction)openFinderForCurrentProjects:(id)sender;
- (IBAction)deployCurrentProjects:(id)sender;
- (IBAction)openDashboardForCurrentProjects:(id)sender;

// No "edit" until we can set a pref to choose the editor.
#if DO_EDIT_TOOLBAR_BUTTON
- (IBAction)editCurrentProjects:(id)sender;
#endif  // DO_EDIT_TOOLBAR_BUTTON

// Not as useful as originally expected.
#if DO_TERMINAL_TOOLBAR_BUTTON
- (IBAction)openTerminalForCurrentProjects:(id)sender;
#endif

// Actions from the view (window) buttons or menu commands.
// Most are self-explanatory.
- (IBAction)addNewApp:(id)sender;
- (IBAction)addExistingApp:(id)sender;
- (IBAction)addDemoApp:(id)sender;
- (IBAction)removeApps:(id)sender;
- (IBAction)makeCommandLineSymlinks:(id)sender;

// TODO(jrg): this is the wrong spot but I'm out of time.
- (IBAction)showPreferencePanel:(id)sender;

// Return a full path to our project save path.
// Exposed in the interface to allow easier unit testing.
- (NSString *)projectSavePath;

// We are not a document-based app; the list of projects (for
// load/save) comes from a plist in ~/Library/Preferences.
- (void)loadProjects;
- (void)saveProjects;

// So the task controller can beginSheet:modalForWindow: properly.
- (NSWindow *)mainProjectWindow;

// To allow others (e.g. MBMainTableView) to configure menu enabling
// based on current state (e.g. disable 'Stop' option if nothing is
// running.)
- (BOOL)isAnySelectedProjectInState:(MBRunState)state;
- (BOOL)isAnySelectedProjectNotInState:(MBRunState)state;

@end
