/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import "PLClangAvailability.h"
#import "PLClangAvailabilityPrivate.h"
#import "PLClangPlatformAvailabilityPrivate.h"
#import "PLClangNSString.h"
#import "PLAdditions.h"

/**
 * Availability information for an entity.
 */
@implementation PLClangAvailability

- (NSString *) description {
    NSMutableString *string = [NSMutableString string];

    switch (self.kind) {
        case PLClangAvailabilityKindAvailable:
        {
            [string appendString: @"available"];
            break;
        }

        case PLClangAvailabilityKindDeprecated:
        {
            [string appendString: @"deprecated"];
            if ([self.unconditionalDeprecationMessage length] > 0) {
                [string appendFormat: @" message: \"%@\"", self.unconditionalDeprecationMessage];
            }
            if ([self.unconditionalDeprecationReplacement length] > 0) {
                [string appendFormat: @" replacement: \"%@\"", self.unconditionalDeprecationReplacement];
            }
            break;
        }

        case PLClangAvailabilityKindUnavailable:
        {
            [string appendString: @"unavailable"];
            if ([self.unconditionalUnavailabilityMessage length] > 0) {
                [string appendFormat: @": \"%@\"", self.unconditionalUnavailabilityMessage];
            }
            break;
        }

        case PLClangAvailabilityKindInaccessible:
        {
            [string appendString: @"inaccessible"];
            break;
        }
    }

    if ([self.platformAvailabilityEntries count] > 0) {
        [string appendFormat: @"\n%@", self.platformAvailabilityEntries];
    }

    return string;
}

@end

/**
 * @internal
 * Package-private methods.
 */
@implementation PLClangAvailability (PackagePrivate)

/**
 * Initialize a newly-created availability instance with the specified clang cursor.
 *
 * @param cursor The clang cursor that will provide availability information.
 * @return An initialized availability instance.
 */
- (instancetype) initWithCXCursor: (CXCursor) cursor {
    PLSuperInit();

    _kind = [self availabilityKindForCXAvailabilityKind: clang_getCursorAvailability(cursor)];

    // Get the number of platform availability entries
    int platformCount = clang_getCursorPlatformAvailability(cursor, NULL, NULL, NULL, NULL, NULL, 0);
    NSAssert(platformCount >= 0, @"clang_getCursorPlatformAvailability() returned a negative number of platforms");

    int always_deprecated = 0;
    int always_unavailable = 0;
    CXString deprecationString = {};
    CXString deprecationReplacementString = {};
    CXString unavilableString = {};
    CXPlatformAvailability *platformAvailability = calloc((unsigned int)platformCount, sizeof(CXPlatformAvailability));
    clang_getCursorPlatformAvailability(cursor,
                                         &always_deprecated,
                                         &deprecationString,
                                         &always_unavailable,
                                         &unavilableString,
                                         platformAvailability,
                                         platformCount);

    _isUnconditionallyDeprecated = always_deprecated;
    _isUnconditionallyUnavailable = always_unavailable;
    _unconditionalDeprecationMessage = plclang_convert_and_dispose_cxstring(deprecationString);
    _unconditionalDeprecationReplacement = plclang_convert_and_dispose_cxstring(deprecationReplacementString);
    _unconditionalUnavailabilityMessage = plclang_convert_and_dispose_cxstring(unavilableString);

    NSMutableArray *entries = [NSMutableArray array];

    for (int i = 0; i < platformCount; i++) {
        PLClangPlatformAvailability *availability = [[PLClangPlatformAvailability alloc] initWithCXPlatformAvailability: platformAvailability[i]];
        [entries addObject: availability];
        clang_disposeCXPlatformAvailability(&platformAvailability[i]);
    }

    _platformAvailabilityEntries = [entries copy];
    free(platformAvailability);

    return self;
}

- (PLClangAvailabilityKind) availabilityKindForCXAvailabilityKind: (enum CXAvailabilityKind) cxAvailabilityKind {
    switch (cxAvailabilityKind) {
        case CXAvailability_Available:
            return PLClangAvailabilityKindAvailable;

        case CXAvailability_Deprecated:
            return PLClangAvailabilityKindDeprecated;

        case CXAvailability_NotAvailable:
            return PLClangAvailabilityKindUnavailable;

        case CXAvailability_NotAccessible:
            return PLClangAvailabilityKindInaccessible;
    }

    abort();
}

@end
