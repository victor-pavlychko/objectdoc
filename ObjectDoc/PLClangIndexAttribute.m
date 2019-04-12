//
//  PLClangIndexAttribute.m
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/13.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#import "PLClangIndexAttribute.h"
#import "PLClangIndexAttributePrivate.h"
#import "PLClangCursorPrivate.h"
#import "PLClangSourceLocationPrivate.h"

@implementation PLClangIndexAttribute {
    CXIdxAttrInfo _attrInfo;
    PLClangCursor *_cursor;
    PLClangSourceLocation *_location;
}

- (instancetype) initWithCXIdxAttrInfo: (CXIdxAttrInfo) attrInfo {
    self = [super init];
    if (self) {
        _attrInfo = attrInfo;
    }
    return self;
}

- (PLClangIndexAttributeKind)kind {
    switch (_attrInfo.kind) {
        case CXIdxAttr_Unexposed:
            return PLClangIndexAttributeKindUnexposed;
        case CXIdxAttr_IBAction:
            return PLClangIndexAttributeKindIBAction;
        case CXIdxAttr_IBOutlet:
            return PLClangIndexAttributeKindIBOutlet;
        case CXIdxAttr_IBOutletCollection:
            return PLClangIndexAttributeKindIBOutletCollection;
    }
    // Attr has an unknown kind
    abort();
}

- (PLClangCursor *)cursor {
    return _cursor ?: (_cursor = [[PLClangCursor alloc] initWithOwner:self cxCursor:_attrInfo.cursor]);
}

- (PLClangSourceLocation *)location {
    return _location ?: (_location = [[PLClangSourceLocation alloc] initWithOwner: self cxSourceLocation: clang_indexLoc_getCXSourceLocation(_attrInfo.loc)]);
}

@end
