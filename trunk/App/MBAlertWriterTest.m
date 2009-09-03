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
#import "MBAlertWriter.h"
#import "MBAlertWriterTest.h"

/* -------------------------------------------------------- */
// Fake alert class which records a BOOL instead of running modal
@interface MBFakeAlert : NSAlert {
 @private
  BOOL didRunModal_;
}
- (BOOL)didRunModal;
- (void)clearRunModal;
@end

@implementation MBFakeAlert

// override
- (void)runModal {
  didRunModal_ = YES;
}

- (BOOL)didRunModal {
  return didRunModal_;
}

- (void)clearRunModal {
  didRunModal_ = NO;
}

@end

/* -------------------------------------------------------- */
// Subclass of MBAlertWriter which records a BOOL instead of terminating
@interface MBFakeAlertWriter : MBAlertWriter {
 @private
  BOOL didTerminate_;
}
- (BOOL)didTerminate;
- (void)clearTerminate;
@end

@implementation MBFakeAlertWriter

// override 
- (void)terminate {
  didTerminate_ = YES;
}

- (BOOL)didTerminate {
  return didTerminate_;
}

- (void)clearTerminate {
  didTerminate_ = NO;
}

@end  // MBFakeAlertWriter

/* -------------------------------------------------------- */

@implementation MBAlertWriterTest

- (void)testInit {
  MBAlertWriter *w = [[MBAlertWriter alloc] init];
  STAssertNotNil(w, nil);
  STAssertTrue([w conformsToProtocol:@protocol(GMLogWriter)], nil);
  [w release];

  w = [[MBAlertWriter alloc] initWithOriginalWriter:nil alert:nil];
  STAssertNotNil(w, nil);
  [w release];

  id<GMLogWriter> gmlw = [[GMLogger sharedLogger] writer];
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  w = [[MBAlertWriter alloc] initWithOriginalWriter:gmlw
                                              alert:alert];
  STAssertNotNil(w, nil);
  [w release];
  
}

- (void)testAlerts {
  MBFakeAlert *alert = [[[MBFakeAlert alloc] init] autorelease];
  MBFakeAlertWriter *writer = [[MBFakeAlertWriter alloc]
                                initWithOriginalWriter:nil
                                                 alert:alert];
  [[GMLogger sharedLogger] setWriter:writer];
  
  STAssertNotNil(alert, nil);
  STAssertNotNil(writer, nil);
  STAssertTrue([alert didRunModal] == NO, nil);
  STAssertTrue([writer didTerminate] == NO, nil);
  
  GMLoggerDebug(@"debug");
  GMLoggerInfo(@"info");
  STAssertTrue([alert didRunModal] == NO, nil);
  STAssertTrue([writer didTerminate] == NO, nil);

  GMLoggerError(@"error");
  STAssertTrue([alert didRunModal] == YES, nil);
  STAssertTrue([writer didTerminate] == NO, nil);
  
  [alert clearRunModal];
  STAssertTrue([alert didRunModal] == NO, nil);
  STAssertTrue([writer didTerminate] == NO, nil);

  GMLoggerAssert(@"assert");
  STAssertTrue([alert didRunModal] == YES, nil);
  STAssertTrue([writer didTerminate] == YES, nil);
  [writer clearTerminate];
  
  [writer release];
}

- (void)testInstall {
  id<GMLogWriter> w = [[GMLogger sharedLogger] writer];
  STAssertTrue([w isKindOfClass:[MBAlertWriter class]] == NO, nil);

  for (int i = 0; i < 2; i++) {
    [MBAlertWriter install];
    w = [[GMLogger sharedLogger] writer];
    STAssertTrue([w isKindOfClass:[MBAlertWriter class]] == YES, nil);
  }
}


@end
