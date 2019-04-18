//
//  PLClangIndexImportedASTFileInfo.m
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/16.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#import "PLClangIndexImportedASTFile.h"
#import "PLClangIndexImportedASTFilePrivate.h"

@implementation PLClangIndexImportedASTFile {
    CXIdxImportedASTFileInfo _info;
}

- (instancetype)initWithCXIdxImportedASTFileInfo:(CXIdxImportedASTFileInfo)info {
    self = [super init];
    if (self) {
        _info = info;
    }
    return self;
}

@end
