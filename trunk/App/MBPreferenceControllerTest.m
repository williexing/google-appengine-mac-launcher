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
#import <OCMock/OCMockObject.h>
#import <OCMock/OCMockRecorder.h>
#import "MBPreferenceController.h"
#import "MBPreferences.h"
#import "MBHardCodedOpenPanel.h"


// Allow a mock object to be used in place of [NSUserDefaults
// standardUserDefaults], and a mock instead of NSOpenPanel.
@interface MBPreferenceControllerMockDefaults : MBPreferenceController {
  id defaults_;  // weak
  id panel_;     // weak
}
- (id)initWithUserDefaults:(id)defaults;
- (id)initWithUserDefaults:(id)defaults openPanel:(id)panel;
- (NSUserDefaults *)defaults;
- (NSOpenPanel *)openPanel;
- (void)makeKeyAndOrderFront;
@end


@implementation MBPreferenceControllerMockDefaults

- (id)initWithUserDefaults:(id)defaults {
  if ((self = [super init])) {
    defaults_ = defaults;
    editor_ = [[[NSTextField alloc] init] autorelease];
  }
  return self;
}

- (id)initWithUserDefaults:(id)defaults openPanel:(id)panel {
  if ((self = [super init])) {
    defaults_ = defaults;
    panel_ = panel;
    editor_ = [[[NSTextField alloc] init] autorelease];
  }
  return self;
}

- (NSUserDefaults *)defaults {
  return defaults_;
}

- (NSOpenPanel *)openPanel {
  if (panel_)
    return panel_;
  return [super openPanel];
}

- (void)makeKeyAndOrderFront {
  // do nothing; we're a unit test!
}

@end

// -------------------------------------------------

// Let's make it easy to mock a control with an NSString.
@implementation NSString(MBPreferenceControllerTest)
- (NSString *)stringValue {
  return self;
}
@end

// -------------------------------------------------

@interface MBPreferenceControllerTest : SenTestCase
@end


@implementation MBPreferenceControllerTest

- (void)testSharedController {
  MBPreferenceController *c1 = [MBPreferenceController sharedController];
  MBPreferenceController *c2 = [MBPreferenceController sharedController];
  STAssertNotNil(c1, nil);
  STAssertNotNil(c2, nil);
  STAssertTrue(c1 == c2, nil);

  [c1 windowWillClose:nil];
  MBPreferenceController *c3 = [MBPreferenceController sharedController];
  STAssertNotNil(c3, nil);
  STAssertTrue(c1 != c3, nil);
}

// Doesn't test everything but it's a start.
- (void)testWindowLoad {
  id mockDefaults = [OCMockObject mockForClass:[NSUserDefaults class]];
  [[[mockDefaults expect] andReturn:@"/usr/bin/python"] stringForKey:kMBPythonPref];
  [[[mockDefaults expect] andReturn:@"Emacs.app"] stringForKey:kMBEditorPref];
  [[mockDefaults stub] boolForKey:OCMOCK_ANY];

  MBPreferenceController *c = [[MBPreferenceControllerMockDefaults alloc]
                                initWithUserDefaults:mockDefaults];
  STAssertNotNil(c, nil);
  [c windowDidLoad];
  [mockDefaults verify];
  [c release];
}

// Not all sets but it tests the pattern we reuse.
- (void)testSomeSets {
  id mockDefaults = [OCMockObject mockForClass:[NSUserDefaults class]];
  NSString *python = @"superPython!";
  NSString *editor = @"Emacs, master of the universe";
  [[mockDefaults expect] setObject:python forKey:kMBPythonPref];
  [[mockDefaults expect] synchronize];
  [[mockDefaults expect] setObject:editor forKey:kMBEditorPref];
  [[mockDefaults expect] synchronize];


  MBPreferenceController *c = [[MBPreferenceControllerMockDefaults alloc]
                                initWithUserDefaults:mockDefaults];
  STAssertNotNil(c, nil);
  [c setPython:python];
  [c setEditor:editor];
  [mockDefaults verify];
  [c release];
}

- (void)testSelectEditor {
  id mockOkDefaults = [OCMockObject mockForClass:[NSUserDefaults class]];
  [[mockOkDefaults expect] setObject:@"Emacs.app" forKey:kMBEditorPref];
  [[mockOkDefaults expect] synchronize];

  id okpanel = [[MBHardCodedOpenPanel alloc] initWithReturnCode:NSOKButton
                                             filenames:[NSArray arrayWithObject:@"Emacs.app"]];

  MBPreferenceController *c = [[MBPreferenceControllerMockDefaults alloc]
                                initWithUserDefaults:mockOkDefaults
                                openPanel:okpanel];
  STAssertNotNil(c, nil);
  [c selectEditorApplication:self];
  [mockOkDefaults verify];
  [c release];

  id mockCancelDefaults = [OCMockObject mockForClass:[NSUserDefaults class]];
  // expect nothing!
  id nopanel = [[MBHardCodedOpenPanel alloc] initWithReturnCode:NSCancelButton
                                             filenames:nil];
  c = [[MBPreferenceControllerMockDefaults alloc]
        initWithUserDefaults:mockCancelDefaults
                   openPanel:nopanel];
  [c selectEditorApplication:self];
  [mockCancelDefaults verify];
  [c release];
}


@end

