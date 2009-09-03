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

#import "MBPreferenceController.h"
#import "MBPreferences.h"
#import "MBEngineRuntime.h"

@implementation MBPreferenceController

static MBPreferenceController *gPreferenceController = nil;

// To make mocking easier
- (NSUserDefaults *)defaults {
  return [NSUserDefaults standardUserDefaults];
}

// To make mocking easier
- (void)makeKeyAndOrderFront {
  [[self window] makeKeyAndOrderFront:self];
}

+ (MBPreferenceController *)sharedController {
  if (gPreferenceController == nil) {
    gPreferenceController = [[MBPreferenceController alloc] init];
  }

  // When asked for, always pop it up.
  [gPreferenceController makeKeyAndOrderFront];
  return gPreferenceController;
}

- (id)init {
  self = [super initWithWindowNibName:@"Preferences"];
  return self;
}

- (void)windowDidLoad {
  NSString *python = [[self defaults]
                       stringForKey:kMBPythonPref];
  if (python)
    [python_ setStringValue:python];

  NSString *editor = [[self defaults]
                       stringForKey:kMBEditorPref];
  if (editor)
    [editor_ setStringValue:editor];

  BOOL doesdir = [[self defaults]
                   boolForKey:kMBEditDirectoryPref];
  [editDirectory_ setState:(doesdir ? NSOnState : NSOffState)];
}

- (IBAction)setPython:(id)sender {
  NSString *python = [sender stringValue];
  NSUserDefaults *defaults = [self defaults];
  if (python) {
    [defaults setObject:python forKey:kMBPythonPref];
    [defaults synchronize];
  }
  [[MBEngineRuntime defaultRuntime] refreshPythonCommand];
}

- (IBAction)setEditor:(id)sender {
  NSString *editor = [sender stringValue];
  NSUserDefaults *defaults = [self defaults];
  [defaults setObject:editor forKey:kMBEditorPref];
  [defaults synchronize];
}

- (IBAction)selectEditorApplication:(id)sender {
  NSOpenPanel *panel = [self openPanel];
  [panel setAllowsMultipleSelection:NO];

  // A .app is really a directory, but don't tell NSOpenPanel...
  [panel setCanChooseDirectories:NO];
  [panel setCanChooseFiles:YES];
  // TODO(jrg): I18N
  [panel setPrompt:@"Choose"];
  [panel setTitle:@"Select an external editor"];
  NSInteger i = [panel runModalForTypes:[NSArray arrayWithObject:@"app"]];
  if (i == NSOKButton) {
    NSArray *results = [panel filenames];
    if ([results count] == 1) {
      // Set the text field, then update the pref.
      [editor_ setStringValue:[results objectAtIndex:0]];
      [self setEditor:editor_];
    }
  }
}

- (NSOpenPanel *)openPanel {
  return [NSOpenPanel openPanel];
}


// Thanks to dpo and bslatkin
- (void)windowWillClose:(NSNotification *)note {
  // Make sure a quick "close" (instead of rtn/tab) gets toggled
  [self setEditor:editor_];
  [self setPython:python_];

  // Normally we recycle the preference window in a singleton.
  // (We don't need a new window if it's already open!)
  // However, on window close, we destroy the singleton.
  [gPreferenceController autorelease];  // gPreferenceController is self
  gPreferenceController = nil;
}

@end


