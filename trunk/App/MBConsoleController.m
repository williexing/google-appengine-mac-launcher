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
#import "MBProject.h"
#import "MBConsoleController.h"

@implementation MBConsoleController

- (id)init {
  return [self initWithName:@""];
}

- (id)initWithName:(NSString *)name {
  if ((self = [super initWithWindowNibName:@"Console"])) {
    if (name == nil)
      name = @"???";
    name_ = [name copy];
    [self setShouldCascadeWindows:YES];
  }
  return self;
}

- (void)dealloc {
  [name_ release];
  [task_ setOutputReceiver:nil];
  [task_ release];
  [super dealloc];
}

- (void)windowDidLoad {
  [[self window] setTitle:[NSString stringWithFormat:@"Log Console (%@)", name_]];
  [self clear];
}

- (IBAction)orderFront:(id)sender {
  [[self window] orderFront:sender];
}

- (IBAction)clearText:(id)sender {
  [self clear];
}

- (void)clear {
  NSTextStorage *storage = [textView_ textStorage];
  [storage setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
}

- (void)scrollToEnd {
  NSRange range = NSMakeRange([[textView_ textStorage] length], 0);
  [textView_ scrollRangeToVisible:range];
}

// Unfortunately, the semantics of [NSText setFont:] don't allow me to
// set a font to be used for all future text additions.  Thus, we must
// call this each time we add text.
- (void)setFont {
  [textView_ setFont:[NSFont userFixedPitchFontOfSize:12.0]];
}

// Append a new string of text to our display.
// Internal method called by our processString:.
- (void)appendString:(NSString *)string {
  NSTextStorage *storage = [textView_ textStorage];
  [storage appendAttributedString:[[[NSAttributedString alloc] initWithString:string] autorelease]];
  [self setFont];
  [self scrollToEnd];
}

- (void)appendString:(NSString *)string attributes:(NSDictionary *)attributes {
  NSTextStorage *storage = [textView_ textStorage];
  NSAttributedString *astring = [[[NSAttributedString alloc]
                                   initWithString:string
                                   attributes:attributes] autorelease];
  [storage appendAttributedString:astring];
  [self setFont];
  [self scrollToEnd];
}

// Implementation of MBEngineTaskOutputReceiver.
// Called by our MBEngineTask when a new string is ready to be displayed.
- (void)processString:(NSString *)string {
  // Cache the attributes?
  NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSColor blackColor]
                                                         forKey:NSForegroundColorAttributeName];
  [self appendString:string attributes:attributes];
}

// Set the MBEngineTask that will provide us text.
- (void)setEngineTask:(MBEngineTask *)task {
  [task_ setOutputReceiver:nil];
  [task_ autorelease];
  task_ = [task retain];
  [task_ setOutputReceiver:self];
}


@end
