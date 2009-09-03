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
#import "MBTaskArrayController.h"
#import "MBTaskArrayControllerTest.h"


@implementation MBTaskArrayControllerTest

- (void)testBasics {
  MBTaskArrayController *c = [[[MBTaskArrayController alloc] init]
                               autorelease];
  [c awakeFromNib];
  [c installCleanupHandlers];

  STAssertNil([c findEngineTaskForProject:nil], nil);
  STAssertNil([c findEngineTaskForTask:[[[NSTask alloc] init] autorelease]],
                 nil);

  [c stopAllTasks];
  [c interruptAllTasksUncleanly:self];
  [c disconnectConsoleFromTask:nil];

  MBProject *p = [MBProject projectWithName:@"name0"
                                       path:@"path0"
                                       port:@"8000"];
  [c removeConsoleForProject:p];
  // [c doConsoleForProject:p showItNow:NO];  // Triggers UI!
  // STAssertNotNil([c findConsoleForProject:p], nil);

  [c addDemos];
  STAssertTrue([[c fullpathForDemo:@"foo"] length] > 0, nil);
}

- (void)testRun {
  MBTaskArrayController *c = [[[MBTaskArrayController alloc] init] autorelease];
  [c awakeFromNib];
  [c installCleanupHandlers];

  MBProject *p = [MBProject projectWithName:@"name0" path:@"path0" port:@"8000"];
  BOOL worked = [c runTaskForProject:p callbackWhenRunning:nil];
  STAssertTrue(worked, nil);
  STAssertNotNil([c findEngineTaskForProject:p], nil);
  [c stopAllTasks];
  [c stopTaskForProject:p];
  STAssertNil([c findEngineTaskForProject:p], nil);

  worked = [c productionRunTaskForProject:p callbackWhenRunning:nil];
  STAssertTrue(worked, nil);
  STAssertNotNil([c findEngineTaskForProject:p], nil);
  [c doConsoleForProject:p showItNow:NO];
  [c stopTaskForProject:p];
  STAssertNil([c findEngineTaskForProject:p], nil);


}

// TODO(jrg): this is a little threadbare.  Once the UI settles down,
// add more meat.


@end  // MBTaskArrayControllerTest
