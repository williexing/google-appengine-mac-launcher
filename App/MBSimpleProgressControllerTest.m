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

#import "MBSimpleProgressController.h"
#import <SenTestingKit/SenTestingKit.h>

@interface MBSimpleProgressControllerTest : SenTestCase
@end

@implementation MBSimpleProgressControllerTest

- (void)testController {
  
  MBSimpleProgressController *c = [[MBSimpleProgressController alloc] init];
  STAssertNotNil(c, nil);
  
  NSArray *messages = [NSArray arrayWithObjects:@"hi", @"mom  ", nil];
  NSEnumerator *menum = [messages objectEnumerator];
  NSString *m;
  while ((m = [menum nextObject])) {
    [c setMessage:m];
    STAssertEqualObjects([c message], m, nil);
  }

  [c startAnimation];  // not confirmed :-(
}


@end  // MBSimpleProgressControllerTest
