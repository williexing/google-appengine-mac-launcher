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

#import "MBProjectArrayController.h"
#import "MBTaskArrayController.h"
#import "MBProject.h"
#import "MBEngineRuntime.h"
#import "MBProjectInfoController.h"
#import "MBDeployController.h"
#import "MBPreferenceController.h"
#import "MBPreferences.h"

@implementation MBProjectArrayController

// Verifies all projects in our data (MBProject array).
// Project names can be updated based on file changes.
- (void)verifyAllProjects:(id)obj {
  NSEnumerator *penum = [[self content] objectEnumerator];
  MBProject *project = nil;

  while ((project = [penum nextObject])) {
    // [MBProject verify] will update the project, and set it's state
    // (valid or not).  We ignore the return value.  An appropriate
    // KVC Transformer will turn a [MBProject valid] return into a
    // text color change.
    [project verify];
  }
}

static NSString *MBProjectPboardType = @"MBProject";

// Configure the main table view in ways that can't be done in the
// nib.  As an example, we can't specify drag destination types in a
// nib.
- (void)configureTableView {
  [mainTableView_ setAllowsEmptySelection:NO];
  NSArray *types = [NSArray arrayWithObjects:NSStringPboardType,
                            NSFilenamesPboardType,
                            MBProjectPboardType,
                            nil];
  [mainTableView_ registerForDraggedTypes:types];
  [mainTableView_ setDataSource:self];

  // NSDragOperationLink means when we drag to X, we get Y:
  // Finder: symlink created
  // Emacs: dired-mode
  // TextEdit.app: a folder icon
  // That behavior is what XCode uses, so it seems appropriate.
  // If you want to copy just the filename, use cut-and-paste.
  [mainTableView_ setDraggingSourceOperationMask:NSDragOperationLink
                                        forLocal:NO];
}

// Special delegate method for data displayed in a table view.
// Drag initiated.
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes
     toPasteboard:(NSPasteboard*)pboard {
  GMAssert(mainTableView_ == tv, nil);

  // Declare all types we know about.
  [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType,
                                NSFilenamesPboardType,
                                MBProjectPboardType,
                                nil] owner:self];

  // Copy the row numbers to the pasteboard.  Used for internal
  // dragging (i.e. project rearrangement within the table).
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
  [pboard setData:data forType:MBProjectPboardType];

  // Copy the projects as strings...
  NSUInteger i;
  NSArray *content = [self content];
  if ([rowIndexes count] == 1) {
    // don't add a newline if there is just one
    [pboard setString:[[content objectAtIndex:[rowIndexes firstIndex]] path]
              forType:NSStringPboardType];
  } else {
    NSMutableString *string = [NSMutableString string];
    for (i = [rowIndexes firstIndex];
         i != NSNotFound;
         i = [rowIndexes indexGreaterThanIndex:i]) {
      [string appendFormat:@"%@\n", [[content objectAtIndex:i] path]];
    }
    [pboard setString:string forType:NSStringPboardType];
  }

  // And as filenames.  An NSFilenamesPboardType uses an NSArray of
  // NSStrings, transmitted across the pasteboard as a property list.
  NSMutableArray *filenames = [NSMutableArray array];
  for (i = [rowIndexes firstIndex];
       i != NSNotFound;
       i = [rowIndexes indexGreaterThanIndex:i]) {
    [filenames addObject:[[content objectAtIndex:i] path]];
  }
  [pboard setPropertyList:filenames forType:NSFilenamesPboardType];

  return YES;
}

// Special delegate method for data displayed in a table view.
// Drop validation.
- (NSDragOperation)tableView:(NSTableView*)tv
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(int)row
       proposedDropOperation:(NSTableViewDropOperation)op {
  return NSDragOperationEvery;
}

