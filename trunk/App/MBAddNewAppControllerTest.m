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
#import "MBAddNewAppController.h"
#import "MBAddNewAppControllerTest.h"


@interface MBAddNewAppController (Expose)
- (void)setNameField:(NSTextField *)field;
- (void)setDirectoryField:(NSTextField *)field;
@end

@implementation MBAddNewAppController (Expose)

- (void)setNameField:(NSTextField *)field {
  if (nameField_ != field) {
    [nameField_ release];
    nameField_ = [field retain];
  }
}

- (void)setDirectoryField:(NSTextField *)field {
  if (directoryField_ != field) {
    [directoryField_ release];
    directoryField_ = [field retain];
  }
}

@end

// ---------------------------------------------------------

@implementation MBAddNewAppControllerTest

- (void)setUp {
  MBAddNewAppController *controller = [[MBAddNewAppController alloc] init];
  STAssertNotNil(controller, nil);
  NSTextField *field = [[NSTextField alloc] init];
  STAssertNotNil(field, nil);
  [controller setNameField:field];
  NSTextField *field2 = [[NSTextField alloc] init];
  STAssertNotNil(field2, nil);
  [controller setDirectoryField:field2];
  controller_ = controller;
}

- (void)tearDown {
  [controller_ release];
}

- (void)testBasics {
  MBAddNewAppController *controller = [[MBAddNewAppController alloc] initWithPort:@"1234"];
  STAssertNotNil(controller, nil);
  [controller close];
  [controller release];
}

- (void)testPaths {
  STAssertNotNil([controller_ browseControllerTitle], nil);
  STAssertTrue([[controller_ browseControllerTitle] length] > 0, nil);

  NSString *foobar = @"/foo/bar";
  [controller_ setDirectoryFromBrowse:foobar];
  // outlets not hooked up
  // STAssertTrue([[controller_ directory] isEqual:foobar], nil);

  NSString *himom = @"himom";
  STAssertNotNil([controller_ name], nil);
  STAssertTrue([[controller_ name] length] == 0, nil);
  [controller_ setName:himom];
  STAssertTrue([[controller_ name] isEqual:himom], nil);
}


@end

