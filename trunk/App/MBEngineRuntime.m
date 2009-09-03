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

#import "MBEngineRuntime.h"
#import "MBPreferences.h"
#import "GMSystemVersion.h"
#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>
#import <unistd.h>

@interface MBEngineRuntime (Private)
- (void)findPython;
- (void)findPackageManager;
- (void)findPythonPathEnvVar;
- (void)findGoogleAppEngine;
- (void)findExtraCommandLineFlags;
- (void)findProductionCommandLineFlags;
- (void)extractIfNeeded;
- (NSString *)runPackageManagerWithArg:(NSString *)arg;

// return all command-line commands (e.g. for makeLinks)
- (NSArray *)commands;
@end



@implementation MBEngineRuntime

static MBEngineRuntime *gDefaultRuntime = nil;

// Currently we ONLY have a "default"
+ (id)defaultRuntime {
  @synchronized(self) {
    if (gDefaultRuntime == nil) {
      gDefaultRuntime = [[self alloc] init];
    }
  }
  return gDefaultRuntime;
}

// TODO(jrg): make mockable (pass in bundle?)
// TODO: choke if the right stuff isn't found?
- (id)init {
  if ((self = [super init])) {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *resources = [bundle resourcePath];

    // contents of GoogleAppEngineLauncher.app/Contents/Resources/
    NSArray *contents = [[NSFileManager defaultManager] directoryContentsAtPath:resources];
    if (contents) {
      NSEnumerator *denum = [contents objectEnumerator];
      NSString *file = nil;
      while ((file = [denum nextObject])) {
        // for now, just use the first one we find.
        // TODO(jrg): use GMRegex?
        if ([file hasPrefix:@"GoogleAppEngine-"] &&
            [file hasSuffix:@".bundle"]) {
          NSString *runtime = [NSString stringWithFormat:@"%@/%@", resources, file];
          runtimeBundle_ = [NSBundle bundleWithPath:runtime];
          break;
        }
      }
    }
    if (runtimeBundle_ != nil) {
      // Delayed from awakeFromNib: to avoid a dbl-help menu problem
      // with a dialog before the menu nib is loadeed
      // [self findRuntimeContents];
    }
  }
  GMAssert(runtimeBundle_, @"No valid runtime found (install problem?)");
  return self;
}

- (void)dealloc {
  [runtimeBundle_ release];
  [pythonCommand_ release];
  [packageManagerCommand_ release];
  [pythonPathEnvVar_ release];
  [pythonExtraEnvironment_ release];
  [devAppDirectory_ release];
  [devAppServer_ release];
  [extraCommandLineFlags_ release];
  [productionCommandLineFlags_ release];
  [super dealloc];
}

- (NSString *)pythonCommand {
  return [[pythonCommand_ copy] autorelease];
}

- (void)refreshPythonCommand {
  [pythonCommand_ release];
  [self findPython];
}

- (NSString *)pythonExtraEnvironmentString {
  return [[pythonPathEnvVar_ copy] autorelease];
}

- (NSDictionary *)pythonExtraEnvironment {
  return [[pythonExtraEnvironment_ copy] autorelease];
}

- (NSString *)devAppDirectory {
  return [[devAppDirectory_ copy] autorelease];
}

- (NSString *)devAppServer {
  return [[devAppServer_ copy] autorelease];
}

- (NSArray *)demos {
  NSString *demodir = [self demoDirectory];
  NSArray *a = [[NSFileManager defaultManager] directoryContentsAtPath:demodir];
  return a;
}

- (NSString *)demoDirectory {
  return [devAppDirectory_ stringByAppendingPathComponent:@"google_appengine/demos"];
}

- (NSString *)newAppTemplateDirectory {
  NSString *path = [devAppDirectory_ stringByAppendingPathComponent:@"google_appengine/new_project_template"];
  BOOL isdir = NO;
  BOOL worked = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isdir];
  GMAssert(isdir && worked, @"No template files for new project.");
  return path;
}

- (NSString *)deployCommand {
  NSString *relative = @"google_appengine/appcfg.py";
  NSString *path = [devAppDirectory_ stringByAppendingPathComponent:relative];
  BOOL worked = [[NSFileManager defaultManager] isExecutableFileAtPath:path];
  GMAssert(worked, @"No deploy command (installation problem?)");
  return relative;
}

- (NSArray *)extraCommandLineFlags {
  return [[extraCommandLineFlags_ copy] autorelease];
}

- (NSArray *)productionCommandLineFlags {
  return [[productionCommandLineFlags_ copy] autorelease];
}

- (NSAlert *)alert {
  return [[[NSAlert alloc] init] autorelease];
}