// Special delegate method for data displayed in a table view.
// Drop acceptance.
- (BOOL)tableView:(NSTableView *)aTableView
       acceptDrop:(id <NSDraggingInfo>)info
              row:(int)row
    dropOperation:(NSTableViewDropOperation)operation {
  NSPasteboard *pb = [info draggingPasteboard];

  NSData *rowData = [pb dataForType:MBProjectPboardType];
  if (rowData) {
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    int dragRow = [rowIndexes firstIndex];
    // dragRow is source; row is dest.  Moving an object to the end
    // gives an invalid array index, so we be careful.
    NSMutableArray *content = [self content];
    if (row >= (int)[content count]) {
      id obj = [content objectAtIndex:dragRow];
      [content removeObjectAtIndex:dragRow];
      [content addObject:obj];
    } else {
      [content exchangeObjectAtIndex:dragRow withObjectAtIndex:row];
      [self saveProjects];
    }
    [mainProjectView_ setNeedsDisplay:YES];
    return YES;
  }

  // D&D of a string or filename always places the new project at the
  // end of the list.
  // TODO(jrg): does that feel awkward?

  NSString *string = [pb stringForType:NSStringPboardType];
  if (string) {
    [self addProjectForDirectory:string];
    return YES;
  }

  NSArray *files = [pb propertyListForType:NSFilenamesPboardType];
  if (files) {
      // TODO(jrg): Is it possible for someone to lie like this across
      // the pasteboard?
    if ([files isKindOfClass:[NSArray class]] == NO)
      return NO;
    NSString *file = nil;
    NSEnumerator *fenum = [files objectEnumerator];
    while ((file = [fenum nextObject]) != nil) {
      [self addProjectForDirectory:file];
    }
    return YES;
  }

  // How could we get here?
  return NO;
}

- (BOOL)isAnySelectedProjectInState:(MBRunState)state {
  NSEnumerator *en = [[self currentProjects] objectEnumerator];
  MBProject *project;
  while ((project = [en nextObject])) {
    if ([project runState] == state)
      return YES;
  }
  return NO;
}

- (BOOL)isAnySelectedProjectNotInState:(MBRunState)state {
  NSEnumerator *en = [[self currentProjects] objectEnumerator];
  MBProject *project;
  while ((project = [en nextObject])) {
    if ([project runState] != state)
      return YES;
  }
  return NO;
}

- (BOOL)selectorArray:(SEL*)array containsSelector:(SEL)selector {
  BOOL hasSel = NO;
  while (*array) {
    if (selector == *array) {
      hasSel = YES;
      break;
    }
    ++array;
  }
  return hasSel;
}

// Called by the toolbar to see whether a given toolbar item is valid.
- (BOOL)validateUserInterfaceItem:(NSToolbarItem *)theItem {
  SEL action = [theItem action];
  BOOL anyRunning = ([self isAnySelectedProjectInState:kMBProjectRun] ||
                     [self isAnySelectedProjectInState:kMBProjectProductionRun]);
  SEL needAnyRunning[] = {
    @selector(browseCurrentProjects:),
    @selector(doAdminConsoleForCurrentProjects:),
    NULL
  };
  SEL needAnyProjects[] = {
    @selector(openFinderForCurrentProjects:),
    @selector(doConsoleForCurrentProjects:),
    @selector(infoOnCurrentProjects:),
    @selector(deployCurrentProjects:),
    @selector(openDashboardForCurrentProjects:),
#if DO_TERMINAL_TOOLBAR_BUTTON
    @selector(openTerminalForCurrentProjects:),
#endif  // DO_TERMINAL_TOOLBAR_BUTTON
#if DO_EDIT_TOOLBAR_BUTTON
    @selector(editCurrentProjects:),
#endif  // DO_EDIT_TOOLBAR_BUTTON
    NULL
  };
  if (action == @selector(runCurrentProjects:)) {
    return [self isAnySelectedProjectInState:kMBProjectStop];
  } else if (action == @selector(productionRunCurrentProjects:)) {
    return [self isAnySelectedProjectNotInState:kMBProjectProductionRun];
  } else if (action == @selector(stopCurrentProjects:)) {
    return anyRunning || [self isAnySelectedProjectInState:kMBProjectDied];
  } else if ([self selectorArray:needAnyRunning containsSelector:action]) {
    return anyRunning;
  } else if ([self selectorArray:needAnyProjects containsSelector:action]) {
    return [[self currentProjects] count] > 0 ? YES : NO;
  }
  return YES;
}

