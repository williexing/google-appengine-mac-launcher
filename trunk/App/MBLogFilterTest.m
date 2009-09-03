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
#import "MBLogFilter.h"
#import "MBLogFilterTest.h"


@implementation MBLogFilterTest

- (void)setUp {
  filter_ = [[MBLogFilter alloc] init];
  STAssertNotNil(filter_, nil);
  pings_ = [[NSMutableSet alloc] init];
}

- (void)tearDown {
  [filter_ release];
  [pings_ release];
}

#pragma mark Test helpers

- (NSInvocation *)pingWithName:(NSString *)name {
  SEL sel = @selector(doPing:);
  NSInvocation *ping = [NSInvocation invocationWithMethodSignature:
                        [self methodSignatureForSelector:sel]];
  [ping setTarget:self];
  [ping setSelector:sel];
  [ping setArgument:&name atIndex:2];
  [ping retainArguments];
  return ping;
}

- (void)doPing:(NSString *)name {
  [pings_ addObject:name];
}

#pragma mark Tests

- (void)testPassThrough {
  NSArray *strings = [NSArray arrayWithObjects:@"hello there\n",
                              @"are you having a good day?\n",
                              @"\n",
                              nil];
  NSEnumerator *senum = [strings objectEnumerator];
  NSString *s;
  while ((s = [senum nextObject]) != nil) {
    STAssertEqualObjects(s, [filter_ processString:s], nil);
  }
}

- (void)testGenericHooks {
  [filter_ addGenericHook:[self pingWithName:@"saw_digits"]
                 forRegex:@".*[0-9]+.*"];
  [filter_ addGenericHook:[self pingWithName:@"end_of_line_hey"]
                 forRegex:@".*hey"];
  STAssertTrue([pings_ count] == 0, nil);

  NSString *line = [filter_ processString:@"the answer is 42, hey\n"];
  STAssertEqualObjects(line, @"the answer is 42, hey\n", nil);
  STAssertTrue([pings_ containsObject:@"saw_digits"], nil);
  STAssertTrue([pings_ containsObject:@"end_of_line_hey"], nil);

  // The 'simple' ping shouldn't be matched a second time
  [pings_ removeAllObjects];
  [filter_ processString:@"number 10 downing street\n"];
  STAssertTrue([pings_ count] == 0, nil);
}

@end  // MBConsoleWindowTest
