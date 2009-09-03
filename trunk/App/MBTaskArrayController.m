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

#import "MBTaskArrayController.h"
#include <unistd.h>
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#import "MBProjectArrayController.h"
#import "MBEngineRuntime.h"
#import "MBAlertWriter.h"
#import "MBEngineTask.h"
#import "MBConsoleController.h"
#import "MBSimpleProgressController.h"
#import "MBLogFilter.h"

@implementation MBTaskArrayController

// File descriptor for kqueue().
static int gLauncherSignalFD = 0;

// Called when it's time to die, triggered from a kevent on a signal.
// Taxed from markd2.
static __attribute__((noreturn)) void SocketCallBack(CFSocketRef socketref,
                                                     CFSocketCallBackType type,
                                                     CFDataRef address,
                                                     const void *data,
                                                     void *info)  {
  struct kevent event;

  if (kevent(gLauncherSignalFD, NULL, 0, &event, 1, NULL) == -1) {
    // sorry; you die.
  } else {
    MBTaskArrayController *c = (MBTaskArrayController *)event.udata;
    [c interruptAllTasksUncleanly:nil];
  }
  exit(0);

}  // SocketCallBack

// Do nothing function: default behavior for SIGTERM is to die.
// We can't ignore the signal, but don't want to die just yet.
// So we do_nothing() when we see it as a normal signal handler.
static void do_nothing(int sig) { }

// Hmm, this looks an awful lot like markd2 code.
- (void)handleSignal:(int)sig {

  // sa_handler can't be SIG_IGN or else child procs (prom tasks)
  // inherit the signal mask and can't be killed!
  struct sigaction sa;
  sa.sa_handler = do_nothing;
  sa.sa_flags = 0;
  sa.sa_mask = 0;
  sigaction(sig, &sa, NULL);

  // listen in a safer way
  if (gLauncherSignalFD == 0) {
    gLauncherSignalFD = kqueue();

    static CFSocketRef grunLoopSocket;
    CFSocketContext context = { 0, NULL, NULL, NULL, NULL };
    grunLoopSocket = CFSocketCreateWithNative(kCFAllocatorDefault,
                                              gLauncherSignalFD,
                                              kCFSocketReadCallBack,
                                              SocketCallBack,
                                              &context);
    CFRunLoopSourceRef rls;
    rls = CFSocketCreateRunLoopSource (NULL, grunLoopSocket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls,
                       kCFRunLoopDefaultMode);
    CFRelease(rls);
  }

  struct kevent ke;
  EV_SET(&ke,
         sig,
         EVFILT_SIGNAL,
         (EV_ADD | EV_ENABLE | EV_CLEAR),
         0, 0,
         (void*)self);
  const struct timespec noWait = { 0, 0 };
  kevent(gLauncherSignalFD, &ke, 1, NULL, 0, &noWait);
}

- (void)installCleanupHandlers {
  // Install a cleanup handler to catch app death (when possible) so
  // we can try to clean up running tasks.
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptAllTasksUncleanly:)
                                        name:NSApplicationWillTerminateNotification
                                        object:nil];
  [self handleSignal:SIGINT];   // ctrl-c
  [self handleSignal:SIGTERM];  // logout
}

- (void)awakeFromNib {
  // Make sure MBLogger is setup before we call something which may use it.
  // XXX - there has got to be a better way to do this.
  // TODO(jrg): obsolete, since this class is now recycled!
  if (gLauncherSignalFD == 0) {  // once-only
    [MBAlertWriter install];
    [self installCleanupHandlers];
  }
  launcherRuntime_ = [[MBEngineRuntime defaultRuntime] retain];
  consoleWindows_ = [[NSMutableDictionary alloc] init];

  // too early
  // [self addDemos];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(didFinishLaunching)
    name:NSApplicationDidFinishLaunchingNotification
    object:nil];

  setenv("NSUnbufferedIO", "YES", 1);
}

