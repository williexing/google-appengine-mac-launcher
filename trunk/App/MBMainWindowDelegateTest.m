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

#import "MBMainWindowDelegate.h"
#import <SenTestingKit/SenTestingKit.h>
#import <OCMock/OCMockObject.h>
#import <OCMock/OCMockRecorder.h>
#import "MBProject.h"
#import "MBProjectArrayController.h"

@interface MBMainWindowDelegateMock : MBMainWindowDelegate {
  id mockPB_;
}
@end

@implementation MBMainWindowDelegateMock

- (id)initWithPB:(id)pb controller:(id)controller {
  if ((self = [super init])) {
    mockPB_ = [pb retain];
    projectController_ = [controller retain];
  }
  return self;
}

- (void)dealloc {
  [(OCMockObject*)mockPB_ verify];  // OCMock
  [(OCMockObject*)projectController_ verify];  // OCMock
  [mockPB_ release];
  [projectController_ release];
  [super dealloc];
}

- (NSPasteboard *)pasteboard {
  return mockPB_;
}

@end

// ------------------------------------------------------------

@interface MBMainWindowDelegateTest : SenTestCase
@end

@implementation MBMainWindowDelegateTest

- (void)testBasics {
  MBMainWindowDelegate *d = [[[MBMainWindowDelegate alloc] init] autorelease];
  STAssertNotNil(d, nil);
  STAssertNotNil([d pasteboard], nil);
  [d cut:self];
}

- (void)testCopy {
  id pb = [OCMockObject mockForClass:[NSPasteboard class]];
  STAssertNotNil(pb, nil);
  [[pb expect] declareTypes:OCMOCK_ANY owner:OCMOCK_ANY];
  [[pb expect] setString:OCMOCK_ANY forType:NSStringPboardType];

  MBProject *p = [MBProject projectWithName:@"name" path:@"path" port:@"1002"];
  STAssertNotNil(p, nil);
  NSArray *projects = [NSArray arrayWithObject:p];
  STAssertNotNil(projects, nil);
  id controller = [OCMockObject mockForClass:[MBProjectArrayController class]];
  STAssertNotNil(controller, nil);
  [[[controller stub] andReturn:projects] currentProjects];
  
  MBMainWindowDelegate *d = [[MBMainWindowDelegateMock alloc]
                              initWithPB:pb controller:controller];
  STAssertNotNil(d, nil);
  [d copy:self];
  [d release];
}

// TODO(jrg): this increases coverage but doesn't actually test anything.
- (void)testPaste {
  MBMainWindowDelegate *d = [[[MBMainWindowDelegate alloc] init] autorelease];
  STAssertNotNil(d, nil);
  [d paste:self];
}

@end


