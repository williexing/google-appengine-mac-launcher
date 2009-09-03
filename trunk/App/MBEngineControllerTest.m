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

#import "MBEngineController.h"
#import <SenTestingKit/SenTestingKit.h>
#import <OCMock/OCMockObject.h>
#import <OCMock/OCMockRecorder.h>
#import "MBEngineRuntime.h"

@interface MBEngineControllerURLMock : MBEngineController
@end

@implementation MBEngineControllerURLMock

- (id)init {
  if ((self = [super init])) {
    urlOpener_ = [[OCMockObject mockForClass:[NSWorkspace class]] retain];
    [[(id)urlOpener_ expect] openURL:OCMOCK_ANY];
  }
  return self;
}

- (void)dealloc {
  [(id)urlOpener_ verify];  // OCMock call
  [urlOpener_ release];
  [super dealloc];
}

@end

// ------------------------------------------------------------

@interface MBEngineControllerTest : SenTestCase
@end

@implementation MBEngineControllerTest

- (void)testHelp {
  MBEngineController *controller = [[MBEngineControllerURLMock alloc] init];
  [controller helpForGoogleAppEngine:self];
  [controller release];

  controller = [[[MBEngineController alloc] init] autorelease];
  [controller awakeFromNib];
}

- (void)testStrings {
  MBEngineController *controller = [[[MBEngineController alloc] init]
                                     autorelease];
  NSString *s;
  NSRange r;

  s = [controller appVersion];
  STAssertTrue([s length] > 0, nil);
  r = [s rangeOfString:@"Version"];
  STAssertTrue(r.location != NSNotFound, nil);

  s = [[controller appInfo] string];
  STAssertTrue([s length] > 0, nil);
  r = [s rangeOfString:@"Google"];
  STAssertTrue(r.location != NSNotFound, nil);

  s = [controller sdkInfo];
  STAssertTrue([s length] > 0, nil);
  r = [s rangeOfString:@"ersion"];
  STAssertTrue(r.location != NSNotFound, nil);
}

// TODO(jrg): this increases coverage numbers but doesn't really test
// anything.  Perhaps add some objects, then confirm text gets put in it.
- (void)testAbout {
  // perform some initialization which doesn't normally happen in a unit test
  [[MBEngineRuntime defaultRuntime] extractionNeeded];
  [[MBEngineRuntime defaultRuntime] findRuntimeContents];

  MBEngineController *controller = [[[MBEngineController alloc] init]
                                     autorelease];
  [controller aboutGoogleAppEngine:self];
}

@end

