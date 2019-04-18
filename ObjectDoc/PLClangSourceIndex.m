/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import "PLClangSourceIndex.h"
#import "PLAdditions.h"
#import "PLClang.h"
#import "PLClangTranslationUnitPrivate.h"
#import "PLClangIndexDeclarationPrivate.h"
#import "PLClangDiagnosticPrivate.h"
#import "PLClangFilePrivate.h"
#import "PLClangEntityReferencePrivate.h"
#import "PLClangIndexIncludedFilePrivate.h"
#import "PLClangIndexImportedASTFilePrivate.h"

#import <clang-c/Index.h>

#define PLConvertSelf PLClangSourceIndex *self = (__bridge PLClangSourceIndex *)client_data
static int PLAbortQuery(void *client_data, void *reserved);
static void PLDiagnostic(CXClientData client_data, CXDiagnosticSet, void *reserved);
static CXIdxClientFile PLEnteredMainFile(CXClientData client_data, CXFile mainFile, void *reserved);
static CXIdxClientFile PLIncludedFile(CXClientData client_data, const CXIdxIncludedFileInfo *);
static CXIdxClientASTFile PLImportedASTFile(CXClientData client_data, const CXIdxImportedASTFileInfo *);
static CXIdxClientContainer PLStartedTranslationUnit(CXClientData client_data, void *reserved);
static void PLIndexDeclaration(void *client_data, const CXIdxDeclInfo * info);
static void PLIndexEntityReference(CXClientData client_data, const CXIdxEntityRefInfo *);


/**
 * Maintains a set of PLTranslationUnits that would typically be linked together into
 * a single executable or library.
 */
@implementation PLClangSourceIndex {
@private
    /** Backing clang index. */
    CXIndex _cIndex;
}

- (id) init {
    return [self initWithOptions: 0];
}

/**
 * Initialize a newly-created index with the specified options.
 *
 * @param options A set of PLClangIndexCreationOptions defining options for the index.
 * @return An initialized index.
 */
- (instancetype) initWithOptions: (PLClangIndexCreationOptions) options {
    PLSuperInit();

    _cIndex = clang_createIndex(!!(options & PLClangIndexCreationExcludePCHDeclarations),
                                !!(options & PLClangIndexCreationDisplayDiagnostics));

    return self;
}

/**
 * Create and return an index with the specified options.
 *
 * @param options A set of PLClangIndexCreationOptions defining options for the index.
 * @return An initialized index.
 */
+ (instancetype) indexWithOptions: (PLClangIndexCreationOptions) options {
    return [[self alloc] initWithOptions: options];
}

/**
 * Add a new translation unit from an existing AST file.
 *
 * An AST file can be created with the compiler's -emit-ast option or by using a translation unit's
 * writeToFile:error: method.
 *
 * @param path The path to the AST file.
 * @param error If an error occurs, upon return contains an NSError object that describes the problem.
 * If you are not interested in possible errors, pass in nil.
 */
- (PLClangTranslationUnit *) addTranslationUnitWithASTPath: (NSString *) path error: (NSError **) error {
    if (error)
        *error = nil;

    CXTranslationUnit tu = clang_createTranslationUnit(_cIndex, [path fileSystemRepresentation]);
    if (tu == NULL) {
        // libclang does not currently report why creation of a translation unit failed or provide
        // access to the associated diagnostics, so for now we can only return a generic failure.
        if (error) {
            *error = [NSError errorWithDomain: PLClangErrorDomain code: PLClangErrorCompiler userInfo: @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"An unrecoverable compiler error occurred.", nil)
            }];
        }
        return nil;
    }

    return [[PLClangTranslationUnit alloc] initWithOwner: self cxTranslationUnit: tu];
}

/**
 * Add a new translation unit to the receiver.
 *
 * @param path The on-disk path to the source file. May be nil if the path to the file is provided via compiler arguments.
 * @param files An array of PLClangUnsavedFile objects representing unsaved data for files within the translation unit.
 * This can include the main source file as well as any dependent headers. May be nil.
 * @param arguments Any additional clang compiler arguments to be used when parsing the translation unit.
 * @param options The options to use when creating the translation unit.
 * @param error If an error occurs, upon return contains an NSError object that describes the problem.
 * If you are not interested in possible errors, pass in nil.
 */
