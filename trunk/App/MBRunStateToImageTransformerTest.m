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
#import "MBProject.h"
#import "MBRunStateToImageTransformer.h"
#import "MBRunStateToImageTransformerTest.h"

@implementation MBRunStateToImageTransformerTest

- (void)testTransform {
  MBRunStateToImageTransformer *t = [[[MBRunStateToImageTransformer alloc] init]
                                      autorelease];
  STAssertTrue([MBRunStateToImageTransformer transformedValueClass] == [NSImage class], nil);
  STAssertFalse([MBRunStateToImageTransformer allowsReverseTransformation], nil);

  MBProject *p = [MBProject project];
  STAssertNotNil(p, nil);
  NSMutableSet *set = [NSMutableSet set];

  [p setRunState:kMBProjectProductionRun];
  [set addObject:[t transformedValue:[p runStateAsObject]]];
  [p setRunState:kMBProjectRun];
  [set addObject:[t transformedValue:[p runStateAsObject]]];
  [p setRunState:kMBProjectStop];
  [set addObject:[t transformedValue:[p runStateAsObject]]];
  [p setRunState:kMBProjectDied];
  [set addObject:[t transformedValue:[p runStateAsObject]]];

  // make sure we have 3 unique images
  STAssertTrue([set count] == 4, nil);

  // Make sure they all look like image paths.  Not sure we can verify
  // the contents are valid; we're not the app bundle in a unit test.
  NSEnumerator *e = [set objectEnumerator];
  NSString *s = nil;
  while ((s = [e nextObject])) {
    STAssertTrue([s isKindOfClass:[NSString class]], nil);
    STAssertTrue([s hasSuffix:@"tiff"] || [s hasSuffix:@"tif"], nil);
    STAssertTrue([[NSFileManager defaultManager] isReadableFileAtPath:s], nil);
  }
}

@end

