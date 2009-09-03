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
#import "MBProjectInfoController.h"
#import "MBProjectInfoControllerTest.h"

@implementation MBProjectInfoControllerTest

- (void)testBasics {
  MBProject *project = [MBProject projectWithName:@"name" path:@"path" port:@"port"];
  [project setCommandLineFlags:[NSArray arrayWithObjects:@"--foo", @"--bar", nil]];
  MBProjectInfoController *c = [[[MBProjectInfoController alloc]
                                  initWithProject:project]
                                 autorelease];
  [c updateFlagsSummary:self];
  [c stopModalWithSuccess:self];

  c = [[MBProjectInfoController alloc] init];
  [(id)c windowDidLoad];
  [c close];
  [c release];
}

@end  // MBProjectInfoControllerTest
