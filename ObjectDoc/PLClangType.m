/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import "PLClangType.h"
#import "PLClangTypePrivate.h"
#import "PLClangCursorPrivate.h"
#import "PLClangNSString.h"
#import "PLAdditions.h"

CXType clang_Type_removeOuterNullability(CXType CT);

/**
 * The type of an element in the abstract syntax tree.
 */
@implementation PLClangType {
    /**
     * A reference to the owning object (the translation unit), held so that the
     * CXTranslationUnit remains valid for the lifetime of the type.
     */
    id _owner;

    /** The backing clang type */
    CXType _type;

    /** The declaration for this type, if any. */
    PLClangCursor *_declaration;

    /** The canonical type. In the case of a typedef, the underlying type behind all typedef levels. */
    PLClangType *_canonicalType;

    /** The result type of a function or method. */
    PLClangType *_resultType;

    /** The type of the pointee for a pointer type. */
    PLClangType *_pointeeType;

    /** The element type of an array, complex, or vector type. */
    PLClangType *_elementType;
}

/**
 * The type's kind.
 */
- (PLClangTypeKind) kind {
    switch (_type.kind) {
        case CXType_Invalid:
            // Unreachable, returns nil from initWithOwner:cxType:
            break;

        case CXType_Unexposed:
            return PLClangTypeKindUnexposed;

        case CXType_Void:
            return PLClangTypeKindVoid;

        case CXType_Bool:
            return PLClangTypeKindBool;

        case CXType_Char_U:
            return PLClangTypeKindCharUnsignedTarget;

        case CXType_UChar:
            return PLClangTypeKindUnsignedChar;

        case CXType_Char16:
            return PLClangTypeKindChar16;

        case CXType_Char32:
            return PLClangTypeKindChar32;

        case CXType_UShort:
            return PLClangTypeKindUnsignedShort;

        case CXType_UInt:
            return PLClangTypeKindUnsignedInt;

        case CXType_ULong:
            return PLClangTypeKindUnsignedLong;

        case CXType_ULongLong:
            return PLClangTypeKindUnsignedLongLong;

        case CXType_UInt128:
            return PLClangTypeKindUInt128;

        case CXType_Char_S:
            return PLClangTypeKindCharSignedTarget;

        case CXType_SChar:
            return PLClangTypeKindSignedChar;

        case CXType_WChar:
            return PLClangTypeKindWChar;

        case CXType_Short:
            return PLClangTypeKindShort;

        case CXType_Int:
            return PLClangTypeKindInt;

        case CXType_Long:
            return PLClangTypeKindLong;

        case CXType_LongLong:
            return PLClangTypeKindLongLong;

        case CXType_Int128:
            return PLClangTypeKindInt128;

        case CXType_Float:
            return PLClangTypeKindFloat;

        case CXType_Double:
            return PLClangTypeKindDouble;

        case CXType_LongDouble:
            return PLClangTypeKindLongDouble;

        case CXType_NullPtr:
            return PLClangTypeKindNullPtr;

        case CXType_Overload:
            return PLClangTypeKindOverload;

        case CXType_Dependent:
            return PLClangTypeKindDependent;

        case CXType_ObjCId:
            return PLClangTypeKindObjCId;

        case CXType_ObjCClass:
            return PLClangTypeKindObjCClass;

        case CXType_ObjCSel:
            return PLClangTypeKindObjCSel;

        case CXType_Float128:
            return PLClangTypeKindFloat128;

        case CXType_Complex:
            return PLClangTypeKindComplex;

        case CXType_Pointer:
            return PLClangTypeKindPointer;

        case CXType_BlockPointer:
            return PLClangTypeKindBlockPointer;

        case CXType_LValueReference:
            return PLClangTypeKindLValueReference;

        case CXType_RValueReference:
            return PLClangTypeKindRValueReference;

        case CXType_Record:
            return PLClangTypeKindRecord;

        case CXType_Enum:
            return PLClangTypeKindEnum;

        case CXType_Typedef:
            return PLClangTypeKindTypedef;

        case CXType_ObjCInterface:
            return PLClangTypeKindObjCInterface;

        case CXType_ObjCObjectPointer:
            return PLClangTypeKindObjCObjectPointer;

        case CXType_FunctionNoProto:
            return PLClangTypeKindFunctionNoPrototype;

        case CXType_FunctionProto:
            return PLClangTypeKindFunctionPrototype;

        case CXType_ConstantArray:
            return PLClangTypeKindConstantArray;

        case CXType_Vector:
            return PLClangTypeKindVector;

        case CXType_IncompleteArray:
            return PLClangTypeKindIncompleteArray;

        case CXType_VariableArray:
            return PLClangTypeKindVariableArray;

        case CXType_DependentSizedArray:
            return PLClangTypeKindDependentSizedArray;

        case CXType_MemberPointer:
            return PLClangTypeKindMemberPointer;

        case CXType_Auto:
            return PLClangTypeKindAuto;

        case CXType_Elaborated:
            return PLClangTypeKindElaborated;
        case CXType_Half:
            return PLClangTypeKindHalf;
        case CXType_Float16:
            return PLClangTypeKindFloat16;
        case CXType_ShortAccum:
            return PLClangTypeKindShortAccum;
        case CXType_Accum:
            return PLClangTypeKindAccum;
        case CXType_LongAccum:
            return PLClangTypeKindLongAccum;
        case CXType_UShortAccum:
            return PLClangTypeKindUShortAccum;
        case CXType_UAccum:
            return PLClangTypeKindUAccum;
        case CXType_ULongAccum:
            return PLClangTypeKindULongAccum;
        case CXType_Pipe:
            return PLClangTypeKindPipe;
        case CXType_OCLImage1dRO:
            return PLClangTypeKindOCLImage1dRO;
        case CXType_OCLImage1dArrayRO:
            return PLClangTypeKindOCLImage1dArrayRO;
        case CXType_OCLImage1dBufferRO:
            return PLClangTypeKindOCLImage1dBufferRO;
        case CXType_OCLImage2dRO:
            return PLClangTypeKindOCLImage2dRO;
        case CXType_OCLImage2dArrayRO:
            return PLClangTypeKindOCLImage2dArrayRO;
        case CXType_OCLImage2dDepthRO:
            return PLClangTypeKindOCLImage2dDepthRO;
        case CXType_OCLImage2dArrayDepthRO:
            return PLClangTypeKindOCLImage2dArrayDepthRO;
        case CXType_OCLImage2dMSAARO:
            return PLClangTypeKindOCLImage2dMSAARO;
        case CXType_OCLImage2dArrayMSAARO:
            return PLClangTypeKindOCLImage2dArrayMSAARO;
        case CXType_OCLImage2dMSAADepthRO:
            return PLClangTypeKindOCLImage2dMSAADepthRO;
        case CXType_OCLImage2dArrayMSAADepthRO:
            return PLClangTypeKindOCLImage2dArrayMSAADepthRO;
        case CXType_OCLImage3dRO:
            return PLClangTypeKindOCLImage3dRO;
        case CXType_OCLImage1dWO:
            return PLClangTypeKindOCLImage1dWO;
        case CXType_OCLImage1dArrayWO:
            return PLClangTypeKindOCLImage1dArrayWO;
        case CXType_OCLImage1dBufferWO:
            return PLClangTypeKindOCLImage1dBufferWO;
        case CXType_OCLImage2dWO:
            return PLClangTypeKindOCLImage2dWO;
        case CXType_OCLImage2dArrayWO:
            return PLClangTypeKindOCLImage2dArrayWO;
        case CXType_OCLImage2dDepthWO:
            return PLClangTypeKindOCLImage2dDepthWO;
        case CXType_OCLImage2dArrayDepthWO:
            return PLClangTypeKindOCLImage2dArrayDepthWO;
        case CXType_OCLImage2dMSAAWO:
            return PLClangTypeKindOCLImage2dMSAAWO;
        case CXType_OCLImage2dArrayMSAAWO:
            return PLClangTypeKindOCLImage2dArrayMSAAWO;
        case CXType_OCLImage2dMSAADepthWO:
            return PLClangTypeKindOCLImage2dMSAADepthWO;
        case CXType_OCLImage2dArrayMSAADepthWO:
            return PLClangTypeKindOCLImage2dArrayMSAADepthWO;
        case CXType_OCLImage3dWO:
            return PLClangTypeKindOCLImage3dWO;
        case CXType_OCLImage1dRW:
            return PLClangTypeKindOCLImage1dRW;
        case CXType_OCLImage1dArrayRW:
            return PLClangTypeKindOCLImage1dArrayRW;
        case CXType_OCLImage1dBufferRW:
            return PLClangTypeKindOCLImage1dBufferRW;
        case CXType_OCLImage2dRW:
            return PLClangTypeKindOCLImage2dRW;
        case CXType_OCLImage2dArrayRW:
            return PLClangTypeKindOCLImage2dArrayRW;
        case CXType_OCLImage2dDepthRW:
            return PLClangTypeKindOCLImage2dDepthRW;
        case CXType_OCLImage2dArrayDepthRW:
            return PLClangTypeKindOCLImage2dArrayDepthRW;
        case CXType_OCLImage2dMSAARW:
            return PLClangTypeKindOCLImage2dMSAARW;
        case CXType_OCLImage2dArrayMSAARW:
            return PLClangTypeKindOCLImage2dArrayMSAARW;
        case CXType_OCLImage2dMSAADepthRW:
            return PLClangTypeKindOCLImage2dMSAADepthRW;
        case CXType_OCLImage2dArrayMSAADepthRW:
            return PLClangTypeKindOCLImage2dArrayMSAADepthRW;
        case CXType_OCLImage3dRW:
            return PLClangTypeKindOCLImage3dRW;
        case CXType_OCLSampler:
            return PLClangTypeKindOCLSampler;
        case CXType_OCLEvent:
            return PLClangTypeKindOCLEvent;
        case CXType_OCLQueue:
            return PLClangTypeKindOCLQueue;
        case CXType_OCLReserveID:
            return PLClangTypeKindOCLReserveID;
        case CXType_ObjCObject:
            return PLClangTypeKindObjCObject;
        case CXType_ObjCTypeParam:
            return PLClangTypeKindObjCTypeParam;
        case CXType_Attributed:
            return PLClangTypeKindAttributed;
        case CXType_OCLIntelSubgroupAVCMcePayload:
            return PLClangTypeKindOCLIntelSubgroupAVCMcePayload;
        case CXType_OCLIntelSubgroupAVCImePayload:
            return PLClangTypeKindOCLIntelSubgroupAVCImePayload;
        case CXType_OCLIntelSubgroupAVCRefPayload:
            return PLClangTypeKindOCLIntelSubgroupAVCRefPayload;
        case CXType_OCLIntelSubgroupAVCSicPayload:
            return PLClangTypeKindOCLIntelSubgroupAVCSicPayload;
        case CXType_OCLIntelSubgroupAVCMceResult:
            return PLClangTypeKindOCLIntelSubgroupAVCMceResult;
        case CXType_OCLIntelSubgroupAVCImeResult:
            return PLClangTypeKindOCLIntelSubgroupAVCImeResult;
        case CXType_OCLIntelSubgroupAVCRefResult:
            return PLClangTypeKindOCLIntelSubgroupAVCRefResult;
        case CXType_OCLIntelSubgroupAVCSicResult:
            return PLClangTypeKindOCLIntelSubgroupAVCSicResult;
        case CXType_OCLIntelSubgroupAVCImeResultSingleRefStreamout:
            return PLClangTypeKindOCLIntelSubgroupAVCImeResultSingleRefStreamout;
        case CXType_OCLIntelSubgroupAVCImeResultDualRefStreamout:
            return PLClangTypeKindOCLIntelSubgroupAVCImeResultDualRefStreamout;
        case CXType_OCLIntelSubgroupAVCImeSingleRefStreamin:
            return PLClangTypeKindOCLIntelSubgroupAVCImeSingleRefStreamin;
        case CXType_OCLIntelSubgroupAVCImeDualRefStreamin:
            return PLClangTypeKindOCLIntelSubgroupAVCImeDualRefStreamin;
        case CXType_ExtVector:
            return PLClangTypeKindExtVector;
        case CXType_BFloat16:
            return PLClangTypeKindBFloat16;
        case CXType_Atomic:
            return PLClangTypeKindAtomic;
    }

    // Type is unknown
    abort();
}

