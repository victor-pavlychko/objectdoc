//
//  PLCXX.hpp
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/17.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#ifndef PLCXX_hpp
#define PLCXX_hpp

#include <clang-c/Index.h>

// libclang extension to support more context information

#if defined(__cplusplus)
extern "C" {
#endif
    
typedef struct CXPlatformAvailability2 {
    CXString Platform;
    CXVersion Introduced;
    CXVersion Deprecated;
    CXVersion Obsoleted;
    int Unavailable;
    CXString Message;
    CXString Replacement;
} CXPlatformAvailability2;

unsigned clang_Cursor_isImplicit(CXCursor C);

CXString clang_getTargetPlatformName(CXTranslationUnit TU);

int clang_getCursorPlatformAvailability2(CXCursor cursor, int *always_deprecated,
                                         CXString *deprecated_message,
                                         CXString *deprecated_replacement,
                                         int *always_unavailable,
                                         CXString *unavailable_message,
                                         CXPlatformAvailability2 *availability,
                                         int availability_size);
void clang_disposeCXPlatformAvailability2(CXPlatformAvailability2 *availability);
    

#if defined(__cplusplus)
} // extern "C"
#endif

#endif /* PLCXX_hpp */