- (void)awakeFromNib {
  [self loadProjects];

  // TODO(jrg): this didn't appear to do anything.
  // Do I want to keep it?
  [self setAvoidsEmptySelection:YES];

  [self configureTableView];

  if ([[self selectedObjects] count] > 0)
    [self setSelectionIndex:0];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                        selector:@selector(verifyAllProjects:)
                                        name:NSApplicationWillBecomeActiveNotification
                                        object:nil];

  // dbl-click on a project runs "Get Info"
  [mainTableView_ setTarget:self];
  [mainTableView_ setDoubleAction:@selector(infoOnCurrentProjects:)];
}

- (NSArray *)currentProjects {
  NSArray *a = [self selectedObjects];
  if ([a count] == 0) {
    // If there is nothing selected but we only have one project, we
    // assume it's the "current project" to try and be friendly.
    if ([[self content] count] == 1) {
      a = [NSArray arrayWithObject:[[self content] objectAtIndex:0]];
    } else {
      // nothing selected; multiple projects around.
    }
  }
  return a;
}

- (int)unusedProjectPort {
  if ([[self content] count] == 0)
    return 8080;
  NSEnumerator *penum = [[self content] objectEnumerator];
  MBProject *p = nil;
  int maxPort = 0;
  int projectPort = 0;
  while ((p = [penum nextObject])) {
    projectPort = [[p port] intValue];
    if (projectPort > maxPort)
      maxPort = projectPort;
  }
  return maxPort+1;
}

- (void)addProject:(MBProject *)project {
  NSEnumerator *penum = [[self content] objectEnumerator];
  MBProject *p = nil;
  NSString *path = nil;
  while ((p = [penum nextObject])) {
    path = [p path];
    if ([path isEqual:[project path]]) {
      GMLoggerError(@"Sorry, you already have a project named \"%@\" at that path.",
                    [project name]);
      return;
    }
  }
  [self addObject:project];
  [self saveProjects];
  [self verifyAllProjects:nil];
}

- (void)addProjectForDirectory:(NSString *)dirname {
  NSString *portString = [NSString stringWithFormat:@"%d",
                                   [self unusedProjectPort]];
  MBProject *project = [MBProject projectWithName:[dirname lastPathComponent]
                                  path:dirname
                                  port:portString];
  [self addProject:project];
}

- (void)removeProject:(MBProject *)project {
  [taskController_ removeConsoleForProject:project];
  [self removeObject:project];
  [self saveProjects];
  [self verifyAllProjects:nil];
}

- (NSArray *)projects {
  return [self content];
}

// This starts the given array of projects. It's called by the two IBAction
// methods below.
- (void)startProjects:(NSArray *)projects inProduction:(BOOL)production {
  MBRunState targetState, alternateState;
  NSNumber *targetStateIsProduction;  // used by callback
  if (!production) {
    targetState = kMBProjectRun;
    alternateState = kMBProjectProductionRun;
    targetStateIsProduction = [NSNumber numberWithBool:NO];
  } else {
    targetState = kMBProjectProductionRun;
    alternateState = kMBProjectRun;
    targetStateIsProduction = [NSNumber numberWithBool:YES];
  }

  NSEnumerator *aenum = [projects objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    if (project && ([project runState] != targetState)) {
      if ([project runState] == alternateState) {
        [taskController_ stopTaskForProject:project];
      }
      if ([project runState] == kMBProjectStarting) {
        // silently ignore
        continue;
      }
      [project setRunState:kMBProjectStarting];
      SEL sel = @selector(successfulStartForProject:inProduction:);
      NSInvocation *callback = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector:sel]];
      [callback setTarget:self];
      [callback setSelector:sel];
      [callback setArgument:&project atIndex:2];
      [callback setArgument:&targetStateIsProduction atIndex:3];
      [callback retainArguments];

      BOOL success = [taskController_ runTaskForProject:project
                                    callbackWhenRunning:callback];
      if (!success) {
        GMLoggerError(@"Whoa; can't start project %@", [project name]);
      }
      [mainProjectView_ setNeedsDisplay:YES];
    }
  }
}