/**
 * A Boolean value indicating whether the type has the "const" qualifier set,
 * without looking through typedefs that may have added "const" at a
 * different level.
 */
- (BOOL) isConstQualified {
    return clang_isConstQualifiedType(_type);
}

/**
 * A Boolean value indicating whether the type has the "restrict" qualifier set,
 * without looking through typedefs that may have added "restrict" at a
 * different level.
 */
- (BOOL) isRestrictQualified {
    return clang_isRestrictQualifiedType(_type);
}

/**
 * A Boolean value indicating whether the type has the "volatile" qualifier set,
 * without looking through typedefs that may have added "volatile" at
 * a different level.
 */
- (BOOL) isVolatileQualified {
    return clang_isVolatileQualifiedType(_type);
}

/**
 * A Boolean value indicating whether the type is a plain old data (POD) type.
 */
- (BOOL) isPOD {
    return clang_isPODType(_type);
}

/**
 * A Boolean value indicating whether the type is a variadic function type.
 */
- (BOOL) isVariadic {
    return clang_isFunctionTypeVariadic(_type);
}

/**
 * The cursor for the type's declaration.
 */
- (PLClangCursor *) declaration {
    return _declaration ?: (_declaration = [[PLClangCursor alloc] initWithOwner: _owner cxCursor: clang_getTypeDeclaration(_type)]);
}

