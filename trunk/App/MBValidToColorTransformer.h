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

// An MBProject has a valid state for a directory which we want to use
// to change the display color.  Using KVC we connect an MBProject and
// the project window, which displays a rep of the project.  However,
// if the MBProject (M in MVC) directly hands the project window (V in
// MVC) a color, we break the MVC model.  The NSValueTransformer,
// which sits between them (and is also a V in MVC), helps us maintain
// our abstraction by converting a valid state to a color.
@interface MBValidToColorTransformer : NSValueTransformer

+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;

@end