- (PLClangTranslationUnit *) addTranslationUnitWithSourcePath: (NSString *) path unsavedFiles: (NSArray *) files compilerArguments: (NSArray *) arguments options: (PLClangTranslationUnitCreationOptions) options error: (NSError **) error {
    /* NOTE: This implementation fetches backing data/string pointers from the passed in Objective-C arguments; these values
     * are not guaranteed to survive past the lifetime of the current autorelease pool. */
    CXTranslationUnit tu;
    char **argv = calloc(sizeof(char *), [arguments count]);
    const char *cPath = NULL;
    struct CXUnsavedFile *unsavedFiles = NULL;
    unsigned int unsavedFileCount = 0;
    unsigned int creationOptions = 0;

    if (error)
        *error = nil;

    if (path != nil)
        cPath = [path fileSystemRepresentation];

    if ([files count] > 0) {
        unsavedFileCount = (unsigned int)[files count];
        unsavedFiles = (struct CXUnsavedFile *)calloc(unsavedFileCount, sizeof(struct CXUnsavedFile));

        for (unsigned int i = 0; i < unsavedFileCount; i++) {
            PLClangUnsavedFile *file = files[i];
            if (![file isKindOfClass: [PLClangUnsavedFile class]])
                continue;

            unsavedFiles[i].Contents = [file.data bytes];
            unsavedFiles[i].Length = [file.data length];
            unsavedFiles[i].Filename = [file.path fileSystemRepresentation];
        }
    }

    for (NSUInteger i = 0; i < [arguments count]; i++)
        argv[i] = (char *) [[arguments objectAtIndex: i] UTF8String];

    if (options & PLClangTranslationUnitCreationDetailedPreprocessingRecord)
        creationOptions |= CXTranslationUnit_DetailedPreprocessingRecord;

    if (options & PLClangTranslationUnitCreationIncomplete)
        creationOptions |= CXTranslationUnit_Incomplete;

    if (options & PLClangTranslationUnitCreationPrecompilePreamble)
        creationOptions |= CXTranslationUnit_PrecompiledPreamble;

    if (options & PLClangTranslationUnitCreationCacheCodeCompletionResults)
        creationOptions |= CXTranslationUnit_CacheCompletionResults;

    if (options & PLClangTranslationUnitCreationForSerialization)
        creationOptions |= CXTranslationUnit_ForSerialization;

    if (options & PLClangTranslationUnitCreationSkipFunctionBodies)
        creationOptions |= CXTranslationUnit_SkipFunctionBodies;

    if (options & PLClangTranslationUnitCreationIncludeBriefCommentsInCodeCompletion)
        creationOptions |= CXTranslationUnit_IncludeBriefCommentsInCodeCompletion;
    
    if (options & PLClangTranslationUnitCreationCreatePreambleOnFirstParse)
        creationOptions |= CXTranslationUnit_CreatePreambleOnFirstParse;
    
    if (options & PLClangTranslationUnitCreationKeepGoing)
        creationOptions |= CXTranslationUnit_KeepGoing;
    
    if (options & PLClangTranslationUnitCreationSingleFileParse)
        creationOptions |= CXTranslationUnit_SingleFileParse;
    
    if (options & PLClangTranslationUnitCreationLimitSkipFunctionBodiesToPreamble)
        creationOptions |= CXTranslationUnit_LimitSkipFunctionBodiesToPreamble;
    
    if (options & PLClangTranslationUnitCreationIncludeAttributedTypes)
        creationOptions |= CXTranslationUnit_IncludeAttributedTypes;
    
    if (options & PLClangTranslationUnitCreationVisitImplicitAttributes)
        creationOptions |= CXTranslationUnit_VisitImplicitAttributes;

    enum CXErrorCode code = clang_parseTranslationUnit2(_cIndex,
            [path fileSystemRepresentation],
            (const char **) argv,
            (int)[arguments count],
            unsavedFiles,
            unsavedFileCount,
            creationOptions,
            &tu);

    free(argv);
    free(unsavedFiles);

    if (tu == NULL) {
        // libclang does not currently report why creation of a translation unit failed or provide
        // access to the associated diagnostics, so for now we can only return a generic failure.
        if (error) {
            *error = [NSError errorWithDomain: PLClangErrorDomain code: PLClangErrorCompiler userInfo: @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"An unrecoverable compiler error occurred.", nil),
                PLClangCXErrorDomain: @(code)
            }];
        }
        return nil;
    }

    return [[PLClangTranslationUnit alloc] initWithOwner: self cxTranslationUnit: tu];
}

