//
//  PLClangPlatformAvailabilityTests.m
//  ObjectDocTests
//
//  Created by lizhuoli on 2019/4/12.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#import "PLClangTestCase.h"

@interface PLClangPlatformAvailabilityTests : PLClangTestCase

@end

@implementation PLClangPlatformAvailabilityTests

- (void)testPlatformAvailable {
    PLClangTranslationUnit *tu = [self translationUnitWithSource:@"void f() __attribute__((availability(ios,introduced=4.0)));"];
    PLClangCursor *cursor = [tu cursorWithSpelling: @"f"];
    XCTAssertNotNil(cursor);
    PLClangAvailability *availability = cursor.availability;
    PLClangPlatformAvailability *platformAvailability = availability.platformAvailabilityEntries.firstObject;
    XCTAssertTrue([platformAvailability.platformName isEqualToString:@"ios"]);
    XCTAssertEqual(platformAvailability.introducedVersion.major, 4);
    XCTAssertEqual(platformAvailability.introducedVersion.minor, 0);
}

- (void)testPlatformDeprecated {
    PLClangTranslationUnit *tu = [self translationUnitWithSource:@"void f() __attribute__((availability(macos,deprecated=10.6,message=\"message\")));"];
    PLClangCursor *cursor = [tu cursorWithSpelling: @"f"];
    XCTAssertNotNil(cursor);
    PLClangAvailability *availability = cursor.availability;
    PLClangPlatformAvailability *platformAvailability = availability.platformAvailabilityEntries.firstObject;
    XCTAssertTrue([platformAvailability.platformName isEqualToString:@"macos"]);
    XCTAssertEqual(platformAvailability.deprecatedVersion.major, 10);
    XCTAssertEqual(platformAvailability.deprecatedVersion.minor, 6);
    XCTAssertTrue([platformAvailability.message isEqualToString:@"message"]);
}

- (void)testPlatformObsoleted {
    PLClangTranslationUnit *tu = [self translationUnitWithSource:@"void f() __attribute__((availability(tvos,obsoleted=9.2)));"];
    PLClangCursor *cursor = [tu cursorWithSpelling: @"f"];
    XCTAssertNotNil(cursor);
    PLClangAvailability *availability = cursor.availability;
    PLClangPlatformAvailability *platformAvailability = availability.platformAvailabilityEntries.firstObject;
    XCTAssertTrue([platformAvailability.platformName isEqualToString:@"tvos"]);
    XCTAssertEqual(platformAvailability.obsoletedVersion.major, 9);
    XCTAssertEqual(platformAvailability.obsoletedVersion.minor, 2);
}

- (void)testPlatformUnavailable {
    PLClangTranslationUnit *tu = [self translationUnitWithSource:@"@interface T @property (getter=tGetter) int t __attribute__((availability(watchos,unavailable)));@end"];
    PLClangCursor *cursor = [tu cursorWithSpelling: @"tGetter"];
    XCTAssertNotNil(cursor);
    PLClangAvailability *availability = cursor.availability;
    PLClangPlatformAvailability *platformAvailability = availability.platformAvailabilityEntries.firstObject;
    XCTAssertTrue([platformAvailability.platformName isEqualToString:@"watchos"]);
    XCTAssertTrue(platformAvailability.isUnavailable);
}

- (void)testUnconditionalDeprecateWithMsg {
    PLClangTranslationUnit *tu = [self translationUnitWithSource:@"void f(void) __attribute__((deprecated(\"message\", \"replacement\")));"];
    PLClangCursor *cursor = [tu cursorWithSpelling: @"f"];
    XCTAssertNotNil(cursor);
    PLClangAvailability *availability = cursor.availability;
    XCTAssertTrue(availability.isUnconditionallyDeprecated);
    XCTAssertTrue([availability.unconditionalDeprecationMessage isEqualToString:@"message"]);
}

- (void)testUnconditionalUnavailableWithMsg {
    PLClangTranslationUnit *tu = [self translationUnitWithSource:@"void f(void)  __attribute__((unavailable(\"unavailable\")));"];
    PLClangCursor *cursor = [tu cursorWithSpelling: @"f"];
    XCTAssertNotNil(cursor);
    PLClangAvailability *availability = cursor.availability;
    XCTAssertTrue(availability.isUnconditionallyUnavailable);
    XCTAssertTrue([availability.unconditionalUnavailabilityMessage isEqualToString:@"unavailable"]);
}

@end
