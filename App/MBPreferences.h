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

// Keys for our preferences as saved in NSUserDefaults.
// Not all are editable from the Preferences window.

// NSString.  Location of python (e.g. /usr/local/bin/python)
#define kMBPythonPref          @"Python"

// NSString.  External app for editing (e.g. TextMate.app)
#define kMBEditorPref          @"Editor"

// BOOL.  Can the external editor open a directory?
#define kMBEditDirectoryPref   @"EditDirectory"

// NSString to use as an alt dashboard server.
// E.g. your-server.company.com
#define kMBDashboardPref       @"Dashboard"

// NSString for the deploy server.
// E.g. your-server.company.com
#define kMBDeployPref          @"Deploy"
