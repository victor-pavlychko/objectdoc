//
//  PLClangIndexDeclarationPrivate.h
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/13.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLClangIndexDeclaration.h"
#import <clang-c/Index.h>

@interface PLClangIndexDeclaration (PackagePrivate)

- (instancetype) initWithCXIdxDeclInfo: (CXIdxDeclInfo) declInfo;

@end

