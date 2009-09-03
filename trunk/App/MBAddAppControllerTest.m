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

#import <SenTestingKit/SenTestingKit.h>
#import <Cocoa/Cocoa.h>
#import "MBAddAppController.h"
#import "MBAddAppControllerTest.h"
#import "MBHardCodedOpenPanel.h"
#import <objc/objc-class.h>


// ---------------------------------------------------------
// Override the bare minimum to prevent UI from waiting for user input.
// Instead of NSOpenPanel, we use an MBHardCodedOpenPanel.

@interface MBAddAppControllerDummyPanel : MBAddAppController {
 @private
  NSInteger return_;
  NSArray *filenames_;
  NSString *directoryFromBrowse_;
}

- (id)initWithReturnCode:(NSInteger)rtn filenames:(NSArray *)filenames;
- (NSOpenPanel *)openPanel;
- (void)setDirectoryFromBrowse:(NSString *)path;
- (NSString *)getDirectory;
- (NSString *)browseControllerTitle;

@end  // MBAddAppControllerDummyPanel


@implementation MBAddAppControllerDummyPanel

- (id)initWithReturnCode:(NSInteger)rtn filenames:(NSArray *)filenames {
  if ((self = [super initWithWindowNibName:@"AddNew" port:@"8080"])) {
    return_ = rtn;
    filenames_ = [filenames copy];
  }
  return self;
}

- (void)dealloc {
  [filenames_ release];
  [super dealloc];
}

- (NSOpenPanel *)openPanel {
  return [[[MBHardCodedOpenPanel alloc] initWithReturnCode:return_
                                                 filenames:filenames_]
           autorelease];
}

- (void)setDirectoryFromBrowse:(NSString *)path {
  directoryFromBrowse_ = [path copy];
}

- (NSString *)getDirectory {
  return directoryFromBrowse_;
}

- (NSString *)browseControllerTitle {
  NSString *title = [super browseControllerTitle];
  if (title == nil)
    title = @"title";
  return title;
}


@end  // MBAddAppControllerDummyPanel

// ---------------------------------------------------------

@implementation MBAddAppControllerTest

- (void)testSelectDirectory {
  NSArray *filenames = [NSArray arrayWithObjects:@"hi", nil];
  MBAddAppControllerDummyPanel *controller = [[[MBAddAppControllerDummyPanel alloc]
                                                initWithReturnCode:NSCancelButton
                                                         filenames:filenames]
                                               autorelease];
  STAssertNotNil(controller, nil);
  [controller windowDidLoad];
  STAssertNil([controller getDirectory], nil);
  [controller selectDirectory:self];
  STAssertNil([controller getDirectory], nil);

   controller = [[[MBAddAppControllerDummyPanel alloc]
                   initWithReturnCode:NSOKButton
                            filenames:filenames]
                  autorelease];
  STAssertNotNil(controller, nil);
  STAssertNil([controller getDirectory], nil);
  [controller selectDirectory:self];
  STAssertTrue([[controller getDirectory] isEqual:@"hi"], nil);
}

// Globals to make sure -[NSApplication stopModalWithCode:] gets called properly
static BOOL gStopped = NO;
static NSInteger gCode = 0;

// Where -[NSApplication stopModalWithCode:] gets redirected to in
// testStopModalWithCode, below
- (void)newStopModalWithCode:(NSInteger)code {
  gStopped = YES;
  gCode = code;
}

- (void)testStopModalWithCode {
  MBAddAppController *controller = [[[MBAddAppController alloc]
                                      initWithWindowNibName:@"AddNew"] autorelease];
  STAssertNotNil(controller, nil);

  // Redirect -[NSApplication stopModalWithCode:] since we want to work without UI
  Method stopModalMethod = class_getInstanceMethod([NSApplication class],
                                                   @selector(stopModalWithCode:));
  Method newStopModalMethod = class_getInstanceMethod([self class],
                                                      @selector(newStopModalWithCode:));
  IMP orig_imp = stopModalMethod->method_imp;
  stopModalMethod->method_imp = newStopModalMethod->method_imp;

  gStopped = NO;
  gCode = NSCancelButton;
  [controller stopModalWithSuccess:self];
  STAssertTrue(gStopped == YES, nil);
  STAssertTrue(gCode == NSOKButton, nil);

  // This probably isn't needed, but it can't hurt to try and clean up
  stopModalMethod->method_imp = orig_imp;

}

- (void)testOtherMethods {
  MBAddAppController *controller = [[[MBAddAppController alloc] init] autorelease];
  STAssertNotNil(controller, nil);

  controller = [[[MBAddAppController alloc]
                  initWithWindowNibName:@"AddNew"] autorelease];
  STAssertNotNil(controller, nil);
  STAssertTrue([[controller openPanel] isKindOfClass:[NSOpenPanel class]], nil);
  STAssertNil([controller browseControllerTitle], nil);
  STAssertNil([controller port], nil);
  [controller setPort:@"himom"];
  // The data is retained in an IBObject.  Since the MBAddAppController
  // wasn't created by a nib load, the outlets are all nil.
  // STAssertTrue([[controller port] isEqual:@"himom"], nil);
  STAssertNil([controller port], nil);
}

@end  // MBAddAppControllerTest
