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

// Run state for a project, encoded in an NSNumber.
typedef enum {
  kMBProjectProductionRun = 3,
  kMBProjectRun = 2,
  kMBProjectStarting = 1,
  kMBProjectStop = 0,
  kMBProjectDied = -1
} MBRunState;

// An MBProject is a single Engine project.  On disk there is a
// folder with all our files.  A project includes other saved data
// (e.g. port to run on).  Projects can, of course, be acted upon
// (told to run), but I don't think I want that code here.
@interface MBProject : NSObject {
 @private
  // Data not saved in a file
  MBRunState runState_;
  NSNumber *identifier_;    // unique ID for this project
  // Static data saved in a file
  NSString *name_;
  NSString *path_;
  NSString *port_;
  NSString *runtime_;  // only have default; can't pick (for now).
  // extra flags for the dev_appserver.py command line
  NSMutableArray *commandLineFlags_;
  // Is our path_ valid?
  BOOL valid_;
}

// Return a project with some default values.
+ (id)project;

+ (id)projectWithName:(NSString *)name path:(NSString *)path port:(NSString *)port;

// Getters and setters.  Mostly uses KVC name convention.
- (NSString *)name;
- (NSString *)path;
- (NSString *)port;
- (MBRunState)runState;
- (id)runStateAsObject;  // for KVC
- (NSArray *)commandLineFlags;
- (void)setName:(NSString *)name;
- (void)setPath:(NSString *)path;
- (void)setPort:(NSString *)port;
- (void)setRunState:(MBRunState)runState;
- (void)setCommandLineFlags:(NSArray *)flags;

// For KVC.  Return a BOOL as an autoreleased NSNumber.  If YES, the
// path for this project is valid.  If NO, it is not.  An appropriate
// value transformer could use this information to change the color of
// the displayed text.
- (NSNumber *)valid;

// Return YES if the project path is valid; else no.
// Update the project name if needed from the project's app.yaml.
- (BOOL)verify;

// Not visible to the user: unique ID for this project.  Not saved
// across launches.
- (NSNumber *)identifier;
@end


