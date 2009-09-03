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

#import "MBAddAppController.h"

@implementation MBAddAppController (UnitTestMethods)

- (NSOpenPanel *)openPanel {
  return [NSOpenPanel openPanel];
}

@end  // MBAddAppController (UnitTestMethods)


@implementation MBAddAppController

- (id)init {
  return [self initWithWindowNibName:@"AddNew" port:nil];
}

- (id)initWithWindowNibName:(NSString *)nibname {
  return [self initWithWindowNibName:nibname port:@"8080"];
}

- (id)initWithWindowNibName:(NSString *)nibname port:(NSString *)port {
  if ((self = [super initWithWindowNibName:nibname])) {
    port_ = [port retain];
  }
  return self;
}

- (void)windowDidLoad {
  [self setPort:port_];
}

- (void)dealloc {
  [port_ release];
  [super dealloc];
}

- (IBAction)selectDirectory:(id)sender {
  NSOpenPanel *panel = [self openPanel];
  [panel setAllowsMultipleSelection:NO];
  [panel setCanChooseDirectories:YES];
  [panel setCanChooseFiles:NO];
  [panel setCanCreateDirectories:YES];
  // TODO(jrg): I18N
  [panel setPrompt:@"Choose"];
  NSString *title = [self browseControllerTitle];
  if (title)
    [panel setTitle:title];
  NSInteger i = [panel runModalForTypes:nil];
  if (i == NSOKButton) {
    NSArray *results = [panel filenames];
    if ([results count] == 1) {
      [self setDirectoryFromBrowse:[results objectAtIndex:0]];
    }
  }
}

- (IBAction)stopModalWithSuccess:(id)sender {
  [NSApp stopModalWithCode:NSOKButton];
}

// Should be, but does not have to be, overridden.
- (NSString *)browseControllerTitle {
  return nil;
}

// Should be overridden.  
// It isn't logical to call this method without overriding it.
// COV_NF_START
- (void)setDirectoryFromBrowse:(NSString *)path {
  GMAssert(0, nil);
}
// COV_NF_END

- (NSString *)port {
  return [portField_ stringValue];
}

- (void)setPort:(NSString *)port {
  [portField_ setStringValue:port];
}

@end

