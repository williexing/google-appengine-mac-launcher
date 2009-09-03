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
#import "MBEngineRuntime.h"
#import "MBEngineRuntimeTest.h"

// ----------------------------------------------
// An NSAlert which always claims success instead of doing UI.
@interface MBSuccessAlert : NSAlert
-(NSInteger)runModal;
@end

@implementation MBSuccessAlert
-(NSInteger)runModal {
  return NSAlertFirstButtonReturn;
}
@end

// ----------------------------------------------
// Prevent UI.  This sucks; it shows we're not following MVC.
// TODO(jrg): fix this!
@interface MBEngineRuntimeNoAlert : MBEngineRuntime
- (NSAlert *)alert;
@end

@implementation MBEngineRuntimeNoAlert
- (NSAlert *)alert {
  return [[[MBSuccessAlert alloc] init] autorelease];
}
@end

// ----------------------------------------------

// sneak a look
@interface MBEngineRuntime (Private)
- (NSArray *)commands;
@end


@implementation MBEngineRuntimeTest

- (void)testAlert {
  MBEngineRuntime *r = [MBEngineRuntime defaultRuntime];
  STAssertNotNil([r alert], nil);
}

- (void)testLinkCommands {
  MBEngineRuntime *r = [MBEngineRuntime defaultRuntime];
  NSArray *c = [r commands];
  STAssertNotNil(c, nil);
  STAssertTrue([c count] > 1, nil);

  NSEnumerator *cenum = [c objectEnumerator];
  NSString *cmd = nil;
  NSMutableArray *lastComponents = [NSMutableArray array];
  while ((cmd = [cenum nextObject])) {
    STAssertTrue([cmd hasSuffix:@".py"], nil);
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:cmd], nil);
    [lastComponents addObject:[cmd lastPathComponent]];
  }
  STAssertTrue([lastComponents containsObject:@"dev_appserver.py"], nil);
  STAssertTrue([lastComponents containsObject:@"appcfg.py"], nil);
  STAssertTrue([lastComponents containsObject:@"bulkloader.py"], nil);
}

// Make sure |a| is an array, and that it is an array of strings.
- (void)confirmArrayOfStrings:(NSArray *)a {
  STAssertTrue([a isKindOfClass:[NSArray class]], nil);
  NSString *s = nil;
  NSEnumerator *e = [a objectEnumerator];
  while ((s = [e nextObject])) {
    STAssertTrue([s isKindOfClass:[NSString class]], nil);
  }
}

- (void)testFlags {
  MBEngineRuntime *runtime = [MBEngineRuntimeNoAlert defaultRuntime];
  STAssertNotNil(runtime, nil);

  [self confirmArrayOfStrings:[runtime extraCommandLineFlags]];
  [self confirmArrayOfStrings:[runtime productionCommandLineFlags]];
}

- (void)testCommands {
  MBEngineRuntime *runtime = [MBEngineRuntimeNoAlert defaultRuntime];
  STAssertNotNil(runtime, nil);

  NSString *cmd = [runtime pythonCommand];
  STAssertNotNil(cmd, nil);
  STAssertTrue([[NSFileManager defaultManager] isExecutableFileAtPath:cmd], nil);
  NSRange r = [cmd rangeOfString:@"python"];
  STAssertTrue(r.location != NSNotFound, nil);

  cmd = [runtime deployCommand];
  STAssertNotNil(cmd, nil);
  r = [cmd rangeOfString:@"appcfg.py"];
  STAssertTrue(r.location != NSNotFound, nil);
}

- (void)testDevAppServer {
  MBEngineRuntime *runtime = [MBEngineRuntimeNoAlert defaultRuntime];
  STAssertNotNil(runtime, nil);

  NSString *env = [runtime pythonExtraEnvironmentString];
  STAssertNotNil(env, nil);
  STAssertTrue([env hasPrefix:@"PYTHONPATH="], nil);
  NSDictionary *dict = [runtime pythonExtraEnvironment];
  STAssertNotNil([dict objectForKey:@"PYTHONPATH"], nil);

  NSString *dir = [runtime devAppDirectory];
  STAssertNotNil(dir, nil);
  BOOL isDir = NO;
  STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir], nil);
  STAssertTrue(isDir, nil);

  NSString *server = [runtime devAppServer];
  STAssertNotNil(server, nil);
  STAssertTrue([[NSFileManager defaultManager] isExecutableFileAtPath:server], nil);
  NSRange r = [server rangeOfString:dir];
  STAssertTrue(r.location != NSNotFound, nil);
}

- (void)testDemos {
  MBEngineRuntime *runtime = [MBEngineRuntimeNoAlert defaultRuntime];
  STAssertNotNil(runtime, nil);

  NSArray *demos = [runtime demos];
  STAssertTrue([demos count] > 0, nil);

  NSString *demodir = [runtime demoDirectory];
  BOOL isDir = NO;
  STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:demodir
                                                    isDirectory:&isDir], nil);
  STAssertTrue(isDir, nil);
  NSString *fullDemo = [demodir stringByAppendingPathComponent:[demos objectAtIndex:0]];
  STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:fullDemo], nil);
}

- (void)testTemplate {
  MBEngineRuntime *runtime = [MBEngineRuntimeNoAlert defaultRuntime];
  STAssertNotNil(runtime, nil);

  NSString *tdir = [runtime newAppTemplateDirectory];
  STAssertNotNil(tdir, nil);
  BOOL isDir = NO;
  STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:tdir
                                                    isDirectory:&isDir], nil);
  STAssertNotNil(tdir, nil);

  NSArray *contents = [[NSFileManager defaultManager] directoryContentsAtPath:tdir];
  STAssertTrue([contents count] > 0, nil);
  STAssertTrue([contents indexOfObject:@"app.yaml"] != NSNotFound, nil);
}

- (void)testVersionFileContents {
  MBEngineRuntime *runtime = [MBEngineRuntimeNoAlert defaultRuntime];
  STAssertNotNil(runtime, nil);

  NSString *version = [runtime versionFileContents];
  STAssertTrue([version length] > 0, nil);
  STAssertNotNil(version, nil);
  NSRange r = [version rangeOfString:@"release:"];
  STAssertTrue(r.location != NSNotFound, nil);
}

@end