/**
 * Add a new translation unit to the receiver.
 *
 * @param path The on-disk path to the source file.
 * @param data The source file's data.
 * @param arguments Any additional clang compiler arguments to be used when parsing the translation unit.
 * @param options The options to use when creating the translation unit.
 * @param error If an error occurs, upon return contains an NSError object that describes the problem.
 * If you are not interested in possible errors, pass in nil.
 */
- (PLClangTranslationUnit *) addTranslationUnitWithSourcePath: (NSString *) path fileData: (NSData *) data compilerArguments: (NSArray *) arguments options: (PLClangTranslationUnitCreationOptions) options error: (NSError **) error {
    NSArray *files = nil;
    if (data != nil) {
        PLClangUnsavedFile *file = [PLClangUnsavedFile unsavedFileWithPath: path data: data];
        files = @[file];
    }
    return [self addTranslationUnitWithSourcePath: path unsavedFiles: files compilerArguments: arguments options: options error: error];
}

/**
 * Add a new translation unit to the receiver.
 *
 * @param arguments Clang compiler arguments to be used when reading the translation unit. The path to
 * the source file must be provided as a compiler argument.
 * @param options The options to use when creating the translation unit.
 * @param error If an error occurs, upon return contains an NSError object that describes the problem.
 * If you are not interested in possible errors, pass in nil.
 */
- (PLClangTranslationUnit *) addTranslationUnitWithCompilerArguments: (NSArray *) arguments options: (PLClangTranslationUnitCreationOptions) options error: (NSError **) error {
    return [self addTranslationUnitWithSourcePath: nil fileData: nil compilerArguments: arguments options: options error: error];
}

/**
 * Add a new translation unit to the receiver.
 *
 * @param path The on-disk path to the source file.
 * @param arguments Any additional clang compiler arguments to be used when parsing the translation unit.
 * @param options The options to use when creating the translation unit.
 * @param error If an error occurs, upon return contains an NSError object that describes the problem.
 * If you are not interested in possible errors, pass in nil.
 */
- (PLClangTranslationUnit *) addTranslationUnitWithSourcePath: (NSString *) path compilerArguments: (NSArray *) arguments options: (PLClangTranslationUnitCreationOptions) options error: (NSError **) error {
    return [self addTranslationUnitWithSourcePath: path fileData: nil compilerArguments: arguments options: options error: error];
}

