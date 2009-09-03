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

#import "MBAddExistingAppController.h"

@implementation MBAddExistingAppController

- (id)initWithPort:(NSString *)port {
  return [super initWithWindowNibName:@"AddExisting" port:port];
}

- (id)init {
  // TODO(jrg): it would nice to init with an NSNumber.
  // When I transition to NSNumberFormatter, adapt.
  return [self initWithPort:@"8080"];
}

- (void)dealloc {
  [super dealloc];
}

- (NSString *)path {
  return [pathField_ stringValue];
}

- (void)setPath:(NSString *)path {
  [pathField_ setStringValue:path];
}

- (NSString *)browseControllerTitle {
  // TODO(jrg): I18N
  return @"Select existing application";
}

- (void)setDirectoryFromBrowse:(NSString *)path {
  [self setPath:path];
  [[[self window] contentView] setNeedsDisplay:YES];
}

@end
