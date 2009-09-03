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
#import "MBValidToColorTransformer.h"
#import "MBValidToColorTransformerTest.h"

@implementation MBValidToColorTransformerTest

- (void)testTransform {
  MBValidToColorTransformer *t = [[[MBValidToColorTransformer alloc] init]
                                      autorelease];
  STAssertTrue([MBValidToColorTransformer transformedValueClass] == [NSColor class], nil);
  STAssertFalse([MBValidToColorTransformer allowsReverseTransformation], nil);

  MBProject *p = [MBProject project];
  STAssertNotNil(p, nil);

  // Bogus transform
  STAssertNil([t transformedValue:nil], nil);
  
  // Default for p is a valid color
  NSColor *vc = [t transformedValue:[p valid]];
  STAssertNotNil(vc, nil);
  STAssertTrue([vc isKindOfClass:[NSColor class]], nil);
  
  // Verify of default values brings an invalid color
  [p verify];
  NSColor *ic = [t transformedValue:[p valid]];
  STAssertNotNil(ic, nil);
  STAssertTrue([vc isKindOfClass:[NSColor class]], nil);
  
  STAssertTrue([vc isEqual:ic] == NO, nil);
}

@end

