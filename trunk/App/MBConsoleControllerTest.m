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
#import "MBEngineTask.h"
#import "MBConsoleController.h"
#import "MBConsoleControllerTest.h"

// Let's expose some fields to make testing easier.
@interface MBConsoleController (Expose)

- (MBEngineTask *)engineTask;
- (void)setTextView:(NSTextView *)view;
- (NSString *)textFromTextView;

@end


@implementation MBConsoleController (Expose)

- (MBEngineTask *)engineTask {
  return task_;
}

- (void)setTextView:(NSTextView *)view {
  // Not memory safe if used in the real world,
  // but for unit testing, I'm happy.
  textView_ = view;
}

- (NSString *)textFromTextView {
  return [[textView_ textStorage] string];
}

@end


// ---------------------------------------------------------

@implementation MBConsoleControllerTest

- (void)setUp {
  console_ = [[MBConsoleController alloc] init];
  STAssertNotNil(console_, nil);
  NSTextView *view = [[NSTextView alloc] init];
  STAssertNotNil(view, nil);
  [console_ setTextView:view];
}

- (void)tearDown {
  [console_ release];
}

- (void)testWindow {
  [(id)console_ windowDidLoad];
  [console_ orderFront:self];
}

- (void)testBasicText {
  [console_ clear];
  STAssertTrue([[console_ textFromTextView] length] == 0, nil);

  NSString *hi = @"hi";
  [console_ appendString:hi];
  STAssertTrue([[console_ textFromTextView] isEqual:hi], nil);
  [console_ clear];
  STAssertTrue([[console_ textFromTextView] length] == 0, nil);

  NSString *lines = @"hi\nfred\nsneaker\n";
  [console_ appendString:lines];
  STAssertTrue([[console_ textFromTextView] isEqual:lines], nil);
  [console_ clearText:self];
  STAssertTrue([[console_ textFromTextView] length] == 0, nil);
}

- (void)testProcessString {
  // Simple text add
  [console_ clear];
  STAssertTrue([[console_ textFromTextView] length] == 0, nil);
  [console_ processString:@"foo"];
  STAssertTrue([[console_ textFromTextView] length] == 3, nil);
  [console_ processString:@"\n"];
  STAssertTrue([[console_ textFromTextView] length] == 4, nil);

  // Bigger string add
  NSString *tvstring = @"America's Next Top Model is my favorite TV show\n\n";
  NSRange r;
  r = [[console_ textFromTextView] rangeOfString:@"Top Model"];
  STAssertTrue(r.location == NSNotFound, nil);
  [console_ processString:tvstring];
  r = [[console_ textFromTextView] rangeOfString:@"Top Model"];
  STAssertTrue(r.location != NSNotFound, nil);
  STAssertTrue([[console_ textFromTextView] length] == (4 + [tvstring length]),
               nil);

  // Make sure append means after
  NSString *mmstring = @"But Make Me A Supermodel is a close second.\n";
  [console_ processString:mmstring];
  NSRange r2 = [[console_ textFromTextView] rangeOfString:@"Supermodel"];
  STAssertTrue(r2.location != NSNotFound, nil);
  STAssertTrue(r.location < r2.location, nil);
}

// Hook up an MBEngineTask; make sure data filters back to us.
// (Perhaps more a test of the MBEngineTask itself?)
- (void)testEngineTask {
  [console_ clear];
  STAssertTrue([[console_ textFromTextView] length] == 0, nil);

  MBEngineTask *task = [MBEngineTask taskWithProject:nil];
  [console_ setEngineTask:task];
  STAssertEquals([console_ engineTask], task, nil);

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSString *string = @"hi\nthere\nmister\fred\n";
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  [dict setObject:data forKey:NSFileHandleNotificationDataItem];
  NSNotification *not = [NSNotification notificationWithName:NSFileHandleReadCompletionNotification
                                                      object:nil
                                                    userInfo:dict];
  [task dataIsAvailable:not];
  STAssertEquals([[console_ textFromTextView] length], [string length], nil);

  // Mega size test which would have choked on pipes
  NSMutableString *s = [NSMutableString string];
  for (int x = 0; x < 500; x++) {
    NSString *frag = [NSString stringWithFormat:@"Here we make a really big string, number %d\n", x];
    [s appendString:frag];
  }
  data = [s dataUsingEncoding:NSUTF8StringEncoding];
  [dict setObject:data forKey:NSFileHandleNotificationDataItem];
  not = [NSNotification notificationWithName:NSFileHandleReadCompletionNotification
                                      object:nil
                                    userInfo:dict];
  [task dataIsAvailable:not];
  STAssertTrue([[console_ textFromTextView] length] > 8192, nil);
}

@end  // MBConsoleWindowTest