// Returns the version embedded in the current Engine runtime.
- (NSString *)versionFileContents {
  NSString *versionFile = [devAppDirectory_ stringByAppendingPathComponent:@"google_appengine/VERSION"];
  NSData *data = [[NSFileManager defaultManager] contentsAtPath:versionFile];
  if (data == nil) {
    return @"?????";
  }
  NSString *version = [[[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding]
                        autorelease];
  return version;
}

// Helper for makeLinks
- (OSStatus)delete:(NSString *)path withAuth:(AuthorizationRef)ref {
  OSStatus myStatus;
  const char *rmargs[] = { "-f", NULL, NULL };
  rmargs[1] = (char *)[path fileSystemRepresentation];
  myStatus = AuthorizationExecuteWithPrivileges(ref,
                                                "/bin/rm",
                                                kAuthorizationFlagDefaults,
                                                (char * const*)rmargs,
                                                NULL);
  if (myStatus != errAuthorizationSuccess)
    GMLoggerError(@"Can't delete old link %@", path);
  return myStatus;
}

// Helper for makeLinks
- (OSStatus)makeLinkTo:(NSString *)to
                  from:(NSString *)from
              withAuth:(AuthorizationRef)ref {
  OSStatus myStatus;
  const char *lnargs[] = { "-s", NULL, NULL, NULL };
  lnargs[1] = (char *)[to fileSystemRepresentation];
  lnargs[2] = (char *)[from fileSystemRepresentation];
  myStatus = AuthorizationExecuteWithPrivileges(ref,
                                                "/bin/ln",
                                                kAuthorizationFlagDefaults,
                                                (char* const*)lnargs,
                                                NULL);
  if (myStatus != errAuthorizationSuccess)
    GMLoggerError(@"Can't create new link %@ --> %@", from, to);
  return myStatus;
}

// Helper for makeLinks
- (OSStatus)move:(NSString *)file
              to:(NSString *)dest
        withAuth:(AuthorizationRef)ref {
  OSStatus myStatus;
  char *mvargs[] = { NULL, NULL, NULL };
  mvargs[0] = (char *)[file fileSystemRepresentation];
  mvargs[1] = (char *)[dest fileSystemRepresentation];
  myStatus = AuthorizationExecuteWithPrivileges(ref,
                                                "/bin/mv",
                                                kAuthorizationFlagDefaults,
                                                mvargs,
                                                NULL);
  if (myStatus != errAuthorizationSuccess)
    GMLoggerError(@"Can't move %@ to %@", file, dest);
  return myStatus;
}

// It seems a little odd that an MBEngineRuntime, somewhat of a
// Data (MVC), can both perform actions (like "makeLinks") and display
// UI (like the security dialog).
// TODO(jrg): refactor.
//
// Yes, this is >80 chars, but if I split it it'a pain to C&P into a browser.
// file://localhost/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/Security/Conceptual/authorization_concepts/index.html
- (NSString *)makeLinks {
  NSMutableString *summary = [NSMutableString string];  // rtn val
  OSStatus myStatus;
  AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
  AuthorizationRef myAuthorizationRef;
  myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,
                                 myFlags, &myAuthorizationRef);
  if (myStatus != errAuthorizationSuccess) {
    GMLoggerError(@"Auth failed.");
    return summary;
  }

  AuthorizationItem myItems = {kAuthorizationRightExecute, 0,
                               NULL, 0};
  AuthorizationRights myRights = {1, &myItems};

  myFlags = kAuthorizationFlagDefaults |
      kAuthorizationFlagInteractionAllowed |
      kAuthorizationFlagPreAuthorize |
      kAuthorizationFlagExtendRights;
  myStatus = AuthorizationCopyRights(myAuthorizationRef,
                                     &myRights, NULL, myFlags, NULL );
  if (myStatus != errAuthorizationSuccess) {
    GMLoggerError(@"Auth failed.");
    return summary;
  }

  // Make sure /usr/local/bin exists
  const char *args[] = { "-p", "/usr/local/bin", NULL };
  myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef,
                                                "/bin/mkdir",
                                                kAuthorizationFlagDefaults,
                                                (char * const *)args,
                                                NULL);
  GMAssert(myStatus == errAuthorizationSuccess,
           @"Can't create /usr/local/bin");
  if (myStatus != errAuthorizationSuccess)
    return summary;

  NSArray *commands = [self commands];
  NSEnumerator *cenum = [commands objectEnumerator];
  NSString *cmd = nil;
  while ((cmd = [cenum nextObject]) != nil) {
    // Delete old link; make new one.
    if ([[cmd lastPathComponent] isEqual:@""])
      break;
    NSString *localPath = [NSString stringWithFormat:@"/usr/local/bin/%@",
                                    [cmd lastPathComponent]];

    // Hmm... this returns NO if it's a symlink.
    // if ([[NSFileManager defaultManager] fileExistsAtPath:localPath])

    [self delete:localPath withAuth:myAuthorizationRef];
    // Don't care if the above worked

    myStatus = [self makeLinkTo:cmd
                           from:localPath
                       withAuth:myAuthorizationRef];

    if (myStatus == errAuthorizationSuccess)
      [summary appendFormat:@"%@ ", [cmd lastPathComponent]];
  }

  // Finally, make the /usr/local/google_appengine link.
  NSString *sdk = [NSString stringWithFormat:@"%@/google_appengine",
                            [self devAppDirectory]];

  // Bail early if thinks look confusing
  BOOL isDir = NO;
  if ([[NSFileManager defaultManager] fileExistsAtPath:sdk isDirectory:&isDir] == NO)
    return summary;

  NSString *localPath = @"/usr/local/google_appengine";

  // If it's a directory, move it aside.
  isDir = NO;
  if ([[NSFileManager defaultManager] fileExistsAtPath:localPath isDirectory:&isDir] &&
      (isDir == YES)) {
    NSString *dest = [NSString stringWithFormat:@"%@.old", localPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dest]) {
      // try just a little harder
      dest = [NSString stringWithFormat:@"%@.old.%d", localPath, (int)getpid()];
    }
    [self move:localPath
          to:dest
          withAuth:myAuthorizationRef];
  } else {
    [self delete:localPath withAuth:myAuthorizationRef];
  }

  // Finally, make the link.
  [self makeLinkTo:sdk
              from:localPath
          withAuth:myAuthorizationRef];

  AuthorizationFree(myAuthorizationRef, kAuthorizationFlagDefaults);
  return summary;
}

