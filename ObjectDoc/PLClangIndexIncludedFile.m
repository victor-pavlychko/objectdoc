//
//  PLClangIndexIncludedFileInfo.m
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/16.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#import "PLClangIndexIncludedFile.h"
#import "PLClangIndexIncludedFilePrivate.h"

@implementation PLClangIndexIncludedFile {
    CXIdxIncludedFileInfo _info;
}

- (instancetype)initWithCXIdxIncludedFileInfo:(CXIdxIncludedFileInfo)info {
    self = [super init];
    if (self) {
        _info = info;
    }
    return self;
}

@end