- (IBAction)runCurrentProjects:(id)sender {
  [self startProjects:[self currentProjects] inProduction:NO];
}

- (IBAction)productionRunCurrentProjects:(id)sender {
  [self startProjects:[self currentProjects] inProduction:YES];
}

// Called when a project finishes starting.
- (void)successfulStartForProject:(MBProject *)project
                     inProduction:(NSNumber *)inProduction {
  if (![inProduction boolValue]) {
    [project setRunState:kMBProjectRun];
  } else {
    [project setRunState:kMBProjectProductionRun];
  }
  [mainProjectView_ setNeedsDisplay:YES];
}

// Called when a project task died, which may have been expected.
// E.g. deploy is done.
- (void)deathForProject:(MBProject *)project {
  [project setRunState:kMBProjectStop];
  [mainProjectView_ setNeedsDisplay:YES];
}

// Called when a project died unexpectedly.
- (void)unexpectedDeathForProject:(MBProject *)project {
  if (([project runState] == kMBProjectRun) ||
      ([project runState] == kMBProjectProductionRun) ||
      ([project runState] == kMBProjectStarting)) {
    [project setRunState:kMBProjectDied];
    [mainProjectView_ setNeedsDisplay:YES];
  }
}

- (void)stopProject:(MBProject *)project {
  if (project != nil) {
    BOOL success = NO;
    switch ([project runState]) {
      case kMBProjectRun:
      case kMBProjectProductionRun:
      case kMBProjectStarting:
        // Do we care if stop returned NO?
        /* success = */ [taskController_ stopTaskForProject:project];
        success = YES;
        break;
      case kMBProjectDied:
        success = YES;  // allows "died" --> "off" transition
        break;
      default:
        break;
    }
    if (success) {
      [project setRunState:kMBProjectStop];
      [mainProjectView_ setNeedsDisplay:YES];
    }
  }
}

- (IBAction)stopCurrentProjects:(id)sender {
  NSArray *a = [self currentProjects];
  NSEnumerator *aenum = [a objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    [self stopProject:project];
  }
}

