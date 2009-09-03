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
#import "MBProject.h"

@class MBProjectArrayController;
@class MBEngineRuntime;
@class MBEngineTask;
@class MBConsoleController;

// This is the 2nd main controller for the launcher.  Our data (model) is
// a list of running tasks (MBEngineTasks).  Our view is the
// console windows, one per task.
@interface MBTaskArrayController : NSArrayController {
  IBOutlet MBProjectArrayController *projectController_;
  IBOutlet NSMenuItem *demoMenu_;

  // In the future projects will have a choice of runtime.  This
  // field, which will become an array, will probably move to
  // MBProjectArrayController (for selection in "New Project", "Get
  // Info", etc.  Until then it's convenient to have in here.
  MBEngineRuntime *launcherRuntime_;

  // Array of MBConsoleControllers indexed by an MBProject's unique ID.
  // Although they show outout of an MBEngineTask (above), they
  // exist for the lifetime of an MBProject, not the lifetime of it's
  // task (So stop/start doesn't clear the log.)
  NSMutableDictionary *consoleWindows_;
}

// Try and exit gracefully.  Called from awakeFromNib
// TODO(jrg): make private.
- (void)installCleanupHandlers;

// Convenience routines.  Returns nil if there is no running task for the given project.
- (MBEngineTask *)findEngineTaskForProject:(MBProject *)project;
- (MBEngineTask *)findEngineTaskForTask:(NSTask *)task;

// Triggered by IBActions.
// If callback is not nil, it will be added as the hook in MBLogFilter to be
// called when the project is fully running.
- (BOOL)runTaskForProject:(MBProject *)project
      callbackWhenRunning:(NSInvocation *)callback;
- (BOOL)productionRunTaskForProject:(MBProject *)project
                callbackWhenRunning:(NSInvocation *)callback;
- (BOOL)stopTaskForProject:(MBProject *)project;

// Triggered by an IBAction once removed (called from MBDeployController)
// Command defaults to "update" if otherwise nil.
// TODO(jrg): abstraction issues!
- (BOOL)runDeployForProject:(MBProject *)project
                   username:(NSString *)username
                   password:(NSString *)password;

// When we're in trouble and need to quit, call this.  It tries to do
// the minimal work necessary to kill subprocesses.
- (void)interruptAllTasksUncleanly:(id)obj;

// A friendlier and cleaner version of the above call.
- (void)stopAllTasks;

- (void)disconnectConsoleFromTask:(MBEngineTask *)task;  // pipe level
- (MBConsoleController *)findConsoleForProject:(MBProject *)project;

// Close and deallocate window.
- (void)removeConsoleForProject:(MBProject *)project;

// Possibly show and/or create a console window for the specified project.
- (void)doConsoleForProject:(MBProject *)project showItNow:(BOOL)showItNow;

// For a demo named |title|, return the full path to find it.
- (NSString *)fullpathForDemo:(NSString *)title;

// Tell the project array controller what demos we have in our
// runtime, and where they live.
- (void)addDemos;

@end


