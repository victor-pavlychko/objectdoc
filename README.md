# objectdoc

Generates a HTML report or docset of the API of an Objective-C library.

It based on [LLVM](https://llvm.org/) and [clang](https://clang.llvm.org/), to parse all your Objective-C library headers' AST, to generate the correct representation of APIs.

## Supported Syntax

+ Class
+ Protocol
+ Category
+ Property
+ Method
+ C Function
+ C Block
+ C Macro
+ API Availability
+ Nullability
+ Attributes like `IBAction`
+ ...all clang supported syntax

## Status

The framework has been tested against the system frameworks and a number of third-party libraries, and have each of syntax with test cases. It's already used by [objc-diff](http://codeworkshop.net/objc-diff/).

The CLI part is not under maintained. It's recommaned to use [jazzy](https://github.com/realm/jazzy) or [appledoc](https://github.com/tomaz/appledoc) instead.

## Framework Usage

You can using objectdoc as a framework. It provide the easy to use Objective-C API wrapper for clang, and make it easy to check each of Objective-C language syntax.

It's a base tool to build your own Objective-C API related tools, such as [objc-diff](http://codeworkshop.net/objc-diff/).

```objectivec
// Setup a source index
PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:0];

// Prepare the header files
// You can also combine different headers together
NSString *combinedHeaderPath = [baseDirectory stringByAppendingPathComponent:@"_OCDAPI.h"];
PLClangUnsavedFile *unsavedFile = [PLClangUnsavedFile unsavedFileWithPath:combinedHeaderPath
                                                                     data:[source dataUsingEncoding:NSUTF8StringEncoding]];

// Parse the code translation unit
// You can pass compiler arguments, as well as the clang parser options
NSError *error;
PLClangTranslationUnit *translationUnit = [index addTranslationUnitWithSourcePath:combinedHeaderPath
                                                                     unsavedFiles:@[unsavedFile]
                                                                compilerArguments:compilerArguments
                                                                          options:PLClangTranslationUnitCreationDetailedPreprocessingRecord |
                                                                                  PLClangTranslationUnitCreationSkipFunctionBodies | PLClangTranslationUnitCreationIncludeAttributedTypes
                                                                            error:&error];

// Enumerate the each cursor and check
[translationUnit visitChildrenUsingBlock:^PLClangCursorVisitResult(PLClangCursor *cursor) {
    // Switch the cursor type
    switch (cursor.type) {
        // @property (nonatomic, strong) id t;
        case PLClangCursorKindObjCPropertyDeclaration: {
            PLClangObjCPropertyAttributes attributes = cursor.objCPropertyAttributes;
            NSString *name = cursor.displayName;
            if (attributes & PLClangObjCPropertyAttributeStrong && 
                attributes & PLClangObjCPropertyAttributeAtomic) {
                // ...
            }
        }
        // - (void)foo:(id)foo bar:(int)bar;
        case PLClangCursorKindObjCInstanceMethodDeclaration: {
            NSArray *arguments = cursor.arguments; // [id(foo), int(bar)]
            PLClangType returnType =  cursor.resultType; // void
            // ...
        }
    }
}];
```

## Command Line Usage

```
doctool --config configfile
```

See the [template page](doctool/templates/index.html) for expanded usage information.

## Requirement

+ macOS 10.13+

## Install

+ Clone the repo
+ Open the `ObjectDoc.xcodeproj`
+ Config the scheme to use `Debug` or `Release` configuration
+ Click `Build` (Command + R) and waiting
+ The first time you build need 10-20 minutes, to build the full LLVM-clang repo. Take a cup of tea and enjoy ;)
+ Done. You can grab the `ObjectDoc.framework` or install the `doctool` to your PATH.

## Test

+ Finish the Install part above
+ Run the `ObjectDocTest` Xcode scheme, check the test result.

## Dependency

- LLVM 8.0.0
- clang 8.0.0
- GRMustache 7.3.2

