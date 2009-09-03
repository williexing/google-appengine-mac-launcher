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

#import "MBHardCodedOpenPanel.h"

@implementation MBHardCodedOpenPanel

- (id)initWithReturnCode:(NSInteger)returnCode filenames:(NSArray *)filenames {
  if ((self = [super init])) {
    return_ = returnCode;
    filenames_ = [filenames copy];
  }
  return self;
}

- (void)dealloc {
  [filenames_ release];
  [super dealloc];
}

- (NSInteger)runModalForTypes:(NSArray *)fileTypes {
  return return_;
}

- (NSArray *)filenames {
  return filenames_;
}

@end  // MBHardCodedOpenPanel