- (void)findRuntimeContents {
  GMAssert(runtimeBundle_, @"No valid runtime found (install problem?)");
  [self findPython];
  [self findPackageManager];
  [self extractIfNeeded];
  [self findPythonPathEnvVar];
  [self findGoogleAppEngine];
  [self findExtraCommandLineFlags];
  [self findProductionCommandLineFlags];
}

// Don't assume any configuration has happened yet.
- (BOOL)extractionNeeded {
  extractionNeeded_ = NO;
  [self findPython];
  [self findPackageManager];
  NSString *packsToExtract = [self runPackageManagerWithArg:@"--query"];
  if ([packsToExtract length] > 0) {
    extractionNeeded_ = YES;
  }
  return extractionNeeded_;
}

@end  // MBEngineRuntime


@implementation MBEngineRuntime (Private)
- (void)findPython {
  // check the pref
  NSString *python = [[NSUserDefaults standardUserDefaults]
                       stringForKey:kMBPythonPref];
  if ((python != nil) && ([python isEqual:@""] == NO)) {
    pythonCommand_ = [python copy];
    return;
  }

  // This is really important just for 10.4 where /usr/bin/python is v2.3.
  // When we obsolete 10.4 support, /usr/bin/python will be just fine.
  NSArray *commands = [NSArray arrayWithObjects:@"/usr/bin/python2.6", /* 10.6 */
                               @"/usr/bin/python2.5", /* 10.5 */
                               @"/usr/local/bin/python2.5", /* a guess */
                               @"/Library/Frameworks/Python.framework/Versions/Current/bin/python2.5", /* MacPython.org */
                               @"/opt/local/bin/python2.5",   /* macports? */
                               @"/sw/bin/python2.5",          /* fink? */
                               nil];
  NSEnumerator *cenum = [commands objectEnumerator];
  NSString *command = nil;
  while ((command = [cenum nextObject])) {
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:command]) {
      // TODO(jrg): run with --version and look for "Python 2.5" in
      // the output string
      pythonCommand_ = [command retain];
      return;
    }
  }

  pythonCommand_ = @"/usr/bin/python"; /* when all else fails */
  if ([GMSystemVersion isLeopardOrGreater]) {
    // we're fine; python2.5 is the default.
    return;
  } else {
    NSAlert *alert = [self alert];
    [alert setMessageText:@"Python Needed"];
    NSString *text = @"Python version 2.5 could not be found.  "
        "Google App Engine may not work correctly.  "
        "Please install Python from http://www.pythonmac.org/packages/";
    [alert setInformativeText:text];
    [alert addButtonWithTitle:@"OK"];
    /* NSInteger rtn = */ [alert runModal];
  }
  return;
}

