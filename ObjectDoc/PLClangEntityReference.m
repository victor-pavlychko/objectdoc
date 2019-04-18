//
//  PLClangEntityReference.m
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/16.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#import "PLClangEntityReference.h"
#import "PLClangEntityReferencePrivate.h"

@implementation PLClangEntityReference {
    CXIdxEntityRefInfo _info;
}

- (instancetype)initWithCXIdxEntityRefInfo:(CXIdxEntityRefInfo)info {
    self = [super init];
    if (self) {
        _info = info;
    }
    return self;
}

@end
