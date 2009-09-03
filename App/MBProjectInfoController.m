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

#import "MBProjectInfoController.h"
#import "MBProject.h"

@implementation MBProjectInfoController

// TODO(jrg): don't let this open if the project is running!  Else
// (for example) the port field won't make sense (different from
// running version).

- (id)init {
  return [self initWithProject:[MBProject project]];
}

- (id)initWithProject:(MBProject *)project {
  if ((self = [super initWithWindowNibName:@"ProjectInfo"])) {
    project_ = [project retain];
  }
  // This allows us to keep our flags summary updated
  // on every keydown in the "extra flags" field.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateFlagsSummary:)
                                               name:NSControlTextDidChangeNotification
                                             object:extraFlagsField_];
  return self;
}

// Override of standard NSWindowController behavior that calls the original.
// We can't removeObserver: in our dealloc, since we'd never get there!
- (void)close {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSControlTextDidChangeNotification
                                                object:extraFlagsField_];
  [super close];
}

- (void)dealloc {
  [project_ release];
  [super dealloc];
}

- (void)windowDidLoad {
  [nameField_ setStringValue:[project_ name]];
  [pathField_ setStringValue:[project_ path]];
  [portField_ setStringValue:[project_ port]];

  NSMutableArray *flags = [NSMutableArray arrayWithArray:[project_ commandLineFlags]];
  NSString *args = @"";
  if ([flags count] > 0)
    args = [flags componentsJoinedByString:@" "];
  [[fullFlagsField_ textStorage] setAttributedString:
                                   [[[NSAttributedString alloc]
                                      initWithString:args]
                                      autorelease]];

  NSString *clearCmd = @"--clear_datastore";
  if ([flags containsObject:clearCmd]) {
    [clearDSOnLaunchCheckBox_ setState:NSOnState];
  } else {
    [clearDSOnLaunchCheckBox_ setState:NSOffState];
  }
  [flags removeObject:clearCmd];
  [extraFlagsField_ setStringValue:[flags componentsJoinedByString:@" "]];
}

- (IBAction)updateFlagsSummary:(id)sender {
  NSMutableArray *flags = [NSMutableArray array];
  if ([clearDSOnLaunchCheckBox_ state] == NSOnState)
    [flags addObject:@"--clear_datastore"];
  NSString *extraFlags = [extraFlagsField_ stringValue];
  if (extraFlags)
    [flags addObject:extraFlags];
  NSString *total = [flags componentsJoinedByString:@" "];
  [[fullFlagsField_ textStorage] setAttributedString:
                                   [[[NSAttributedString alloc]
                                      initWithString:total]
                                     autorelease]];
}

- (IBAction)stopModalWithSuccess:(id)sender {
  // save state into the project
  [project_ setPort:[portField_ stringValue]];
  NSMutableArray *flags = [NSMutableArray array];
  if ([clearDSOnLaunchCheckBox_ state] == NSOnState)
    [flags addObject:@"--clear_datastore"];

  NSString *extra = [extraFlagsField_ stringValue];
  // TODO(jrg): we should be friendly with paths; e.g. "/tmp/foo\ bar" shouldn't choke us.
  // TODO(jrg): there has got to be a better way to do this.
  // What we're doing here is
  //  1) removing complete whitespace
  //  2) throwing away extra spaces between args, since [@"  " componentsJoinedByString:@" "]
  //     returns a non-empty list (!)
  if ([extra length] > 0) {
    NSArray *args = [extra componentsSeparatedByString:@" "];
    NSString *arg = nil;
    NSEnumerator *aenum = [args objectEnumerator];
    while ((arg = [aenum nextObject])) {
      if ([arg length] > 0) {
        [flags addObject:arg];
      }
    }
  }
  [project_ setCommandLineFlags:flags];
  // then stop the dialog.
  [NSApp stopModalWithCode:NSOKButton];
}


@end


