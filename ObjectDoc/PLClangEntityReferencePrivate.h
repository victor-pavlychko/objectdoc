//
//  PLClangEntityReference+PackagePrivate.h
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/18.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#import "PLClangEntityReference.h"

#import <clang-c/Index.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLClangEntityReference (PackagePrivate)

- (instancetype)initWithCXIdxEntityRefInfo:(CXIdxEntityRefInfo)info;

@end

NS_ASSUME_NONNULL_END
