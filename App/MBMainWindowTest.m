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
#import "MBMainWindow.h"
#import "MBMainWindowTest.h"

@implementation MBMainWindowTest

- (void)testUpDown {
  MBMainWindow *win = [[MBMainWindow alloc] init];
  STAssertTrue([win respondsToSelector:@selector(awakeFromNib)], nil);
  [((id)win) awakeFromNib];
  STAssertTrue([[win toolbarIdentifier] length] > 0, nil);
  STAssertTrue([win isReleasedWhenClosed], nil);
  [win close];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}


- (void)testToolbarDelegate {
  MBMainWindow *win = [[MBMainWindow alloc] init];
  STAssertTrue([win respondsToSelector:@selector(awakeFromNib)], nil);
  [((id)win) awakeFromNib];

  NSArray *IDs = [win toolbarDefaultItemIdentifiers:nil];
  NSArray *allowedIDs = [win toolbarAllowedItemIdentifiers:nil];
  STAssertTrue([allowedIDs count] >= [IDs count], nil);

  NSEnumerator *e = [IDs objectEnumerator];
  NSString *itemIdentifier = nil;
  while ((itemIdentifier = [e nextObject])) {
    STAssertNotNil([win toolbar:nil itemForItemIdentifier:itemIdentifier
                        willBeInsertedIntoToolbar:NO], nil);
  }
  STAssertNil([win toolbar:nil itemForItemIdentifier:@"zapfDingbats"
                   willBeInsertedIntoToolbar:NO], nil);

  // Look for a few favorites
  NSArray *strings = [NSArray arrayWithObjects:@"Run", @"Stop", @"Deploy", nil];
  e = [strings objectEnumerator];
  NSString *name = nil;
  while ((name = [e nextObject])) {
    STAssertTrue([IDs indexOfObject:name] != NSNotFound, nil);
  }

  [win close];
}

@end  // MBMainWindowTest
