//
//  PLClangFile.m
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/16.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#import "PLClangFile.h"
#import "PLClangFilePrivate.h"

@implementation PLClangFile {
    CXFile _file;
}

- (instancetype)initWithCXFile:(CXFile)file {
    self = [super init];
    if (self) {
        _file = file;
    }
    return self;
}

@end
