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

#import "MBProject.h"

// Used for generating a unique project identifier.
static int gProjectIdentifier = 0;

@implementation MBProject

- (NSNumber *)uniqueIdentifier {
  NSNumber *number = nil;
  @synchronized(self) {
    number = [NSNumber numberWithInt:gProjectIdentifier++];
  }
  return number;
}

+ (id)project {
  return [[[self alloc] init] autorelease];
}

+ (id)projectWithName:(NSString *)name path:(NSString *)path port:(NSString *)port {
  MBProject *project = [self project];
  [project setName:name];
  [project setPath:path];
  [project setPort:port];
  return project;
}

- (id)init {
  if ((self = [super init])) {
    runState_ = kMBProjectStop;
    identifier_ = [[self uniqueIdentifier] retain];
    // Let's not be unfriendly by returning nil for some KVC methods
    name_ = @"";
    path_ = @"";
    port_ = @"";
    commandLineFlags_ = [[NSMutableArray alloc] init];
    valid_ = YES;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    runState_ = kMBProjectStop;
    identifier_ = [[self uniqueIdentifier] retain];
    name_ = [[coder decodeObjectForKey:@"name"] retain];
    path_ = [[coder decodeObjectForKey:@"path"] retain];
    port_ = [[coder decodeObjectForKey:@"port"] retain];
    commandLineFlags_ = [[coder decodeObjectForKey:@"flags"] retain];
    valid_ = YES;
  }
  return self;
}

- (void)dealloc {
  [identifier_ release];
  [name_ release];
  [path_ release];
  [port_ release];
  [runtime_ release];
  [commandLineFlags_ release];
  [super dealloc];
}

- (NSString *)name {
  return [[name_ copy] autorelease];
}

- (NSString *)path {
  return [[path_ copy] autorelease];
}

- (NSString *)port {
  return [[port_ copy] autorelease];
}

- (MBRunState)runState {
  return runState_;
}

- (id)runStateAsObject {
  return [NSNumber numberWithInt:runState_];
}

- (NSArray *)commandLineFlags {
  return [NSMutableArray arrayWithArray:commandLineFlags_];
}

- (void)setName:(NSString *)name {
  [name_ autorelease];
  name_ = [name copy];
  // TODO(jrg): call [self verify]?
}

- (void)setPath:(NSString *)path {
  [path_ autorelease];
  path_ = [path copy];
  // TODO(jrg): call [self verify]?
}

- (void)setPort:(NSString *)port {
  [port_ autorelease];
  port_ = [port copy];
}

- (void)setRunState:(MBRunState)runState {
  runState_ = runState;
}

- (void)setCommandLineFlags:(NSArray *)flags {
  [commandLineFlags_ autorelease];
  commandLineFlags_ = [[NSMutableArray arrayWithArray:flags] retain];
}

// We do NOT want to call [self verify] here, since this method is
// called from KVC which may be quite often (e.g. redisplay).
- (NSNumber *)valid {
  return [NSNumber numberWithBool:valid_];
}

- (BOOL)verify {
  valid_ = NO;  // until proven otherwise

  NSString *appYaml = [path_ stringByAppendingPathComponent:@"app.yaml"];

  // Implicitly verifies that path_ is a directory and contains an app.yaml
  NSData *data = [[NSFileManager defaultManager] contentsAtPath:appYaml];
  if (data == nil) {
    return valid_;
  }

  // TODO(jrg): Use a real YAML library to parse properly.
  //            This cheat will work for now but isn't ideal.
  NSArray *lines = [[[[NSString alloc] initWithData:data
                                       encoding:NSUTF8StringEncoding]
                      autorelease] componentsSeparatedByString:@"\n"];
  NSString *line = nil;
  NSEnumerator *senum = [lines objectEnumerator];
  while ((line = [senum nextObject])) {
    NSRange range = [line rangeOfString:@"application:"];
    if (range.location == 0) {
      NSString *name = [[line substringFromIndex:range.length]
                         stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      [self setName:name];
      valid_ = YES;
      break;
    }
  }

  return valid_;
}

- (NSNumber *)identifier {
  return [[identifier_ copy] autorelease];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:name_ forKey:@"name"];
  [coder encodeObject:path_ forKey:@"path"];
  [coder encodeObject:port_ forKey:@"port"];
  [coder encodeObject:commandLineFlags_ forKey:@"flags"];
}

@end