// called at NSApplicationDidFinishLaunchingNotification time
- (void)didFinishLaunching {
  BOOL extracting = [launcherRuntime_ extractionNeeded];
  MBSimpleProgressController *controller = nil;

  if (extracting) {
    controller = [[[MBSimpleProgressController alloc] init] autorelease];
    [NSApp beginSheet:[controller window]
       modalForWindow:[projectController_ mainProjectWindow]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    [controller startAnimation];
  }

  [launcherRuntime_ findRuntimeContents];

  if (extracting) {
    [NSApp endSheet:[controller window]];
    [controller close];
    [projectController_ makeCommandLineSymlinks:self];
  }

  [self addDemos];
}

- (void)dealloc {
  [self stopAllTasks];
  [launcherRuntime_ release];
  // TODO(jrg): stop tasks?  Close windows?
  [consoleWindows_ release];
  [super dealloc];
}

- (MBEngineTask *)findEngineTaskForProject:(MBProject *)project {
  NSEnumerator *tenum = [[self content] objectEnumerator];
  MBEngineTask *task = nil;
  while ((task = [tenum nextObject])) {
    if ([[task project] isEqual:project]) {
      return task;
    }
  }
  return nil;
}

- (MBEngineTask *)findEngineTaskForTask:(NSTask *)task {
  NSEnumerator *tenum = [[self content] objectEnumerator];
  MBEngineTask *mbtask = nil;
  while ((mbtask = [tenum nextObject])) {
    if ([[mbtask task] isEqual:task]) {
      return mbtask;
    }
  }
  return nil;
}

// Common "run task" method which accepts extra args
- (BOOL)genericRunTaskForProject:(MBProject *)project
             callbackWhenRunning:(NSInvocation *)callback
                      extraFlags:(NSArray *)extraFlags {
  MBEngineTask *task = [self findEngineTaskForProject:project];
  if (task != nil) {
    return NO;
  }

  // assert(launcherRuntime_);
  NSString *python = [launcherRuntime_ pythonCommand];
  NSMutableArray *args = [NSMutableArray array]; // full command line
  NSMutableArray *moreargs = [NSMutableArray array]; // all except das, project

  [moreargs addObjectsFromArray:[launcherRuntime_ extraCommandLineFlags]];
  [moreargs addObject:[NSString stringWithFormat:@"--port=%@", [project port]]];

  NSMutableArray *projectFlags = [NSMutableArray arrayWithArray:[project commandLineFlags]];
  [moreargs addObjectsFromArray:projectFlags];

  if (extraFlags)
    [moreargs addObjectsFromArray:extraFlags];

  // args = (dev_appserver.py + <args...> + <project>)
  [args addObject:[launcherRuntime_ devAppServer]];
  [args addObjectsFromArray:moreargs];
  [args addObject:[project path]];

  NSString *dir = [launcherRuntime_ devAppDirectory];
  NSMutableDictionary *environment = [NSMutableDictionary dictionary];
  [environment addEntriesFromDictionary:[[NSProcessInfo processInfo] environment]];
  [environment addEntriesFromDictionary:[launcherRuntime_ pythonExtraEnvironment]];

  // ALWAYS create a console window, even if never seen, so we have a
  // history of log output.
  [self doConsoleForProject:project showItNow:NO];

  // Now that we have a console (for sure), print some helpful text.
  MBConsoleController *console = [self findConsoleForProject:project];
  [console appendString:@"\n"];
  [console appendString:@"*** Running dev_appserver with the following flags:\n    "];
  [console appendString:[moreargs componentsJoinedByString:@" "]];
  [console appendString:@"\n"];
  [console appendString:[NSString stringWithFormat:@"Python command: %@\n", python]];

  task = [MBEngineTask taskWithProject:project];
  [task setLaunchPath:python];
  [task setArguments:args];
  [task setCurrentDirectoryPath:dir];
  [task setEnvironment:environment];
  [[self content] addObject:task];

  // Listen for an early death.
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(handleTaskDeathNotification:)
           name:NSTaskDidTerminateNotification
         object:[task task]];

  if (callback) {
    [[task logFilter] addProjectLaunchCompleteCallback:callback];
  }

  // Hook it up
  [console setEngineTask:task];

  // Finally, launch!
  [task launch];

  return YES;
}

- (BOOL)runTaskForProject:(MBProject *)project
      callbackWhenRunning:(NSInvocation *)callback {
  return [self genericRunTaskForProject:project
                    callbackWhenRunning:callback
                             extraFlags:nil];
}

