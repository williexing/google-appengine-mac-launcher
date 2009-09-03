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
#import <unistd.h>
#import "MBProject.h"
#import "MBProjectTest.h"

@implementation MBProjectTest

- (void)testInit {
  MBProject *p = nil;
  p = [MBProject project];
  STAssertNotNil(p, nil);
  p = [[MBProject alloc] init];
  STAssertNotNil(p, nil);
  [p release];
  p = [MBProject projectWithName:@"name" path:@"path" port:@"port"];
  STAssertNotNil(p, nil);
}


// TODO(jrg): ideally we enforce a number for port.  If done in
// MBProject and not the UI, this unit test will need to change.
- (void)testBasicGetSet {
  MBProject *p = nil;
  p = [MBProject project];
  STAssertNotNil(p, nil);
  STAssertNotNil([p name], nil);
  STAssertNotNil([p path], nil);
  STAssertNotNil([p name], nil);

  p = [MBProject projectWithName:@"name" path:@"path" port:@"port"];
  STAssertNotNil(p, nil);
  STAssertTrue([[p name] isEqual:@"name"], nil);
  STAssertTrue([[p path] isEqual:@"path"], nil);
  STAssertTrue([[p port] isEqual:@"port"], nil);

  [p setName:@"borkName"];
  [p setPath:@"pathBork"];
  [p setPort:@"qwerty"];
  STAssertTrue([[p name] isEqual:@"borkName"], nil);
  STAssertTrue([[p path] isEqual:@"pathBork"], nil);
  STAssertTrue([[p port] isEqual:@"qwerty"], nil);
}

- (void)testRunState {
  NSNumber *num = nil;
  MBProject *p = [MBProject project];
  STAssertNotNil(p, nil);
  STAssertTrue([p runState] == kMBProjectStop, nil);
  STAssertTrue([[p runStateAsObject] isKindOfClass:[NSNumber class]], nil);
  num = [p runStateAsObject];
  STAssertTrue([num intValue] == kMBProjectStop, nil);

  [p setRunState:kMBProjectRun];
  STAssertTrue([p runState] == kMBProjectRun, nil);
  [p setRunState:kMBProjectStop];
  STAssertTrue([p runState] == kMBProjectStop, nil);

  [p setRunState:kMBProjectDied];
  STAssertTrue([p runState] == kMBProjectDied, nil);
  num = [p runStateAsObject];
  STAssertTrue([num intValue] == kMBProjectDied, nil);
}

- (void)testUnique {
  MBProject *p = nil;
  NSMutableSet *set = [NSMutableSet set];
  for (int i = 0; i < 100; i++) {
    p = [MBProject project];
    STAssertNotNil(p, nil);
    [set addObject:[p identifier]];
  }
  STAssertTrue([set count] == 100, nil);
}

- (void)testCommandLineFlags {
  NSArray *array = nil;
  MBProject *p = [MBProject project];
  STAssertNotNil(p, nil);

  array = [p commandLineFlags];
  STAssertNotNil(array, nil);
  STAssertTrue([array count] == 0, nil);

  NSMutableArray *flags = [NSMutableArray arrayWithObjects:@"--foo", @"--bar", @"--free-borks", nil];
  STAssertNotNil(flags, nil);
  [p setCommandLineFlags:flags];
  array = [p commandLineFlags];
  STAssertNotNil(array, nil);
  STAssertTrue([array isEqualToArray:flags], nil);

  [flags addObject:@"--help"];
  [p setCommandLineFlags:flags];
  array = [p commandLineFlags];
  STAssertNotNil(array, nil);
  STAssertTrue([array count] == 4, nil);
}

- (void)testCoder {
  MBProject *p = [MBProject projectWithName:@"BIGNAME" path:@"smallpath" port:@"bestPortInTown"];
  STAssertNotNil(p, nil);
  [p setCommandLineFlags:[NSArray arrayWithObjects:@"--spaz", @"--gofast", nil]];
  [p setRunState:kMBProjectDied];

  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:p];
  STAssertNotNil(data, nil);

  MBProject *dest = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  STAssertTrue([dest isKindOfClass:[MBProject class]], nil);
  STAssertTrue([[dest name] isEqual:[p name]], nil);
  STAssertTrue([[dest path] isEqual:[p path]], nil);
  STAssertTrue([[dest port] isEqual:[p port]], nil);
  STAssertTrue([[dest commandLineFlags] isEqual:[p commandLineFlags]], nil);
  STAssertFalse([[dest identifier] isEqual:[p identifier]], nil);
  STAssertTrue([dest runState] == kMBProjectStop, nil);
}

- (void)testVerify {

  NSString *unique = [NSString stringWithFormat:@"project-test-%d-%f",
                               (int)getpid(),
                               (float)[NSDate timeIntervalSinceReferenceDate]];
  NSString *dir = [@"/tmp" stringByAppendingPathComponent:unique];
  [[NSFileManager defaultManager] createDirectoryAtPath:dir attributes:nil];

  NSString *appYaml = [dir stringByAppendingPathComponent:@"app.yaml"];
  NSData *data = [@"application: foo\n" dataUsingEncoding:NSUTF8StringEncoding];
  [[NSFileManager defaultManager] createFileAtPath:appYaml
                                          contents:data
                                        attributes:nil];

  MBProject *p = [MBProject projectWithName:unique path:dir port:@"8000"];
  STAssertNotNil(p, nil);
  STAssertTrue([p verify] == YES, nil);

  NSNumber *valid = [p valid];
  STAssertNotNil(valid, nil);
  STAssertTrue([valid boolValue] == YES, nil);

  // make sure the name got updated
  NSString *name = [p name];
  STAssertTrue([name isEqual:@"foo"], nil);

  // removes all contents, so it will no longer be valid
  [[NSFileManager defaultManager] removeFileAtPath:dir handler:nil];
  [p verify];

  valid = [p valid];
  STAssertNotNil(valid, nil);
  STAssertTrue([valid boolValue] == NO, nil);
}



@end  // MBProjectTest
