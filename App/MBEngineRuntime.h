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

#import <Foundation/Foundation.h>

// A Engine Runtime is everything needed to run Engine.  This included
// a specific python; a pointer to a dev_appserver.py; demos which
// work with this runtime; and so on.  Most of these are packaged into
// a bundle, embedded in GoogleAppEngineLauncher.app.  In theory we
// could have multiple Runtimes (so, for example, Engine apps don't
// break on a silent update).  However, for now we only have one, and
// projects are hard-coded to use it.
@interface MBEngineRuntime : NSObject {
 @private
  NSBundle *runtimeBundle_;
  NSString *pythonCommand_;
  NSString *packageManagerCommand_;
  NSString *pythonPathEnvVar_;
  NSDictionary *pythonExtraEnvironment_;
  NSString *devAppDirectory_;
  NSString *devAppServer_;
  NSArray *extraCommandLineFlags_;
  NSArray *productionCommandLineFlags_;
  BOOL extractionNeeded_;
}

+ (id)defaultRuntime;

// Return YES if we need to extract.
// Lets the caller know to bring up UI.
- (BOOL)extractionNeeded;

// For delayed extraction
- (void)findRuntimeContents;

// Returns a full path to the "python" command we will be using
// (e.g. /usr/bin/python)
- (NSString *)pythonCommand;

// If a preference has been set/reset, reprobe for the python command.
- (void)refreshPythonCommand;

// Returns the extra environment setting when using this python
// (e.g. "PYTHONPATH=/foo")
- (NSString *)pythonExtraEnvironmentString;

// Return the python path as a dictionary, suitable for NSTask use.
- (NSDictionary *)pythonExtraEnvironment;

// Return the directory in which dev_appserver.py lives.
- (NSString *)devAppDirectory;

// Return a full path to dev_appserver.py.
- (NSString *)devAppServer;

// Return an array of demos in this runtime.  Each item in the array
// is an NSString which contains the title (not the full path) to the demo.
- (NSArray *)demos;

// Return the path which contains all demos.
- (NSString *)demoDirectory;

// Return the directory which contains the new app template files.
// GMAssert()s if the path doesn't exist.
- (NSString *)newAppTemplateDirectory;

// Return a path for the "deploy" command (appcfg.py)
// relative to [self devAppDirectory].
// GMAssert()s if we can't return something useful.
- (NSString *)deployCommand;

// Return a list of extra command line flags to use for this runtime.
- (NSArray *)extraCommandLineFlags;

// Return a list of extra command line flags to use when running
// dev_appserver in PRODUCTION mode (e.g. not generating indices).
// These are in ADDITION to extraCommandLineFlags.
- (NSArray *)productionCommandLineFlags;

// Return an autoreleased NSAlert.  Split out to make unit testing easier.
// TODO(jrg): shows we violate MVC!
- (NSAlert *)alert;

// Returns the contents of the VERSION file embedded in the current
// Engine runtime.
- (NSString *)versionFileContents;

// Add symlinks to Prom components (e.g. dev_appserver.py) in
// /usr/local/bin.  This method may trigger an auth dialog.  Returns
// an NSString, suitable for display to the user, which represents the
// links created.
- (NSString *)makeLinks;
@end

