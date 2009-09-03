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

#import "MBRunStateToImageTransformer.h"
#import "MBProject.h"

@implementation MBRunStateToImageTransformer

+ (void)load {
  MBRunStateToImageTransformer *xformer = [[MBRunStateToImageTransformer alloc]
                                            init];
  [NSValueTransformer setValueTransformer:xformer
                      forName:@"RunStateToImageTransformer"];
  [xformer release];
}

+ (Class)transformedValueClass {
  return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
  return NO;
}

// TODO(jrg): perhaps use -[NSImage setName:] in combination with
// +[NSImage imageNamed:@"string] to cache them.  Or do they get
// cached automatically inside NSImageCell when the object is an
// NSString?
- (id)transformedValue:(id)value {
  if ([value respondsToSelector:@selector(intValue)] == NO)
    return nil;

  MBRunState e = [value intValue];

  // By being more explict than [NSBundle mainBundle],
  // unit tests are much happier.
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];

  NSString *path = nil;
  switch (e) {
    case kMBProjectProductionRun:
      path = [bundle pathForResource:@"ProdOn" ofType:@"tiff"];
      break;
    case kMBProjectRun:
      path = [bundle pathForResource:@"On" ofType:@"tiff"];
      break;
    case kMBProjectStarting:
      path = [bundle pathForResource:@"Starting" ofType:@"tiff"];
      break;
    case kMBProjectStop:
      path = [bundle pathForResource:@"Off" ofType:@"tiff"];
      break;
    case kMBProjectDied:
    default:
      path = [bundle pathForResource:@"Died" ofType:@"tiff"];
      break;
  }
  return path;
}



@end