- (BOOL)productionRunTaskForProject:(MBProject *)project
                callbackWhenRunning:(NSInvocation *)callback {
  NSArray *flags = [launcherRuntime_ productionCommandLineFlags];
  return [self genericRunTaskForProject:project
                    callbackWhenRunning:callback
                             extraFlags:flags];
}

// Common routine for notifications or polling (see above)
- (void)handleDeployTaskDeathNotificationHelper:(NSTask *)task {
  MBEngineTask *mbtask = [self findEngineTaskForTask:task];
  if (mbtask == nil) {
    NSLog(@"Can't find mbtask for NSTask %@\n", task);
    return; /* ??? */
  }

  [self disconnectConsoleFromTask:mbtask];
  MBProject *project = [mbtask project];
  MBConsoleController *console = [self findConsoleForProject:project];

  NSString *helpMe = @"If deploy fails you might need to 'rollback' manually.\n"
      "The \"Make Symlinks...\" menu option can help with command-line work.\n";
  [console appendString:helpMe];

  int status = [task terminationStatus];
  NSString *final = [NSString stringWithFormat:@"*** appcfg.py has finished with exit code %d ***\n",
                              status];
  [console appendString:final];

  [[self content] removeObject:mbtask];
  if (status == 0)
    [projectController_ deathForProject:[mbtask project]];
  else
    [projectController_ unexpectedDeathForProject:[mbtask project]];
}

// Deploy task died; we behave a little differently.
- (void)handleDeployTaskDeathNotification:(NSNotification *)aNotification {
  NSTask *task = [aNotification object];
  [self handleDeployTaskDeathNotificationHelper:task];
}

// On 10.4.11 we don't get notifications?  Poll to be robust.
- (void)checkForDeployTaskDeath:(NSTimer *)timer {
  NSTask *task = [timer userInfo];
  if ([task isRunning] == NO) {
    [self handleDeployTaskDeathNotificationHelper:task];
    [timer invalidate];
  }
}

// TODO(jrg): this is mostly cut-and-paste from genericRunTaskForProject.
// (I guess it wasn't so generic...)
// TODO(jrg): generalize even more.  Out of time.
- (BOOL)runDeployForProject:(MBProject *)project
                   username:(NSString *)username
                   password:(NSString *)password {
  MBEngineTask *task = [self findEngineTaskForProject:project];
  if (task != nil) {
    return NO;
  }

  // assert(launcherRuntime_);
  NSString *python = [launcherRuntime_ pythonCommand];
  NSMutableArray *args = [NSMutableArray array]; // full command line
  NSMutableArray *moreargs = [NSMutableArray array]; // all except das, project

  [moreargs addObjectsFromArray:
              [NSArray arrayWithObjects:@"--no_cookies",
                       [NSString stringWithFormat:@"--email=%@", username],
                       @"--passin",
                       @"update",
                       nil]];

  // defaults write com.google.GoogleAppEngineLauncher DeployServer BLAH
  NSString *server = [[NSUserDefaults standardUserDefaults]
                       stringForKey:@"Deploy"];
  if (server)
    [moreargs addObject:[NSString stringWithFormat:@"--server=%@", server]];


  // args = (appcfg.py + <args...> + <project>)
  [args addObject:[launcherRuntime_ deployCommand]];  // NOT C&P
  [args addObjectsFromArray:moreargs];
  [args addObject:[project path]];

  NSString *dir = [launcherRuntime_ devAppDirectory];
  NSMutableDictionary *environment = [NSMutableDictionary dictionary];
  [environment addEntriesFromDictionary:[[NSProcessInfo processInfo] environment]];
  [environment addEntriesFromDictionary:[launcherRuntime_ pythonExtraEnvironment]];

  // ALWAYS create a console window, even if never seen, so we have a
  // history of log output.
  [self doConsoleForProject:project showItNow:NO];

  // Now that we have a console (for sure), print some helpful text.
  MBConsoleController *console = [self findConsoleForProject:project];
  [console appendString:@"\n"];
  [console appendString:@"*** Running appfg.py with the following flags:\n    "];
  [console appendString:[moreargs componentsJoinedByString:@" "]];
  [console appendString:@"\n"];

  task = [MBEngineTask taskWithProject:project];
  [task setLaunchPath:python];
  [task setArguments:args];
  [task setCurrentDirectoryPath:dir];
  [task setEnvironment:environment];
  [task setStandardInput:[NSString stringWithFormat:@"%@\n", password]];

  [[self content] addObject:task];

#if 0
  // Listen for an early death.
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(handleDeployTaskDeathNotification:)
           name:NSTaskDidTerminateNotification
         object:[task task]];