// Generic routine to open the browser to a URL for all selected
// projects.  |urlBase| is the basic URL, used in [NSString
// stringWithFormat:]; it is expected to contain an %@, which will be
// replaced by the local port number for each project.
- (IBAction)genericBrowseForCurrentProjects:(id)sender
                                    urlBase:(NSString *)urlBase {
  NSArray *a = [self currentProjects];
  NSEnumerator *aenum = [a objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    if (([project runState] == kMBProjectRun) ||
        ([project runState] == kMBProjectProductionRun)) {
      NSString *urlString = [NSString stringWithFormat:urlBase,
                                      [project port]];
      NSURL *url = [NSURL URLWithString:urlString];

      // If you jump to the URL too soon after starting a project, it's
      // not listening yet!
      //
      // TODO(jrg):
      // For now, try 10 times over 2.5 seconds for it to start.
      // But don't be so synchronous; use a retry on a timer so
      // the UI stays responsive.
      NSURLRequest *request = [NSURLRequest requestWithURL:url];
      for (int i = 0; i < 10; i++) {
        if ([NSURLConnection canHandleRequest:request] == YES) {
          break;
        } else {
          [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }
      }
      BOOL opened = [[NSWorkspace sharedWorkspace] openURL:url];
      if (opened == NO) {
        GMLoggerError(@"Failed to open URL %@", urlString);
      }
    }
  }
}

- (IBAction)browseCurrentProjects:(id)sender {
  [self genericBrowseForCurrentProjects:sender
                                urlBase:@"http://localhost:%@"];
}

- (IBAction)doAdminConsoleForCurrentProjects:(id)sender {
  [self genericBrowseForCurrentProjects:sender
                                urlBase:@"http://localhost:%@/_ah/admin"];
}

- (IBAction)doConsoleForCurrentProjects:(id)sender {
  NSArray *a = [self currentProjects];
  NSEnumerator *aenum = [a objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    [taskController_ doConsoleForProject:project showItNow:YES];
  }
}

- (IBAction)infoOnCurrentProjects:(id)sender {
  NSArray *a = [self currentProjects];
  NSEnumerator *aenum = [a objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    MBProjectInfoController *controller = [[[MBProjectInfoController alloc]
                                            initWithProject:project]
                                            autorelease];
    GMAssert([controller window], @"no window in nib!");

    [NSApp beginSheet:[controller window]
       modalForWindow:[mainProjectView_ window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    NSInteger rtn = [NSApp runModalForWindow:[controller window]];
    [NSApp endSheet:[controller window]];
    [controller close];
    if (rtn == NSOKButton) {
      // only need to save if something changed
      [self saveProjects];
    }
    // MBProjectInfoController will update the project as needed.

    // TODO(jrg): We are inconsistent.  MBProjectInfoController
    // modifies the data (MBProject) itself.  This contrasts with
    // other dialogs triggered from here (new app, add existing app).
    // For those other dialogs, the caller checks its text fields et
    // al and does the right thing.  One reason for the difference is
    // that the MBProjectInfoController displays the data in a special
    // way (e.g. checkbox for --clear_datastore and text field for all
    // else) which isn't a direct match to the way these flags are
    // stored in the MBProject.  Perhaps it's a good idea to keep the
    // M and V (in the MVC world) split?
  }
}

#if DO_EDIT_TOOLBAR_BUTTON
- (IBAction)editCurrentProjects:(id)sender {
  NSString *editor = [[[NSUserDefaults standardUserDefaults]
                        stringForKey:kMBEditorPref] lastPathComponent];
  if (editor == nil || [editor length] == 0) {
    editor = @"TextEdit.app";
  }
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  if ([ws fullPathForApplication:editor] == nil) {
    GMLoggerError(@"Sorry, I can't find %@", editor);
  } else {
    NSArray *a = [self currentProjects];
    NSEnumerator *aenum = [a objectEnumerator];
    MBProject *project = nil;
    BOOL editDirectory = [[NSUserDefaults standardUserDefaults]
                          boolForKey:kMBEditDirectoryPref];
    while ((project = [aenum nextObject])) {
      NSString *path = [project path];
      if (!(editDirectory ||
            [editor isEqual:@"BBEdit.app"] ||
            [editor isEqual:@"TextMate.app"] ||
            [editor isEqual:@"Emacs.app"])) {
        path = [path stringByAppendingPathComponent:@"app.yaml"];
      }
      if (![ws openFile:path withApplication:editor]) {
        GMLoggerError(@"Sorry, I had a problem opening %@ in %@",
                      [[project path] lastPathComponent], editor);
      }
    }
  }
}
#endif  // DO_EDIT_TOOLBAR_BUTTON

#if DO_TERMINAL_TOOLBAR_BUTTON
- (IBAction)openTerminalForCurrentProjects:(id)sender {
  NSArray *a = [self currentProjects];
  NSEnumerator *aenum = [a objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    NSString *script = [NSString stringWithFormat:@"tell Application \"Terminal.app\" to do script \"cd %@\"",
                                 [project path]];
    NSAppleScript *as = [[[NSAppleScript alloc] initWithSource:script] autorelease];
    NSDictionary *info = nil;
    if ([as executeAndReturnError:&info] == nil) {
      GMLoggerError(@"Sorry, I had a problem opening %@ in Terminal.app");
    }
  }
}
#endif  // DO_TERMINAL_TOOLBAR_BUTTON

- (IBAction)openFinderForCurrentProjects:(id)sender {
  NSArray *a = [self currentProjects];
  NSEnumerator *aenum = [a objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    BOOL opened = [[NSWorkspace sharedWorkspace] openFile:[project path]];
    if (opened == NO)
      GMLoggerError(@"Sorry, I can't open \"%@\"", [project path]);
  }
}

// Uses new-style auth dialog
- (IBAction)deployCurrentProjects:(id)sender {
  NSArray *projects = [self currentProjects];
  if ([projects count] == 0)
    return;

  NSEnumerator *aenum = [projects objectEnumerator];
  MBProject *project = nil;
  // TODO(jrg): we shouldn't need to stop, but I'm recycling some UI...
  // TODO(jrg): don't allow a deploy in the middle of a deploy!
  while ((project = [aenum nextObject])) {
    if (([project runState] == kMBProjectProductionRun) ||
        ([project runState] == kMBProjectRun)) {
      [taskController_ stopTaskForProject:project];
      [project setRunState:kMBProjectStop];
      [mainProjectView_ setNeedsDisplay:YES];
    }

    // Can't do this yet; cancel in the auth dialog leaves the project
    // 'running' forever.
#if 0
    [project setRunState:kMBProjectRun];  // looks like it's running!
    [mainProjectView_ setNeedsDisplay:YES];
#endif

  }

  [deployController_ deploy:projects parentWindow:[mainProjectView_ window]];
}

- (IBAction)openDashboardForCurrentProjects:(id)sender {

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *dashboardBase = @"http://appengine.google.com/dashboard?app_id=";
  NSString *dashboardMachine = [defaults stringForKey:kMBDashboardPref];
  if (dashboardMachine) {
    dashboardBase = [NSString stringWithFormat:@"http://%@/dashboard?app_id=",
                              dashboardMachine];
  }
  NSArray *a = [self currentProjects];
  NSEnumerator *aenum = [a objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    NSString *urlString = [NSString stringWithFormat:@"%@%@",
                                    dashboardBase,
                                    [project name]];
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL opened = [[NSWorkspace sharedWorkspace] openURL:url];
    if (opened == NO) {
      GMLoggerError(@"Failed to open URL %@", urlString);
    }
  }
}

// Loads the nib named |nibname|, assumed to contain an
// MBAddAppController subclass.  After some generic configuration, it
// displays a dialog modally.  On Cancel, clean up properly and
// return nil.  Else return the controller so the caller can collect
// data from it.  The object returned, if any, is autoreleased.
- (MBAddAppController *)addApp:(NSString *)nibname
           withControllerClass:(Class)addControllerClass {
  // TODO(jrg): Runtime "GoogleAppEngine 1.0" is hard-coded in the (disabled) popup menu
  NSString *portString = [NSString stringWithFormat:@"%d",
                                   [self unusedProjectPort]];
  MBAddAppController *controller = [[[addControllerClass alloc]
                                     initWithWindowNibName:nibname
                                     port:portString]
                                     autorelease];
  GMAssert([controller window], @"no window in %@.nib", nibname);
  GMAssert([controller isKindOfClass:addControllerClass], @"bad class in nib");

  [NSApp beginSheet:[controller window]
     modalForWindow:[mainProjectView_ window]
      modalDelegate:nil
     didEndSelector:nil
        contextInfo:nil];
  NSInteger rtn = [NSApp runModalForWindow:[controller window]];
  [NSApp endSheet:[controller window]];
  [controller close];
  if ((rtn == NSRunStoppedResponse) ||
      (rtn == NSRunAbortedResponse) ||
      (rtn == NSCancelButton)) {
    // Cancel; do nothing.
  } else if (rtn == NSOKButton) {
    return controller;
  } else {
    // seems a little brutal to assert here...
  }

  return nil;
}

- (IBAction)addExistingApp:(id)sender {
  MBAddExistingAppController *controller =
      (MBAddExistingAppController *)[self addApp:@"AddExisting"
                             withControllerClass:[MBAddExistingAppController class]];
  if (controller == nil)
    return;

  NSString *path = [controller path];
  NSString *port = [controller port];
  MBProject *project = [MBProject projectWithName:[path lastPathComponent]
                                             path:path
                                             port:port];
  [self addProject:project];
}

- (IBAction)addNewApp:(id)sender {
  MBAddNewAppController *controller =
      (MBAddNewAppController *)[self addApp:@"AddNew"
                        withControllerClass:[MBAddNewAppController class]];
  if (controller == nil)
    return;

  MBEngineRuntime *runtime = [MBEngineRuntime defaultRuntime];
  GMAssert(runtime, @"Must have a runtime to find new project templates");

  NSString *template = [runtime newAppTemplateDirectory];
  NSString *dest = [[controller directory] stringByAppendingPathComponent:[controller name]];
  BOOL worked = [[NSFileManager defaultManager] copyPath:template
                                                  toPath:dest
                                                handler:nil];
  if (worked == NO) {
    GMLoggerError(@"A directory or file named %@ may already exist, "
                  "or you may not have permission to create it.",
                  dest);
    return;
  }

  NSArray *args = [NSArray arrayWithObjects:@"-R", @"u+w", dest, nil];
  NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/bin/chmod"
                         arguments:args];
    [task waitUntilExit];

  // Now fix the default project
  NSString *appYamlFile = [dest stringByAppendingPathComponent:@"app.yaml"];
  NSMutableString *yamlString = [NSMutableString stringWithContentsOfFile:appYamlFile
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:NULL];
  [yamlString replaceOccurrencesOfString:@"new-project-template"
              withString:[controller name]
                 options:NSLiteralSearch
                   range:NSMakeRange(0, [yamlString length])];
  worked = [yamlString writeToFile:appYamlFile
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:NULL];
  if (worked == NO) {
    GMLoggerError(@"Can't setup new project correctly.");
    return;
  }

  MBProject *project = [MBProject projectWithName:[controller name]
                                             path:dest  // full path!
                                             port:[controller port]];
  [self addProject:project];
}

- (IBAction)addDemoApp:(id)sender {
  NSString *title = [sender title];
  NSString *oldPath = [taskController_ fullpathForDemo:title];
  NSString *port = [NSString stringWithFormat:@"%d", [self unusedProjectPort]];
  if (title && oldPath && port) {
    NSString *newPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(),
                                  title];
    int count = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
      newPath = [NSString stringWithFormat:@"%@/%@-%d", NSHomeDirectory(),
                          title, count++];
    }
    [[NSFileManager defaultManager] copyPath:oldPath
                                      toPath:newPath
                                      handler:nil];

    NSArray *args = [NSArray arrayWithObjects:@"-R", @"u+w", newPath, nil];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/bin/chmod"
                                            arguments:args];
    [task waitUntilExit];

    // TODO(jrg): confirm?
    MBProject *project = [MBProject project];
    [project setName:title];
    [project setPath:newPath];
    [project setPort:port];
    [self addProject:project];
  }
}