- (void)findPackageManager {
  NSString *pm = [runtimeBundle_ pathForResource:@"packagemanager" ofType:@"py"];
  GMAssert(pm, @"Can't determine how to manage packages (install problem?)");
  packageManagerCommand_ = [pm retain];
}

- (NSString *)runPackageManagerWithArg:(NSString *)arg {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:packageManagerCommand_];
  [task setCurrentDirectoryPath:[runtimeBundle_ resourcePath]];
  [task setArguments:[NSArray arrayWithObjects:arg, nil]];
  NSPipe *pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];
  [task launch];
  NSData *outData = [[pipe fileHandleForReading] readDataToEndOfFile];
  NSString *outputString = [[[NSString alloc] initWithBytes:[outData bytes]
                                                     length:[outData length]
                                                   encoding:NSASCIIStringEncoding]
                             autorelease];
  [task waitUntilExit];
  [task release];
  return outputString;
}

- (void)extractIfNeeded {
  if (extractionNeeded_) {
    [self runPackageManagerWithArg:@"--extract"];
    extractionNeeded_ = NO;
  }

  // confirm
  NSString *packsToExtract = [self runPackageManagerWithArg:@"--query"];
  if ([packsToExtract length] > 0) {
    GMLoggerError(@"The Google App Engine Runtime could not be extracted "
                  "(perhaps you are running the Launcher from the dmg?  "
                  "If so, drag copy the Launcher to your local disk first.)  "
                  "GoogleAppEngineLauncher.app may not work correctly.");
  }
}

- (void)findPythonPathEnvVar {
  GMAssert(packageManagerCommand_, @"no package manager command.");
  NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  pythonPathEnvVar_ = [[[self runPackageManagerWithArg:@"--path"]
                         stringByTrimmingCharactersInSet:charSet] retain];
  NSArray *components = [pythonPathEnvVar_ componentsSeparatedByString:@"="];
  GMAssert([components count] == 2,
           @"Sorry, pieces of GoogleAppEngineLauncher.app appear missing "
           "or corrupted, or I can't run python2.5 properly.  "
           "Output was: %@", pythonPathEnvVar_);

  NSString *key = [components objectAtIndex:0];
  NSString *value = [components objectAtIndex:1];
  GMAssert([key isEqual:@"PYTHONPATH"], @"Can't determine how to run python correctly (no value)");

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dict setObject:value forKey:key];  // PYTHONPATH=blah

  NSBundle *bundle = [NSBundle mainBundle];
  // NSString *bundleid = [bundle bundleIdentifier];
  NSString *version = [[bundle infoDictionary] objectForKey:(id)kCFBundleVersionKey];
  NSString *sdkName = [NSString stringWithFormat:@"mac-launcher-%@", version];

  // GoogleAppEngineLauncher.app is the app.
  // GoogleAppEngine is the SDK.
  // Doesn't seem right to use the launcher version in a var named '*_SDK_*'.
  [dict setObject:sdkName forKey:@"APPCFG_SDK_NAME"];
  pythonExtraEnvironment_ = [dict retain];
}

- (void)findGoogleAppEngine {
  devAppDirectory_ = [[runtimeBundle_ resourcePath] retain];
  NSString *das = [NSString stringWithFormat:@"%@/%@",
                            devAppDirectory_,
                            @"google_appengine/dev_appserver.py"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:das]) {
    devAppServer_ = [das retain];
  }
  GMAssert(devAppServer_, @"Can't find dev_appserver.py (install problem?)");
}

- (void)findExtraCommandLineFlags {
  [extraCommandLineFlags_ release];
  extraCommandLineFlags_ = [[NSArray alloc] initWithObjects:@"--admin_console_server=", nil];
}

- (void)findProductionCommandLineFlags {
  [productionCommandLineFlags_ release];
  productionCommandLineFlags_ = [[NSArray alloc] initWithObjects:@"--require_indexes", nil];
}

- (NSArray *)commands {
  NSString *dadir = [self devAppDirectory];
  NSString *sdkdir = [dadir stringByAppendingPathComponent:@"google_appengine"];

  // Find all tools (named *.py) for linking.
  // Warning: directoryContentsAtPath: does not return absolute paths.
  NSArray *tools = [[NSFileManager defaultManager] directoryContentsAtPath:sdkdir];

  NSMutableArray *array = [NSMutableArray array];
  NSEnumerator *tenum = [tools objectEnumerator];
  NSString *tool = nil;
  while ((tool = [tenum nextObject])) {
    if ([tool hasSuffix:@".py"]) {
      [array addObject:[sdkdir stringByAppendingPathComponent:tool]];
    }
  }
  return array;
}

@end  // MBEngineRuntime (Private)
