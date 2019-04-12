//
//  PLClangIndexDeclaration.m
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/13.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#import "PLClangIndexDeclaration.h"
#import "PLClangIndexDeclarationPrivate.h"
#import "PLClangIndexAttributePrivate.h"

@implementation PLClangIndexDeclaration {
    @private
    CXIdxDeclInfo _declInfo;
}

- (instancetype) initWithCXIdxDeclInfo: (CXIdxDeclInfo) declInfo {
    self = [super init];
    if (self) {
        _declInfo = declInfo;
        _isRedeclaration = _declInfo.isRedeclaration;
        _isDefinition = _declInfo.isDefinition;
        _isContainer = _declInfo.isContainer;
        _isImplicit = _declInfo.isImplicit;
        size_t numAttributes = _declInfo.numAttributes;
        NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:numAttributes];
        for (size_t i = 0; i < numAttributes; i++) {
            CXIdxAttrInfo attrInfo = *(_declInfo.attributes[i]);
            PLClangIndexAttribute *attribute = [[PLClangIndexAttribute alloc] initWithCXIdxAttrInfo:attrInfo];
            [attributes addObject:attribute];
        }
        _attributes = [attributes copy];
    }
    return self;
}

@end
