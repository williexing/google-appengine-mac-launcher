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
@class MBLogFilter;
@class MBProject;

// A class which handles output from an MBEngineTask should implement
// this protocol.
@protocol MBEngineTaskOutputReceiver

// Handle a line of output from the engine task.
- (void)processString:(NSString *)string;

@end  // MBEngineTaskOutputReceiver


// An MBEngineTask quacks like an NSTask but holds onto a little
// more data (the MBProject it is associated with) and has some minor
// convenience methods (e.g. -fileHandleForReading).  I would have
// liked to subclass NSTask, but it's a cluster (e.g. NSConcreteTask),
// so subclassing provides only sorrow.
@interface MBEngineTask : NSObject {
 @private
  // our NSTask
  NSTask *task_;

  // The receiver of our output
  id<MBEngineTaskOutputReceiver> receiver_;  // weak; retains us

  // The log output filter and the post-filter pipe.
  MBLogFilter *filter_;

  // The MBProject we are associated with.
  MBProject *project_;
}

+ (id)taskWithProject:(MBProject *)project;
- (id)initWithProject:(MBProject *)project;

// getter/setter for our MBProject
- (void)setProject:(MBProject *)project;
- (MBProject *)project;

// Getter for the log filter for this task. Objects wanting to add hooks
// should call this. Will be nil if this MBEngineTask object was created
// without useFilter being true.
- (MBLogFilter *)logFilter;

// Convenience routine to specify some stdin to the task.
// MUST be done before launching the task.
// The input string is not appended with each call; it is replaced.
- (void)setStandardInput:(NSString *)input;

// Return the actual NSTask we quack like
- (NSTask *)task;

// Set the output receiver
- (void)setOutputReceiver:(id<MBEngineTaskOutputReceiver>)receiver;

// Quack like an NSTask
- (void)setLaunchPath:(NSString *)path;
- (void)setArguments:(NSArray *)arguments;
- (void)setEnvironment:(NSDictionary *)dict;
- (void)setCurrentDirectoryPath:(NSString *)path;
- (void)launch;
- (void)interrupt;
- (void)waitUntilExit;

@end  // MBEngineTask


@interface MBEngineTask (ExposedForTesting)
- (void)dataIsAvailable:(NSNotification *)notification;
@end  // MBEngineTask (ExposedForTesting)

