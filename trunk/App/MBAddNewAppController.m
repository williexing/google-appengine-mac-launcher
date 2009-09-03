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

#import "MBAddNewAppController.h"

@implementation MBAddNewAppController

// This allows us to keep our info string ("Directory Blah will be created..")
// on every keydown, not just on Return.
- (void)registerForControlChanges {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                        selector:@selector(updateDirectoryExplanation:)
                                        name:NSControlTextDidChangeNotification
                                        object:nameField_];
}

- (id)initWithWindowNibName:(NSString *)nibname port:(NSString *)port {
  if ((self = [super initWithWindowNibName:nibname port:port])) {
    [self registerForControlChanges];
  }
  return self;
}

- (id)initWithPort:(NSString *)port {
  return [self initWithWindowNibName:@"AddNew" port:port];
}

// Override of standard NSWindowController behavior that calls the original.
// We can't removeObserver: in our dealloc, since we'd never get there!
- (void)close {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSControlTextDidChangeNotification
                                                object:nameField_];
  [super close];
}

- (id)init {
  return [self initWithPort:@"8080"];
}

- (void)dealloc {
  [super dealloc];
}

- (void)windowDidLoad {
  [super windowDidLoad];
  [self setDirectory:NSHomeDirectory()];
}

// Update the directoryExplanationView_ text to describe what will
// happen, like XCode.
- (IBAction)updateDirectoryExplanation:(id)sender {
  NSString *expl = @"";
  NSString *name = [self name];
  NSString *directory = [self directory];
  if (([name length] > 0) && ([directory length] > 0)) {
    expl = [NSString stringWithFormat:@"The project directory %@/ "
                     "will be created if necessary, and default "
                     "project files will be created therein.",
                     [directory stringByAppendingPathComponent:name]];
  }

  NSString *currentExpl = [directoryExplanationField_ stringValue];
  if ([currentExpl isEqualToString:expl] == NO) {
    [directoryExplanationField_ setStringValue:expl];
    [[[self window] contentView] setNeedsDisplay:YES];
  }
}

- (NSString *)browseControllerTitle {
  // TODO(jrg): I18N
  return @"Select parent folder for new application";
}

- (void)setDirectoryFromBrowse:(NSString *)path {
  [self setDirectory:path];
  [[[self window] contentView] setNeedsDisplay:YES];
}

- (NSString *)name {
  return [nameField_ stringValue];
}

- (NSString *)directory {
  return [directoryField_ stringValue];
}

- (void)setName:(NSString *)name {
  [nameField_ setStringValue:name];
  [self updateDirectoryExplanation:self];
}

- (void)setDirectory:(NSString *)directory {
  [directoryField_ setStringValue:directory];
  [self updateDirectoryExplanation:self];
}

@end