/**
 * The canonical type for this type.
 *
 * Clang's type system explicitly models typedefs and all the ways
 * a specific type can be represented.  The canonical type is the underlying
 * type with all the "sugar" removed.  For example, if 'T' is a typedef
 * for 'int', the canonical type for 'T' would be 'int'.
 */
- (PLClangType *) canonicalType {
    return _canonicalType ?: (_canonicalType = [[PLClangType alloc] initWithOwner: _owner cxType: clang_getCanonicalType(_type)]);
}

/**
 * The result type associated with a function type, or nil if this is not a function type.
 */
- (PLClangType *) resultType {
    return _resultType ?: (_resultType = [[PLClangType alloc] initWithOwner: _owner cxType: clang_getResultType(_type)]);
}

/**
 * The type of the pointee, or nil if this is not a pointer type.
 */
- (PLClangType *) pointeeType {
    return _pointeeType ?: (_pointeeType = [[PLClangType alloc] initWithOwner: _owner cxType: clang_getPointeeType(_type)]);
}

/**
 * The element type of an array, complex, or vector type, or nil if this type has no element type.
 */
- (PLClangType *) elementType {
    return _elementType ?: (_elementType = [[PLClangType alloc] initWithOwner: _owner cxType: clang_getElementType(_type)]);
}

