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

#import "MBMainWindow.h"
#import "MBTaskArrayController.h"
#import "MBToolbar.h"

@interface MBMainWindow (Private)
- (void)makeToolbarItems;
- (void)makeToolbar;
@end

@implementation MBMainWindow

- (void)dealloc {
  [toolbarItems_ release];
  [validToolbarItems_ release];
  [defaultToolbarItems_ release];
  [super dealloc];
}

- (void)awakeFromNib {
  [self makeToolbarItems];
  [self makeToolbar];
  [self orderFront:self];
}

- (NSString *)toolbarIdentifier {
  return @"DocTB";
}

// Make an NSToolbarItem using |name| for the label and image (which
// it tries to find in the main bundle's resources).  Use |sel| as the
// action for this item, and (member variable) toolbarDelegate_ as the
// target.
- (NSToolbarItem *)makeTbItem:(NSString *)name
                      tooltip:(NSString *)tooltip
                     selector:(SEL)sel {
  NSToolbarItem *i = [[NSToolbarItem alloc] initWithItemIdentifier:name];
  [i autorelease];
  [i setLabel:name];
  [i setPaletteLabel:name];
  if (tooltip) {
    [i setToolTip:tooltip];
  }
  [i setTarget:toolbarTarget_];
  [i setAction:sel];

  NSBundle *bundle = [NSBundle mainBundle];
  NSString *path = [bundle pathForResource:name ofType:@"tiff"];
  NSImage *image = [[[NSImage alloc] initByReferencingFile:path] autorelease];
  [i setImage:image];
  return i;
}

// Make all toolbar items and associated data (e.g. list of valid
// toolbar items returned in n NSToolbarDelegate call such as
// toolbarAllowedItemIdentifiers:).
// TODO(jrg): internationalize!
- (void)makeToolbarItems {
  NSMutableArray *tbi = [[NSMutableArray array] retain];

  // 1st group: actions on project.
  [tbi addObject:[self makeTbItem:kMBTRun
                          tooltip:@"Run the current project.  Builds indexes as needed."
                         selector:@selector(runCurrentProjects:)]];
  [tbi addObject:[self makeTbItem:kMBTRunStrict
                          tooltip:@"Run the current project in strict production mode "
                                   "to confirm index creation.  "
                                   "Only desired before deployment."
                         selector:@selector(productionRunCurrentProjects:)]];
  [tbi addObject:[self makeTbItem:kMBTStop
                          tooltip:@"Stop the currently selected project."
                         selector:@selector(stopCurrentProjects:)]];
  [tbi addObject:[self makeTbItem:kMBTBrowse
                          tooltip:@"Connect to the current project in a browser."
                         selector:@selector(browseCurrentProjects:)]];
  [tbi addObject:[self makeTbItem:kMBTLogs
                          tooltip:@"Open the console log window of a running project."
                         selector:@selector(doConsoleForCurrentProjects:)]];
  [tbi addObject:[self makeTbItem:kMBTSDKConsole
                          tooltip:@"Open the local admin console for a running project."
                         selector:@selector(doAdminConsoleForCurrentProjects:)]];
  [tbi addObject:[[[NSToolbarItem alloc]
                    initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier]
                   autorelease]];

  // 2nd group: configure or modify the project.
  [tbi addObject:[self makeTbItem:kMBTInfo
                          tooltip:@"View and change project information and settings."
                         selector:@selector(infoOnCurrentProjects:)]];
#if DO_EDIT_TOOLBAR_BUTTON
  [tbi addObject:[self makeTbItem:kMBTEdit
                          tooltip:@"Open the current project in your favorite editor."
                         selector:@selector(editCurrentProjects:)]];
#endif  // DO_EDIT_TOOLBAR_BUTTON

#if DO_TERMINAL_TOOLBAR_BUTTON
  [tbi addObject:[self makeTbItem:kMBTTerminal
                          tooltip:@"Go to the current project in Terminal.app."
                         selector:@selector(openTerminalForCurrentProjects:)]];
#endif  // DO_TERMINAL_TOOLBAR_BUTTON

  [tbi addObject:[self makeTbItem:kMBTReveal
                          tooltip:@"Reveal the current project in the Finder."
                         selector:@selector(openFinderForCurrentProjects:)]];
  [tbi addObject:[[[NSToolbarItem alloc]
                    initWithItemIdentifier:NSToolbarSeparatorItemIdentifier]
                   autorelease]];

  // 3rd group: hit the cloud.
  [tbi addObject:[self makeTbItem:kMBTDeploy
                          tooltip:@"Deploy the current project to Google."
                         selector:@selector(deployCurrentProjects:)]];
  [tbi addObject:[[[NSToolbarItem alloc]
                    initWithItemIdentifier:NSToolbarSeparatorItemIdentifier]
                   autorelease]];

  // Do we want this?
  [tbi addObject:[self makeTbItem:kMBTDashboard
                          tooltip:@"Connect to the deployed dashboard "
                                   "for the current project in a browser."
                         selector:@selector(openDashboardForCurrentProjects:)]];

  toolbarItems_ = tbi;

  // save a list of the IDs
  NSMutableArray *vti =  [[NSMutableArray array] retain];
  NSEnumerator *e = [toolbarItems_ objectEnumerator];
  NSToolbarItem *item = nil;
  while ((item = [e nextObject])) {
    [vti addObject:[item itemIdentifier]];
  }
  validToolbarItems_ = vti;

  // Make a list of DEFAULT IDs
  defaultToolbarItems_ = [[NSArray arrayWithObjects:kMBTRun, kMBTStop,
                                   kMBTBrowse, kMBTLogs, kMBTSDKConsole,
                                   NSToolbarSeparatorItemIdentifier,
                                   kMBTEdit,
                                   NSToolbarFlexibleSpaceItemIdentifier,
                                   kMBTDeploy, kMBTDashboard,
                                   nil] retain];
}

// Make a toolbar with the icons we like and install it on myself.
// We can't create it in IB if we want our nibs to be happy on 10.4.
- (void)makeToolbar {
  NSToolbar *tb = [[[NSToolbar alloc] initWithIdentifier:[self toolbarIdentifier]]
                    autorelease];
  [tb setShowsBaselineSeparator:YES];
  [tb setAllowsUserCustomization:YES];
  [tb setDelegate:self];

  // Oddly, this line must be AFTER setDelegate: but BEFORE [self
  // setToolbar:].
  [tb setAutosavesConfiguration:YES];

  [self setToolbar:tb];
}

// The next three are methods to let us be a delegate of NSToolbar.
// I don't know why NSToolbarDelegate is a category and not a protocol.

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag {
  NSEnumerator *e = [toolbarItems_ objectEnumerator];
  NSToolbarItem *item = nil;
  while ((item = [e nextObject])) {
    if ([[item itemIdentifier] isEqual:itemIdentifier]) {
      return item;
    }
  }
  return nil;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
  return [[defaultToolbarItems_ copy] autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
  return [[validToolbarItems_ copy] autorelease];
}


@end  /* MBMainWindow */
