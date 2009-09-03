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

// TODO(jrg): unit test this!  It's a pain but too bad.

#import "MBConsoleController.h"
#import "MBDeployController.h"
#import "MBProject.h"
#import "MBEngineRuntime.h"
#import "MBTaskArrayController.h"
#import "GMClientAuthWindowController.h"
#import "GMLogger.h"
#import "GMClientAuthManager.h"


@implementation MBDeployController

- (void)dealloc {
  [projects_ release];
  [super dealloc];
}

// In a hurry so I recycle (uncleanly) some elements which I've seen before.
// TODO(jrg): unify use of console window and tasks
- (void)deployProjectsWithUsername:(NSString *)username
                          password:(NSString *)password {

  NSEnumerator *aenum = [projects_ objectEnumerator];
  MBProject *project = nil;
  while ((project = [aenum nextObject])) {
    [taskController_ runDeployForProject:project
                                username:username
                                password:password];
    [taskController_ doConsoleForProject:project showItNow:YES];
  }
}

// Callback for GMClientAuthWindowController
- (void)mySignInError:(GMClientAuthWindowController *)signIn {
  GMLoggerError(@"Failed; auth error.");
}

// Callback for GMClientAuthWindowController
- (void)mySignInUserCanceled:(GMClientAuthWindowController *)authWindow {
  [NSApp endSheet:[authWindow window]];
}

// (Comment copied from GMClientAuthWindowController.h)
// NSApp's modal sheet handler also calls us back; we orderOut on the sheet
// and release the controller:
- (void)sheetDidEnd:(NSWindow *)sheet
         returnCode:(int)returnCode
        contextInfo:(void  *)contextInfo {
  [sheet orderOut:self];
  GMClientAuthWindowController *authController = (GMClientAuthWindowController *)contextInfo;
  [authController release];
}

// Got a name and password; let's do our magic.
- (void)mySignInSucceeded:(GMClientAuthWindowController *)authWindow  {
  // successful authentication; get the service's token issued by Gaia,
  // then dismiss the sheet
  // NSString *serviceToken = [authWindow authToken];
  [NSApp endSheet:[authWindow window]];

  GMClientAuthManager *authMgr = [authWindow clientAuthManager];
  GMAuthCredential *credential = [authMgr credential];
  NSString *username = [credential username];
  NSString *password = [credential password];

  [self deployProjectsWithUsername:username password:password];
}

// Initiates a deploy by opening a name/password sheet
- (void)deploy:(NSArray *)projects parentWindow:(NSWindow *)window {
  MBEngineRuntime *runtime = [MBEngineRuntime defaultRuntime];
  GMAssert(runtime, @"Must have a runtime to find new project templates");

  [projects_ autorelease];
  projects_ = [projects copy];

  GMClientAuthWindowController *authController;
  NSURL *url = [NSURL URLWithString:@"http://code.google.com/appengine/docs/appcfgpy.html"];
  authController = [[GMClientAuthWindowController alloc]
                     initWithTarget:self
                   signedInSelector:@selector(mySignInSucceeded:)
                   canceledSelector:@selector(mySignInUserCanceled:)
               errorMessageSelector:@selector(mySignInError:)
                   sourceIdentifier:@"GoogleAppEngineLauncher" // for log analysis
                     serviceName:@"ah"
                     serviceDisplayName:@"GoogleAppEngine"
                       learnMoreURL:url];

  [NSApp beginSheet:[authController window]
     modalForWindow:window
      modalDelegate:self
     didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
        contextInfo:authController];
}

@end




