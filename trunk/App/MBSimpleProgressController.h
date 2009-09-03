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

// Controller for a simple progress dialog; a sheet with some
// text and a progress indicator.  It's modal but
// has no buttons (it goes away when done; can't be cancelled.)
@interface MBSimpleProgressController : NSWindowController {
 @private
  IBOutlet NSProgressIndicator *progressIndicator_;
  IBOutlet NSTextField *messageField_;
}

// Get and set the content string of this sheet
- (NSString *)message;
- (void)setMessage:(NSString *)message;

// Start the progress indicator running
- (void)startAnimation;

@end

