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

#ifdef __cplusplus
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

/**
 * \brief Returns non-zero if the cursor represents an entity that was
 * implicitly created by the compiler rather than explicitly written in the
 * source code.
 */
CINDEX_LINKAGE unsigned clang_Cursor_isImplicit(CXCursor C);

/**
 * \brief Returns the platform name for current translation unit
 * Possible values are "ios" and "macosx".
 */
CINDEX_LINKAGE CXString clang_getTargetPlatformName(CXTranslationUnit TU);

CINDEX_LINKAGE int clang_getCursorPlatformAvailability2(CXCursor cursor, int *always_deprecated,
                                                        CXString *deprecated_message,
                                                        CXString *deprecated_replacement,
                                                        int *always_unavailable,
                                                        CXString *unavailable_message,
                                                        CXPlatformAvailability2 *availability,
                                                        int availability_size);
CINDEX_LINKAGE void clang_disposeCXPlatformAvailability2(CXPlatformAvailability2 *availability);

/**
 * \brief Returns a copy of the given type with its outer nullability
 * information removed.
 */
CINDEX_LINKAGE CXType clang_Type_removeOuterNullability(CXType T);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* PLCXX_hpp */