- (IBAction)removeApps:(id)sender {
  NSArray *a = [self currentProjects];

  // TODO(jrg): abstract so testing is easier
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  [alert setMessageText:@"Remove Application"];
  NSString *text = [NSString stringWithFormat:@"Remove %d items from the project?"
                             "  (The on-disk content will not be modified.)",
                             [a count]];
  [alert setInformativeText:text];
  [alert addButtonWithTitle:@"Remove"];
  [alert addButtonWithTitle:@"Cancel"];
  /*
  [alert beginSheetModalForWindow:[mainTableView_ window]
                    modalDelegate:nil
                   didEndSelector:nil
                      contextInfo:nil];
  */
  NSInteger rtn = [alert runModal];
  // [NSApp endSheet:[alert window]];
  if (rtn != NSAlertFirstButtonReturn) {
    return;
  }

  NSEnumerator *aenum = [a objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    if ([project runState] == kMBProjectRun) {
      [self stopProject:project];
    }
    [self removeProject:project];
  }
}

- (IBAction)makeCommandLineSymlinks:(id)sender {
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  [alert setMessageText:@"Make Command Symlinks?"];
  NSString *text = [NSString stringWithFormat:@"The Google App Engine SDK "
                             "contains command-line programs used by "
                             "GoogleAppEngineLauncher.app.  "
                             "Would you like symbolic links "
                             "for these programs, "
                             "such as dev_appserver.py, to be made in "
                             "/usr/local/bin?\nThis action will replace links "
                             "which may currently exist.\n\n"
                             "An authorization will be required."];
  [alert setInformativeText:text];
  [alert addButtonWithTitle:@"OK"];
  [alert addButtonWithTitle:@"Cancel"];
  /*
  [alert beginSheetModalForWindow:[mainTableView_ window]
                    modalDelegate:nil
                   didEndSelector:nil
                      contextInfo:nil];
  */
  NSInteger rtn = [alert runModal];
  // [NSApp endSheet:[alert window]];
  if (rtn == NSAlertFirstButtonReturn) {
    // new alert since we can't remove buttons...
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    NSString *summary = [[MBEngineRuntime defaultRuntime] makeLinks];
    if ([summary isEqual:@""])
      return;
    [alert setMessageText:@"Symlink Status"];
    text = [NSString stringWithFormat:@"Symbolic links in /usr/local/bin have "
                     "been created for the following commands:\n\n"
                     "%@\n\n"
                     "In addition, /usr/local/google_appengine points "
                     "to the SDK.\n", summary];
    [alert setInformativeText:text];
    [alert addButtonWithTitle:@"OK"];
    /*
    [alert beginSheetModalForWindow:[mainTableView_ window]
                      modalDelegate:nil
                     didEndSelector:nil
                        contextInfo:nil];
    */
    rtn = [alert runModal];
    // [NSApp endSheet:[alert window]];
  }
}