/**
 * The number of elements in an array or vector type.
 *
 * The value of this property is -1 if the type is not an array or vector type.
 */
- (long long) numberOfElements {
    return clang_getNumElements(_type);
}

- (PLClangNullability) nullability {
    switch (clang_Type_getNullability(_type)) {

        case CXTypeNullability_NonNull:
            return PLClangNullabilityNonnull;

        case CXTypeNullability_Nullable:
            return PLClangNullabilityNullable;

        case CXTypeNullability_NullableResult:
            return PLClangNullabilityNullableResult;

        case CXTypeNullability_Unspecified:
            return PLClangNullabilityExplicitlyUnspecified;
        
        case CXTypeNullability_Invalid:
        return PLClangNullabilityInvalid;
    }

    // Nullability kind is unknown
    abort();
}

/**
 * Returns a copy of the type with its outer nullability information removed.
 */
- (instancetype) typeByRemovingOuterNullability {
    return [[[self class] alloc] initWithOwner: _owner cxType: clang_Type_removeOuterNullability(_type)];
}

- (BOOL) isEqual: (id) object {
    if (![object isKindOfClass: [PLClangType class]])
        return NO;

    return clang_equalTypes(_type, [object cxType]);
}

/**
 * @internal
 * Clang should provide a function for this similar to clang_hashCursor().
 * For now this is based on the implementation of clang_equalTypes(), which
 * checks for equality of the data pointers.
 */
- (NSUInteger) hash {
    return (NSUInteger)_type.data[0] ^ (NSUInteger)_type.data[1];
}

- (NSString *) description {
    return self.spelling;
}

- (NSString *) debugDescription {
    return [NSString stringWithFormat: @"<%@: %p> %@", [self class], self, [self description]];
}

@end

/**
 * @internal
 * Package-private methods.
 */
@implementation PLClangType (PackagePrivate)

/**
 * Initialize a newly-created type with the specified clang type.
 *
 * @param owner A reference to the owner of the clang type. This reference will be retained
 * to ensure that the clang type survives for the lifetime of this instance.
 * @param type The clang type that will back this object.
 * @return An initialized type or nil if the specified clang type was invalid.
 */
- (instancetype) initWithOwner: (id) owner cxType: (CXType) type {
    PLSuperInit();

    if (type.kind == CXType_Invalid)
        return nil;

    _owner = owner;
    _type = type;
    _spelling = plclang_convert_and_dispose_cxstring(clang_getTypeSpelling(_type));

    int argCount = clang_getNumArgTypes(_type);
    if (argCount >= 0) {
        NSMutableArray *argumentTypes = [NSMutableArray arrayWithCapacity: (unsigned int)argCount];

        for (unsigned int i = 0; i < (unsigned int)argCount; i++) {
            [argumentTypes addObject: [[PLClangType alloc] initWithOwner: _owner cxType: clang_getArgType(_type, i)]];
        }

        _argumentTypes = argumentTypes;
    }

    return self;
}

- (CXType) cxType {
    return _type;
}

@end
