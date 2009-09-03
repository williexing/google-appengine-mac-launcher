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
#import "MBMainTableViewTest.h"
#import "MBMainTableView.h"
#import "MBToolbar.h"

// -----------------------------------------------

// Internal API exposed so it's easier to test
@interface MBMainTableView(Private)
- (NSMenu *)configuredProjectMenu;
@end

// -----------------------------------------------

// Make the MBMainTableView easier to play with.
@interface MBTestableMainTableView : MBMainTableView {
  BOOL anyRunning_;
  BOOL anyStopped_;
  BOOL isSelected_;
}
@end

@implementation MBTestableMainTableView

- (id)init {
  if ((self = [super init])) {
    projectMenu_ = [[NSMenu alloc] initWithTitle:@"Project"];
    [projectMenu_ setAutoenablesItems:NO];
    [projectMenu_ addItem:[[[NSMenuItem alloc]
                             initWithTitle:kMBTStop
                                    action:NULL
                             keyEquivalent:@""] autorelease]];
    [projectMenu_ addItem:[[[NSMenuItem alloc]
                             initWithTitle:kMBTRun
                                    action:NULL
                             keyEquivalent:@""] autorelease]];
    mainViewMenu_ = [[NSMenu alloc] initWithTitle:@"Main"];
  }
  return self;
}

- (void)dealloc {
  [projectMenu_ release];
  [mainViewMenu_ release];
  [super dealloc];
}

// XXX - internal knowledge about implementation!!!
- (BOOL)anyRunning {
  return anyRunning_;
}

// XXX - internal knowledge about implementation!!!
- (BOOL)anyStopped {
  return anyStopped_;
}

- (void)setAnyRunning:(BOOL)ar anyStopped:(BOOL)as {
  anyRunning_ = ar;
  anyStopped_ = as;
}

- (void)setIsSelected:(BOOL)is {
  isSelected_ = is;
}

// override
- (BOOL)isRowSelected:(int)row {
  return isSelected_;
}

@end

// -----------------------------------------------


@implementation MBMainTableViewTest

- (void)testProjectMenuConfiguration {
  NSMenu *menu = nil;
  MBTestableMainTableView *view = [[MBTestableMainTableView alloc] init];
  STAssertNotNil(view, nil);
  
  [view setAnyRunning:YES anyStopped:YES];
  menu = [view configuredProjectMenu];
  STAssertNotNil([menu itemWithTitle:kMBTStop], nil);
  STAssertTrue([[menu itemWithTitle:kMBTStop] isEnabled] == YES, nil);
  STAssertNotNil([menu itemWithTitle:kMBTRun], nil);
  STAssertTrue([[menu itemWithTitle:kMBTRun] isEnabled] == YES, nil);

  [view setAnyRunning:NO anyStopped:YES];
  menu = [view configuredProjectMenu];
  STAssertNotNil([menu itemWithTitle:kMBTStop], nil);
  STAssertTrue([[menu itemWithTitle:kMBTStop] isEnabled] == NO, nil);
  STAssertNotNil([menu itemWithTitle:kMBTRun], nil);
  STAssertTrue([[menu itemWithTitle:kMBTRun] isEnabled] == YES, nil);

  [view setAnyRunning:YES anyStopped:NO];
  menu = [view configuredProjectMenu];
  STAssertNotNil([menu itemWithTitle:kMBTStop], nil);
  STAssertTrue([[menu itemWithTitle:kMBTStop] isEnabled] == YES, nil);
  STAssertNotNil([menu itemWithTitle:kMBTRun], nil);
  STAssertTrue([[menu itemWithTitle:kMBTRun] isEnabled] == NO, nil);
  
  [view release];
}

- (void)testMenuSelection {
  MBTestableMainTableView *view = [[MBTestableMainTableView alloc] init];
  STAssertNotNil(view, nil);

  NSEvent *rightDown = [NSEvent mouseEventWithType:NSRightMouseDown
                                 location:NSMakePoint(1,1)
                                 modifierFlags:0
                                 timestamp:0.0
                                 windowNumber:0
                                 context:nil
                                 eventNumber:0
                                 clickCount:0
                                 pressure:0.0];
  NSEvent *ctrlLeftDown = [NSEvent mouseEventWithType:NSLeftMouseDown
                                 location:NSMakePoint(1,1)
                                 modifierFlags:NSControlKeyMask
                                 timestamp:0.0
                                 windowNumber:0
                                 context:nil
                                 eventNumber:0
                                 clickCount:0
                                 pressure:0.0];
  NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown
                               location:NSMakePoint(1,1)
                               modifierFlags:0
                               timestamp:0
                               windowNumber:0
                               context:nil
                               characters:@"x"
                               charactersIgnoringModifiers:@"x"
                               isARepeat:NO
                               keyCode:27];

  NSMenu *p1, *p2, *mainView;
  [view setIsSelected:YES];
  p1 = [view menuForEvent:rightDown];
  STAssertNotNil(p1, nil);
  p2 = [view menuForEvent:ctrlLeftDown];
  STAssertNotNil(p2, nil);
  mainView = [view menuForEvent:keyPress];
  STAssertNotNil(mainView, nil);

  STAssertTrue(p1 == p2, nil);
  STAssertFalse(p1 == mainView, nil);

  STAssertTrue([[p1 title] isEqual:@"Project"], nil);
  STAssertTrue([[mainView title] isEqual:@"Main"], nil);
  [view release];
}



@end

