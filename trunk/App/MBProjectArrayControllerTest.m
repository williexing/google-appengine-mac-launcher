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

#import <SenTestingKit/SenTestingKit.h>
#import <Cocoa/Cocoa.h>
#import "GMLogger.h"
#import "MBProject.h"
#import "MBProjectArrayController.h"
#import "MBProjectArrayControllerTest.h"

// ---------------------------------------------

// Override of save path
@interface MBProjectArrayTestController : MBProjectArrayController {
  NSString *unique_;
}
@end

@implementation MBProjectArrayTestController

- (NSString *)projectSavePath {
  if (unique_ == nil) {
    unique_ = [[NSString stringWithFormat:@"/tmp/pactest-%d",
                         [[NSProcessInfo processInfo] processIdentifier]] retain];
  }
  return unique_;
}

- (void)dealloc {
  [[NSFileManager defaultManager] removeFileAtPath:unique_ handler:nil];
  [super dealloc];
}

@end



// ---------------------------------------------

@implementation MBProjectArrayControllerTest

- (void)testAwakeFromNib {
  MBProjectArrayController *c = [[[MBProjectArrayTestController alloc] init] autorelease];
  STAssertNotNil(c, nil);
  [c awakeFromNib];
}

- (void)testBasics {
  MBProjectArrayController *c = [[[MBProjectArrayTestController alloc] init] autorelease];
  STAssertNotNil(c, nil);
  STAssertTrue([[c currentProjects] count] == 0, nil);
  STAssertTrue([c unusedProjectPort] == 8080, nil);

  [c addProject:[MBProject projectWithName:@"name0" path:@"path0" port:@"8080"]];
  [c addProject:[MBProject projectWithName:@"name2" path:@"path2" port:@"8082"]];
  // Let's not block on some UI
  [[GMLogger sharedLogger] setWriter:nil];
  // expected to fail
  [c addProject:[MBProject projectWithName:@"name0" path:@"path0" port:@"8081"]];

  STAssertTrue([c unusedProjectPort] != 8080, nil);
  STAssertTrue([c unusedProjectPort] != 8082, nil);
  STAssertTrue([[c projects] count] == 2, nil);

  MBProject *p = [MBProject projectWithName:@"name10" path:@"path10" port:@"8010"];
  STAssertNotNil(p, nil);
  [p setRunState:kMBProjectRun];
  STAssertTrue([p runState] == kMBProjectRun, nil);
  [c addProject:p];
  STAssertTrue([[c projects] count] == 3, nil);
  [c unexpectedDeathForProject:p];
  STAssertTrue([p runState] == kMBProjectDied, nil);
  STAssertTrue([[c projectSavePath] length] > 0, nil);

  [c removeProject:p];
  STAssertTrue([[c projects] count] == 2, nil);

  [c runCurrentProjects:nil];
  [c stopCurrentProjects:nil];
  [c doConsoleForCurrentProjects:nil];
  // [c infoOnCurrentProjects:nil];
  // [c editCurrentProjects:nil];
  [c openFinderForCurrentProjects:nil];
  [c productionRunCurrentProjects:nil];
  // [c deployCurrentProjects:nil];
  // [c openDashboardForCurrentProjects:nil];
}

- (void)testLoadSave {
  MBProjectArrayController *c = [[[MBProjectArrayTestController alloc] init] autorelease];
  STAssertNotNil(c, nil);
  [c awakeFromNib];

  MBProject *p1 = [MBProject projectWithName:@"name0" path:@"path0" port:@"8080"];
  MBProject *p2 = [MBProject projectWithName:@"super" path:@"smash" port:@"8081"];
  STAssertNotNil(p1, nil);
  STAssertNotNil(p2, nil);
  [c addProject:p1];
  [c addProject:p2];
  STAssertTrue([[c projects] count] == 2, nil);
  [c saveProjects];

  MBProjectArrayController *c2 = [[[MBProjectArrayTestController alloc] init] autorelease];
  STAssertTrue([[c2 projects] count] == 0, nil);

  [c2 loadProjects];
  STAssertTrue([[c2 projects] count] == 2, nil);

  // TODO(jrg): verify.
  // We can't just look for p1 and p2 since they won't be the same
  // object.  There is currently no isEqual: for MBProjects, or
  // "search by name/path/port" mechanism.
}


- (void)testDialogs {
  //
  // TODO(jrg): test IBActions triggered from the UI which creates
  // dialogs.  The -addApp: method is split out; I could override that
  // to setup some dummy values in a synthetic MBAddAppDialog*.  BUT I
  // expect the UI to change a LOT, so perhaps I shouldn't do much
  // here quite yet.  (Yes, everyone has an excuse).
  //
}


@end  // MBProjectArrayControllerTest
