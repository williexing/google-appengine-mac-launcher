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
#import "MBProject.h"
#import "MBEngineTask.h"
#import "MBEngineTaskTest.h"

@implementation MBEngineTaskTest

- (void)setUp {
  projects_ = [[NSMutableArray array] retain];
  for (int i = 0; i < 3; i++) {
    NSString *str = [NSString stringWithFormat:@"%d", i];
    [projects_ addObject:[MBProject projectWithName:str path:str port:str]];
  }
  output_ = [[NSMutableString alloc] init];
}

- (void)tearDown {
  [projects_ release];
  [output_ release];
}

- (void)testBasics {
  MBEngineTask *t = [[MBEngineTask alloc] init];
  STAssertNotNil(t, nil);
  [t release];

  MBProject *project = [projects_ objectAtIndex:0];
  t = [MBEngineTask taskWithProject:project];
  STAssertNotNil(t, nil);
  STAssertTrue([[t project] isEqual:project], nil);

  project = [projects_ objectAtIndex:1];
  [t setProject:project];
  STAssertTrue([[t project] isEqual:project], nil);
  STAssertNotNil([t task], nil);

  MBEngineTask *t2 = [[MBEngineTask alloc] initWithProject:project];
  STAssertNotNil(t2, nil);
  STAssertTrue([[t project] isEqual:[t2 project]], nil);
  [t2 release];
}

- (void)processString:(NSString *)string {
  [output_ appendString:string];
}

- (void)testTask {
  MBProject *project = [projects_ objectAtIndex:0];

  // Interrupted
  MBEngineTask *t = [[MBEngineTask taskWithProject:project] retain];
  STAssertNotNil(t, nil);
  [t setLaunchPath:@"/bin/echo"];
  [t setArguments:[NSArray arrayWithObject:@"himom"]];
  [t setEnvironment:[NSDictionary dictionaryWithObject:@"/bin" forKey:@"PATH"]];
  [t launch];
  [t interrupt];
  [t waitUntilExit];
  [t release];

  t = [[MBEngineTask taskWithProject:project] retain];
  STAssertNotNil(t, nil);
  [t setOutputReceiver:self];  // so processString: is called and
                               // output_ is filled in
  [t setLaunchPath:@"/bin/pwd"];
  [t setCurrentDirectoryPath:@"/tmp"];
  [t launch];
  [t waitUntilExit];
  [t release];
  NSRange r = [output_ rangeOfString:@"/tmp"];
  STAssertTrue(r.location != NSNotFound, nil);
}

@end