- (PLClangTranslationUnit *)indexSourcePath:(NSString *)path unsavedFiles:(NSArray *)files compilerArguments:(NSArray *)arguments indexOptions:(PLClangTranslationUnitIndexOptions)indexOptions creationOptions:(PLClangTranslationUnitCreationOptions)options error:(NSError *__autoreleasing *)error {
    CXTranslationUnit tu;
    char **argv = calloc(sizeof(char *), [arguments count]);
    const char *cPath = NULL;
    struct CXUnsavedFile *unsavedFiles = NULL;
    unsigned int unsavedFileCount = 0;
    unsigned int creationOptions = 0;
    
    if (error)
        *error = nil;
    
    if (path != nil)
        cPath = [path fileSystemRepresentation];
    
    if ([files count] > 0) {
        unsavedFileCount = (unsigned int)[files count];
        unsavedFiles = (struct CXUnsavedFile *)calloc(unsavedFileCount, sizeof(struct CXUnsavedFile));
        
        for (unsigned int i = 0; i < unsavedFileCount; i++) {
            PLClangUnsavedFile *file = files[i];
            if (![file isKindOfClass: [PLClangUnsavedFile class]])
                continue;
            
            unsavedFiles[i].Contents = [file.data bytes];
            unsavedFiles[i].Length = [file.data length];
            unsavedFiles[i].Filename = [file.path fileSystemRepresentation];
        }
    }
    
    for (NSUInteger i = 0; i < [arguments count]; i++)
        argv[i] = (char *) [[arguments objectAtIndex: i] UTF8String];
    
    if (options & PLClangTranslationUnitCreationDetailedPreprocessingRecord)
        creationOptions |= CXTranslationUnit_DetailedPreprocessingRecord;
    
    if (options & PLClangTranslationUnitCreationIncomplete)
        creationOptions |= CXTranslationUnit_Incomplete;
    
    if (options & PLClangTranslationUnitCreationPrecompilePreamble)
        creationOptions |= CXTranslationUnit_PrecompiledPreamble;
    
    if (options & PLClangTranslationUnitCreationCacheCodeCompletionResults)
        creationOptions |= CXTranslationUnit_CacheCompletionResults;
    
    if (options & PLClangTranslationUnitCreationForSerialization)
        creationOptions |= CXTranslationUnit_ForSerialization;
    
    if (options & PLClangTranslationUnitCreationSkipFunctionBodies)
        creationOptions |= CXTranslationUnit_SkipFunctionBodies;
    
    if (options & PLClangTranslationUnitCreationIncludeBriefCommentsInCodeCompletion)
        creationOptions |= CXTranslationUnit_IncludeBriefCommentsInCodeCompletion;
    
    if (options & PLClangTranslationUnitCreationCreatePreambleOnFirstParse)
        creationOptions |= CXTranslationUnit_CreatePreambleOnFirstParse;
    
    if (options & PLClangTranslationUnitCreationKeepGoing)
        creationOptions |= CXTranslationUnit_KeepGoing;
    
    if (options & PLClangTranslationUnitCreationSingleFileParse)
        creationOptions |= CXTranslationUnit_SingleFileParse;
    
    if (options & PLClangTranslationUnitCreationLimitSkipFunctionBodiesToPreamble)
        creationOptions |= CXTranslationUnit_LimitSkipFunctionBodiesToPreamble;
    
    if (options & PLClangTranslationUnitCreationIncludeAttributedTypes)
        creationOptions |= CXTranslationUnit_IncludeAttributedTypes;
    
    if (options & PLClangTranslationUnitCreationVisitImplicitAttributes)
        creationOptions |= CXTranslationUnit_VisitImplicitAttributes;
    
    CXIndex index = clang_createIndex(1, 0);
    IndexerCallbacks *callbacks = calloc((unsigned int)1, sizeof(IndexerCallbacks));
    CXIndexAction action = clang_IndexAction_create(index);
    callbacks->abortQuery = PLAbortQuery;
    callbacks->diagnostic = PLDiagnostic;
    callbacks->enteredMainFile = PLEnteredMainFile;
    callbacks->ppIncludedFile = PLIncludedFile;
    callbacks->importedASTFile = PLImportedASTFile;
    callbacks->startedTranslationUnit = PLStartedTranslationUnit;
    callbacks->indexDeclaration = PLIndexDeclaration;
    callbacks->indexEntityReference = PLIndexEntityReference;
    
    enum CXErrorCode code = (enum CXErrorCode)clang_indexSourceFile(action,
                                                  (__bridge CXClientData)(self),
                                                  callbacks,
                                                  sizeof(IndexerCallbacks),
                                                  indexOptions,
                                                  [path fileSystemRepresentation],
                                                  (const char **) argv,
                                                  (int)[arguments count],
                                                  unsavedFiles,
                                                  unsavedFileCount,
                                                  &tu,
                                                  creationOptions);
    
    free(argv);
    free(unsavedFiles);
    
    if (tu == NULL) {
        // libclang does not currently report why creation of a translation unit failed or provide
        // access to the associated diagnostics, so for now we can only return a generic failure.
        if (error) {
            *error = [NSError errorWithDomain: PLClangErrorDomain code: PLClangErrorCompiler userInfo: @{
                                                                                                         NSLocalizedDescriptionKey: NSLocalizedString(@"An unrecoverable compiler error occurred.", nil),
                                                                                                         PLClangCXErrorDomain: @(code)
                                                                                                         }];
        }
        return nil;
    }
    
    return [[PLClangTranslationUnit alloc] initWithOwner: self cxTranslationUnit: tu];
}

