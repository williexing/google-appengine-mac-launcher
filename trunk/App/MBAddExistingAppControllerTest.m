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
#import "MBAddExistingAppController.h"
#import "MBAddExistingAppControllerTest.h"


@interface MBAddExistingAppController (Expose)
- (void)setPathField:(NSTextField *)field;
@end

@implementation MBAddExistingAppController (Expose)
- (void)setPathField:(NSTextField *)field {
  if (pathField_ != field) {
    [pathField_ release];
    pathField_ = [field retain];
  }
}
@end

// ---------------------------------------------------------

@implementation MBAddExistingAppControllerTest

- (void)setUp {
  MBAddExistingAppController *controller = [[MBAddExistingAppController alloc] init];
  STAssertNotNil(controller, nil);
  NSTextField *field = [[NSTextField alloc] init];
  STAssertNotNil(field, nil);
  [controller setPathField:field];
  controller_ = controller;
}

- (void)tearDown {
  [controller_ release];
}

- (void)testPaths {
  STAssertNotNil([controller_ browseControllerTitle], nil);
  STAssertTrue([[controller_ browseControllerTitle] length] > 0, nil);
  STAssertNotNil([controller_ path], nil);
  STAssertTrue([[controller_ path] length] == 0, nil);

  NSString *foobar = @"/foo/bar";
  [controller_ setDirectoryFromBrowse:foobar];
  // outlets not hooked up
  // STAssertTrue([[controller_ path] isEqual:foobar], nil);
}


@end

