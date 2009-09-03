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

// This object is the main controller (in the MVC sense) for Google
// App Engine related items unrelated to process launch or execution,
// such as "Help for GoogleAppEngine".
@interface MBEngineController : NSObject {
 @protected  // not @private so it's easier to subclass and mock
  // "About Google App Engine" window.  Like the about box for the
  // app, but displays information on the embedded GAE.
  IBOutlet NSWindow *aboutWindow_;

  // In the About box, this is the launcher version string
  IBOutlet NSTextField *appVersion_;

  // In the About box, this is where the launcher text goes.
  IBOutlet NSTextView *appTextView_;

  // In the "About GAE" box, this is where the SDK text goes.
  IBOutlet NSTextView *sdkTextView_;

  // How we open URLs.  Made a member for easier unit testing.
  NSWorkspace *urlOpener_;
}

// From the help menu, open a URL to "What is Google App Engine?"
- (IBAction)helpForGoogleAppEngine:(id)sender;

// Display the version of the embedded Google App Engine (like an About box)
- (IBAction)aboutGoogleAppEngine:(id)sender;

// Utilities for aboutGoogleAppEngine:, broken out for easier unit testing.
// Return a string which represents this app's version.
- (NSString *)appVersion;

// Return an attributed string which contains informational test about
// this app.
- (NSAttributedString *)appInfo;

// Return a string which contains information (including version)
// about the Prom SDK embedded in the app.
- (NSString *)sdkInfo;

@end
