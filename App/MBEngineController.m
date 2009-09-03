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

#import "MBEngineController.h"
#import "MBEngineRuntime.h"

@implementation MBEngineController

- (void)awakeFromNib {
  urlOpener_ = [NSWorkspace sharedWorkspace];
}

- (IBAction)helpForGoogleAppEngine:(id)sender {
  NSURL *url = [NSURL URLWithString:@"http://code.google.com/appengine/docs/whatisgoogleappengine.html"];
  [urlOpener_ openURL:url];
}

- (NSString *)appVersion {
  NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
  NSString *shortVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
  NSString *longVersion = [infoDict objectForKey:(id)kCFBundleVersionKey];
  NSString *versionString = [NSString stringWithFormat:@"Version %@ (%@)",
                                     shortVersion, longVersion];
  return versionString;
}

- (NSAttributedString *)appInfo {
  NSDictionary *docAttr = nil;
  // Can't "mainBundle" here; breaks unit test.
  NSString *urlpath = [[NSBundle bundleForClass:[MBEngineController class]]
                                pathForResource:@"Credits"
                                         ofType:@"html"];
  NSURL *creditsURL = [NSURL fileURLWithPath:urlpath];
  NSData *htmlData = [creditsURL resourceDataUsingCache:NO];
  NSAttributedString *appInfo = [[[NSAttributedString alloc] initWithHTML:htmlData
                                                             baseURL:creditsURL
                                                  documentAttributes:&docAttr]
                                  autorelease];
  return appInfo;
}

- (NSString *)sdkInfo {
  // Add interesting text for the SDK
  MBEngineRuntime *runtime = [MBEngineRuntime defaultRuntime];
  NSString *version = [runtime versionFileContents];
  NSString *string = [NSString stringWithFormat:@"%@\n",
                               version];
  return string;
}

- (IBAction)aboutGoogleAppEngine:(id)sender {

  // first, clear the text.
  NSTextStorage *appstorage = [appTextView_ textStorage];
  [appstorage setAttributedString:[[[NSAttributedString alloc]
                                     initWithString:@""] autorelease]];
  NSTextStorage *sdkstorage = [sdkTextView_ textStorage];
  [sdkstorage setAttributedString:[[[NSAttributedString alloc]
                                     initWithString:@""] autorelease]];

  // Then add something interesting
  [appVersion_ setStringValue:[self appVersion]];
  [appstorage setAttributedString:[self appInfo]];
  NSString *string = [self sdkInfo];
  NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:10.0]
                                                         forKey:NSFontAttributeName];
  [sdkstorage appendAttributedString:[[[NSAttributedString alloc]
                                        initWithString:string
                                            attributes:attributes]
                                       autorelease]];
  [sdkTextView_ setAlignment:NSCenterTextAlignment];

  // Finally, bring out the window.
  [[aboutWindow_ contentView] setNeedsDisplay:YES];
  [aboutWindow_ center];
  [aboutWindow_ makeKeyAndOrderFront:self];
}


@end

