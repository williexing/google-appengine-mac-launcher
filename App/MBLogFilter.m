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

#import "MBLogFilter.h"

#include <string.h>
#import "GMRegex.h"


@interface MBLogFilter (Private)

- (void)runHooksForLine:(NSString *)line;

@end

@implementation MBLogFilter

- (id)init {
  if ((self = [super init])) {
    hooks_ = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [hooks_ release];
  [super dealloc];
}

// TODO(dsymonds): This does not handle partial lines.
// It's very unlikely to get any, but this could buffer incomplete
// lines to avoid missing a match.
- (NSString *)processString:(NSString *)output {
  if ([hooks_ count] > 0) {
    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    NSEnumerator *en = [lines objectEnumerator];
    NSString *line;
    while ((line = [en nextObject])) {
      if ([line length] > 0) {
        [self runHooksForLine:line];
      }
    }
  }

  // For now we never change the text; we merely trigger off it.
  return output;
}

#pragma mark Hooks

- (void)runHooksForLine:(NSString *)line {
  NSMutableIndexSet *firedHooks = [NSMutableIndexSet indexSet];
  for (unsigned int i = 0; i < [hooks_ count]; ++i) {
    NSDictionary *hook = [hooks_ objectAtIndex:i];
    if ([line matchesPattern:[hook objectForKey:@"regex"]]) {
      [[hook objectForKey:@"callback"] invoke];
      [firedHooks addIndex:i];
    }
  }
  [hooks_ removeObjectsAtIndexes:firedHooks];
}

- (void)addGenericHook:(NSInvocation *)callback forRegex:(NSString *)regex {
  [hooks_ addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                     regex, @"regex",
                     callback, @"callback", nil]];
}

- (void)addProjectLaunchCompleteCallback:(NSInvocation *)callback {
  [self addGenericHook:callback
              forRegex:@".*Running application.*http://[^:]+:[0-9]+.*"];
}

@end