#else
  // For reasons that I don't understand, Hannah's machine (10.4.11)
  // sometimes doesn't get the death notification even when the task
  // dies (!).  For now I add a timer to periodically check.  This
  // sucks but it makes us robust.
  [NSTimer scheduledTimerWithTimeInterval:1.0
                                   target:self
                                 selector:@selector(checkForDeployTaskDeath:)
                                 userInfo:[task task]
                                  repeats:YES];
#endif

  // Hook it up
  [console setEngineTask:task];

  // Finally, launch!
  [task launch];

  return YES;
}

- (void)handleTaskDeathNotification:(NSNotification *)aNotification {
  NSTask *task = [aNotification object];
  MBEngineTask *mbtask = [self findEngineTaskForTask:task];
  if (mbtask) {
    [self disconnectConsoleFromTask:mbtask];
    [projectController_ unexpectedDeathForProject:[mbtask project]];
    [[self content] removeObject:mbtask];
  }
}

- (BOOL)stopTaskForProject:(MBProject *)project {
  MBEngineTask *task = [self findEngineTaskForProject:project];
  if (task == nil) {
    return NO;
  }

  // Clean stop so we turn off the notification.
  [[NSNotificationCenter defaultCenter]
    removeObserver:self
              name:NSTaskDidTerminateNotification
            object:[task task]];

  [task interrupt];
  [task waitUntilExit];  // in a seperate thread?
  [self disconnectConsoleFromTask:task];
  [[self content] removeObject:task];

  return YES;
}

- (void)interruptAllTasksUncleanly:(id)obj {
  NSEnumerator *tenum = [[self content] objectEnumerator];
  MBEngineTask *task = nil;
  while ((task = [tenum nextObject])) {
    [task interrupt];
  }
}

- (void)stopAllTasks {
  NSEnumerator *tenum = [[self content] objectEnumerator];
  MBEngineTask *task = nil;
  while ((task = [tenum nextObject])) {
    [task interrupt];
    [task waitUntilExit];
    [self disconnectConsoleFromTask:task];
  }
  [[self content] removeAllObjects];
}

- (void)disconnectConsoleFromTask:(MBEngineTask *)task {
  MBProject *project = [task project];
  MBConsoleController *console = [self findConsoleForProject:project];
  if (console) {
    [console setEngineTask:nil];
  }
}

- (MBConsoleController *)findConsoleForProject:(MBProject *)project {
  MBConsoleController *console = [consoleWindows_ objectForKey:[project identifier]];
  return console;
}

- (void)removeConsoleForProject:(MBProject *)project {
  MBConsoleController *console = [self findConsoleForProject:project];
  if (console) {
    [console close];
    [consoleWindows_ removeObjectForKey:[project identifier]];
  }
}

- (void)doConsoleForProject:(MBProject *)project showItNow:(BOOL)showItNow {
  MBConsoleController *console = [self findConsoleForProject:project];
  if (console) {
    if (showItNow)
      [console orderFront:self];
  } else {
    MBConsoleController *console = [[[MBConsoleController alloc]
                                      initWithName:[project name]]
                                     autorelease];
    GMAssert([console window], @"no window in Console.nib");
    if (showItNow)
      [console showWindow:self];

    // Current index is the project's identifier.
    [consoleWindows_ setObject:console forKey:[project identifier]];
  }
}

- (NSString *)fullpathForDemo:(NSString *)title {
  NSString *fullpath = [[launcherRuntime_ demoDirectory] stringByAppendingPathComponent:title];
  // TODO(jrg): sanity check the path!
  return fullpath;
}


- (void)addDemos {
  NSArray *demos = [launcherRuntime_ demos];
  if (demos) {
    NSEnumerator *senum = [demos objectEnumerator];
    NSString *fullpath = nil;
    while ((fullpath = [senum nextObject])) {
      NSMenu *submenu = [demoMenu_ submenu];
      NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:fullpath
                                                     action:@selector(addDemoApp:)
                                              keyEquivalent:@""] autorelease];
      [item setTarget:projectController_];
      [submenu addItem:item];
    }
  }
}



@end
