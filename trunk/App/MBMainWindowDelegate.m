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

#import <Cocoa/Cocoa.h>

#import "MBMainWindowDelegate.h"
#import "MBProjectArrayController.h"

@implementation MBMainWindowDelegate

- (NSPasteboard *)pasteboard {
  return [NSPasteboard generalPasteboard];
}

// Just like the remove app ("minus") button at the bottom of the window
- (IBAction)cut:(id)sender {
  [projectController_ removeApps:sender];
}

- (IBAction)copy:(id)sender {
  NSPasteboard *pb = [self pasteboard];
  NSArray *projects = [projectController_ currentProjects];
  if ([projects count] == 0)
    return;

  NSMutableString *names = [NSMutableString string];

  // No newline if it's just one.  That may look like odd logic but it
  // behaves nicer in practice.
  if ([projects count] == 1) {
    [names appendString:[[projects objectAtIndex:0] path]];
  } else {
    MBProject *proj = nil;
    NSEnumerator *penum = [projects objectEnumerator];
    while ((proj = [penum nextObject]) != nil) {
      [names appendString:[proj path]];
      [names appendString:@"\n"];
    }
  }
  
  [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType]
             owner:self];
  [pb setString:names forType:NSStringPboardType];
}

- (IBAction)paste:(id)sender {
  NSPasteboard *pb = [self pasteboard];

  NSArray *pBoardArray = [NSArray arrayWithObject:NSStringPboardType];
  NSString *type = [pb availableTypeFromArray:pBoardArray];
  if (type) {
    NSString *names = [pb stringForType:NSStringPboardType];
    // TextEdit.app splits lines with \n; Emacs.app splits lines with \r.
    // First, we determine the split string to use.
    NSString *splitString = @"\r";
    NSRange r = [names rangeOfString:@"\r"];
    if (r.location == NSNotFound)
      splitString = @"\n";

    // Then we try to split.  (Unfortunately,
    // [NSString componentsSeparatedByCharactersInSet] is 10.5-only.)
    r = [names rangeOfString:splitString];
    if (r.location == NSNotFound) {
      [projectController_ addProjectForDirectory:names];
    } else {
      NSArray *nameArray = [names componentsSeparatedByString:splitString];
      NSString *name = nil;
      NSEnumerator *nenum = [nameArray objectEnumerator];
      while ((name = [nenum nextObject]) != nil) {
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        name = [name stringByTrimmingCharactersInSet:whitespace];
        if ([name length] > 0) {
          [projectController_ addProjectForDirectory:name];
        }
      }
    }
  }
}

@end

