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
@class MBTaskArrayController;

// Controller for deployment of applications.  'Deploy' is defined as
// 'upload to the cloud with appcfg.py'.  In MVC, The view (UI) is a
// combination of GMClientAuthWindow (which itself has a controller)
// and a Console output window.  The data is a combination of project
// list and MBEngineRuntime.
@interface MBDeployController : NSObject {
 @private  
  // As passed in; save until we've auth'ed
  NSArray *projects_;

  // TODO(jrg): this recycling is cheating but I'm out of time.
  IBOutlet MBTaskArrayController *taskController_;
}
// And we're off!
- (void)deploy:(NSArray *)projects parentWindow:(NSWindow *)window;
@end