- (void) dealloc {
    if (_cIndex != NULL)
        clang_disposeIndex(_cIndex);
}

@end


#pragma mark - Callbacks

static int PLAbortQuery(void *client_data, void *reserved) {
    PLClangSourceIndex *self = (__bridge PLClangSourceIndex *)client_data;
    if ([self.delegate respondsToSelector:@selector(indexShouldAbortQuery:)]) {
        return [self.delegate indexShouldAbortQuery:self];
    } else {
        return 0;
    }
}

static void PLDiagnostic(CXClientData client_data, CXDiagnosticSet diagnostic, void *reserved) {
    PLConvertSelf;
    if ([self.delegate respondsToSelector:@selector(index:didIndexDiagnostics:)]) {
        NSArray<PLClangDiagnostic *> *diagnostics = [PLClangDiagnostic diagnosticsWithCXDiagnosticSet:diagnostic];
        [self.delegate index:self didIndexDiagnostics:diagnostics];
    }
}

static CXIdxClientFile PLEnteredMainFile(CXClientData client_data, CXFile mainFile, void *reserved) {
    PLConvertSelf;
    if ([self.delegate respondsToSelector:@selector(index:didEnterMainFile:)]) {
        PLClangFile *file = [[PLClangFile alloc] initWithCXFile:mainFile];
        [self.delegate index:self didEnterMainFile:file];
    }
    return (CXIdxClientFile)mainFile;
}

static CXIdxClientFile PLIncludedFile(CXClientData client_data, const CXIdxIncludedFileInfo * info) {
    PLConvertSelf;
    if ([self.delegate respondsToSelector:@selector(index:didIncludeFile:)]) {
        PLClangIndexIncludedFile *fileInfo = [[PLClangIndexIncludedFile alloc] initWithCXIdxIncludedFileInfo:*info];
        [self.delegate index:self didIncludeFile:fileInfo];
    }
    return (CXIdxClientFile)info->file;
}

static CXIdxClientASTFile PLImportedASTFile(CXClientData client_data, const CXIdxImportedASTFileInfo * info) {
    PLConvertSelf;
    if ([self.delegate respondsToSelector:@selector(index:didImportASTFile:)]) {
        PLClangIndexImportedASTFile *fileInfo = [[PLClangIndexImportedASTFile alloc] initWithCXIdxImportedASTFileInfo:*info];
        [self.delegate index:self didImportASTFile:fileInfo];
    }
    return (CXIdxClientFile)info->file;
}

static CXIdxClientContainer PLStartedTranslationUnit(CXClientData client_data, void *reserved) {
    PLConvertSelf;
    if ([self.delegate respondsToSelector:@selector(indexDidStartTranslationUnit:)]) {
        [self.delegate indexDidStartTranslationUnit:self];
    }
    return (CXIdxClientContainer)"TU";
}

static void PLIndexDeclaration(void *client_data, const CXIdxDeclInfo * info) {
    PLConvertSelf;
    if ([self.delegate respondsToSelector:@selector(index:didIndexDeclaration:)]) {
        PLClangIndexDeclaration *declaration = [[PLClangIndexDeclaration alloc] initWithCXIdxDeclInfo:*info];
        [self.delegate index:self didIndexDeclaration:declaration];
    }
}
static void PLIndexEntityReference(CXClientData client_data, const CXIdxEntityRefInfo * info) {
    PLConvertSelf;
    if ([self.delegate respondsToSelector:@selector(index:didIndexEntityReference:)]) {
        PLClangEntityReference *entity = [[PLClangEntityReference alloc] initWithCXIdxEntityRefInfo:*info];
        [self.delegate index:self didIndexEntityReference:entity];
    }
}