- (IBAction)showPreferencePanel:(id)sender {
  MBPreferenceController *prefController = [MBPreferenceController sharedController];
  [prefController showWindow:self];
}

// Make sure the directory which contains our project file exists.
- (void)createProjectSaveDirectory {
  // Can't [NSFileManager createDirectoryAtPath:withIntermediateDirectories:]
  // since we need to work on 10.4
  NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:
                                    @"Library/Application Support/GoogleAppEngineLauncher"];
  [[NSFileManager defaultManager] createDirectoryAtPath:dir attributes:nil];
}

- (NSString *)projectSavePath {
  return [NSHomeDirectory() stringByAppendingPathComponent:
                           @"Library/Application Support/GoogleAppEngineLauncher/Projects.plist"];
}

// TODO(jrg): add some asserts...
- (void)loadProjects {
  [self createProjectSaveDirectory];
  [[self content] removeAllObjects];
  NSString *path = [self projectSavePath];
  NSData *data = [NSData dataWithContentsOfFile:path];
  if (data) {
    NSKeyedUnarchiver *unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data]
                                      autorelease];
    NSArray *projects = [unarchiver decodeObjectForKey:@"projects"];
    [unarchiver finishDecoding];
    if (projects)
      [self addObjects:projects];
  }
  [self verifyAllProjects:nil];
}

- (void)saveProjects {
  [self createProjectSaveDirectory];
  NSString *path = [self projectSavePath];
  NSArray *projects = [self content];
  NSMutableData *data = [NSMutableData data];
  NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data]
                                autorelease];
  [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
  [archiver encodeObject:projects forKey:@"projects"];
  [archiver finishEncoding];
  BOOL worked = [data writeToFile:path atomically:YES];
  if (worked == NO)
    GMLoggerError(@"Can't write project file to %@", path);
}

- (NSWindow *)mainProjectWindow {
  return [mainProjectView_ window];
}

@end


