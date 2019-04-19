//
//  PLCXX.cpp
//  ObjectDoc
//
//  Created by lizhuoli on 2019/4/17.
//  Copyright © 2019 Landon Fuller. All rights reserved.
//

#include "PLCXX.h"
#include <clang-cxx/CXType.h>
#include <clang-cxx/CXCursor.h>
#include <clang-cxx/CXTranslationUnit.h>
#include <clang/AST/Decl.h>
#include <clang/AST/DeclObjC.h>
#include <clang/AST/Expr.h>
#include <clang/AST/Type.h>
#include <clang/Frontend/ASTUnit.h>

using namespace clang;
using namespace clang::cxtu;
using namespace clang::cxcursor;

static CXVersion convertVersion(VersionTuple In) {
    CXVersion Out = { -1, -1, -1 };
    if (In.empty())
        return Out;
    
    Out.Major = In.getMajor();
    
    Optional<unsigned> Minor = In.getMinor();
    if (Minor.hasValue())
        Out.Minor = *Minor;
    else
        return Out;
    
    Optional<unsigned> Subminor = In.getSubminor();
    if (Subminor.hasValue())
        Out.Subminor = *Subminor;
    
    return Out;
}

static void getCursorPlatformAvailabilityForDecl(
                                                 const Decl *D, int *always_deprecated, CXString *deprecated_message, CXString *deprecated_replacement,
                                                 int *always_unavailable, CXString *unavailable_message,
                                                 SmallVectorImpl<AvailabilityAttr *> &AvailabilityAttrs) {
    bool HadAvailAttr = false;
    for (auto A : D->attrs()) {
        if (DeprecatedAttr *Deprecated = dyn_cast<DeprecatedAttr>(A)) {
            HadAvailAttr = true;
            if (always_deprecated)
                *always_deprecated = 1;
            if (deprecated_message) {
                clang_disposeString(*deprecated_message);
                *deprecated_message = cxstring::createDup(Deprecated->getMessage());
            }
            if (deprecated_replacement) {
                clang_disposeString(*deprecated_replacement);
                *deprecated_replacement = cxstring::createDup(Deprecated->getReplacement());
            }
            continue;
        }
        
        if (UnavailableAttr *Unavailable = dyn_cast<UnavailableAttr>(A)) {
            HadAvailAttr = true;
            if (always_unavailable)
                *always_unavailable = 1;
            if (unavailable_message) {
                clang_disposeString(*unavailable_message);
                *unavailable_message = cxstring::createDup(Unavailable->getMessage());
            }
            continue;
        }
        
        if (AvailabilityAttr *Avail = dyn_cast<AvailabilityAttr>(A)) {
            AvailabilityAttrs.push_back(Avail);
            HadAvailAttr = true;
        }
    }
    
    if (!HadAvailAttr)
        if (const EnumConstantDecl *EnumConst = dyn_cast<EnumConstantDecl>(D))
            return getCursorPlatformAvailabilityForDecl(
                                                        cast<Decl>(EnumConst->getDeclContext()), always_deprecated,
                                                        deprecated_message, deprecated_replacement, always_unavailable, unavailable_message,
                                                        AvailabilityAttrs);
    
    if (AvailabilityAttrs.empty())
        return;
    
    llvm::sort(AvailabilityAttrs,
               [](AvailabilityAttr *LHS, AvailabilityAttr *RHS) {
                   return LHS->getPlatform()->getName() <
                   RHS->getPlatform()->getName();
               });
    ASTContext &Ctx = D->getASTContext();
    auto It = std::unique(
                          AvailabilityAttrs.begin(), AvailabilityAttrs.end(),
                          [&Ctx](AvailabilityAttr *LHS, AvailabilityAttr *RHS) {
                              if (LHS->getPlatform() != RHS->getPlatform())
                                  return false;
                              
                              if (LHS->getIntroduced() == RHS->getIntroduced() &&
                                  LHS->getDeprecated() == RHS->getDeprecated() &&
                                  LHS->getObsoleted() == RHS->getObsoleted() &&
                                  LHS->getMessage() == RHS->getMessage() &&
                                  LHS->getReplacement() == RHS->getReplacement())
                                  return true;
                              
                              if ((!LHS->getIntroduced().empty() && !RHS->getIntroduced().empty()) ||
                                  (!LHS->getDeprecated().empty() && !RHS->getDeprecated().empty()) ||
                                  (!LHS->getObsoleted().empty() && !RHS->getObsoleted().empty()))
                                  return false;
                              
                              if (LHS->getIntroduced().empty() && !RHS->getIntroduced().empty())
                                  LHS->setIntroduced(Ctx, RHS->getIntroduced());
                              
                              if (LHS->getDeprecated().empty() && !RHS->getDeprecated().empty()) {
                                  LHS->setDeprecated(Ctx, RHS->getDeprecated());
                                  if (LHS->getMessage().empty())
                                      LHS->setMessage(Ctx, RHS->getMessage());
                                  if (LHS->getReplacement().empty())
                                      LHS->setReplacement(Ctx, RHS->getReplacement());
                              }
                              
                              if (LHS->getObsoleted().empty() && !RHS->getObsoleted().empty()) {
                                  LHS->setObsoleted(Ctx, RHS->getObsoleted());
                                  if (LHS->getMessage().empty())
                                      LHS->setMessage(Ctx, RHS->getMessage());
                                  if (LHS->getReplacement().empty())
                                      LHS->setReplacement(Ctx, RHS->getReplacement());
                              }
                              
                              return true;
                          });
    AvailabilityAttrs.erase(It, AvailabilityAttrs.end());
}

unsigned clang_Cursor_isImplicit(CXCursor C) {
    if (clang_isDeclaration(C.kind)) {
        if (const Decl *D = getCursorDecl(C))
            return D->isImplicit();
    }

    return 0;
}

CXString clang_getTargetPlatformName(CXTranslationUnit TU) {
    ASTContext &Context = getASTUnit(TU)->getASTContext();
    return cxstring::createDup(Context.getTargetInfo().getPlatformName());
}

int clang_getCursorPlatformAvailability2(CXCursor cursor, int *always_deprecated,
                                         CXString *deprecated_message,
                                         CXString *deprecated_replacement,
                                         int *always_unavailable,
                                         CXString *unavailable_message,
                                         CXPlatformAvailability2 *availability,
                                         int availability_size) {
    if (always_deprecated)
        *always_deprecated = 0;
    if (deprecated_message)
        *deprecated_message = cxstring::createEmpty();
    if (deprecated_replacement)
        *deprecated_replacement = cxstring::createEmpty();
    if (always_unavailable)
        *always_unavailable = 0;
    if (unavailable_message)
        *unavailable_message = cxstring::createEmpty();
    
    if (!clang_isDeclaration(cursor.kind))
        return 0;
    
    const Decl *D = cxcursor::getCursorDecl(cursor);
    if (!D)
        return 0;
    
    SmallVector<AvailabilityAttr *, 8> AvailabilityAttrs;
    getCursorPlatformAvailabilityForDecl(D, always_deprecated, deprecated_message, deprecated_replacement,
                                         always_unavailable, unavailable_message,
                                         AvailabilityAttrs);
    for (const auto &Avail :
         llvm::enumerate(llvm::makeArrayRef(AvailabilityAttrs)
                         .take_front(availability_size))) {
             availability[Avail.index()].Platform =
             cxstring::createDup(Avail.value()->getPlatform()->getName());
             availability[Avail.index()].Introduced =
             convertVersion(Avail.value()->getIntroduced());
             availability[Avail.index()].Deprecated =
             convertVersion(Avail.value()->getDeprecated());
             availability[Avail.index()].Obsoleted =
             convertVersion(Avail.value()->getObsoleted());
             availability[Avail.index()].Unavailable = Avail.value()->getUnavailable();
             availability[Avail.index()].Message =
             cxstring::createDup(Avail.value()->getMessage());
             availability[Avail.index()].Replacement =
             cxstring::createDup(Avail.value()->getReplacement());
         }
    
    return AvailabilityAttrs.size();
}

void clang_disposeCXPlatformAvailability2(CXPlatformAvailability2 *availability) {
    clang_disposeString(availability->Platform);
    clang_disposeString(availability->Message);
    clang_disposeString(availability->Replacement);
}

using cxtype::MakeCXType;

static inline QualType GetQualType(CXType CT) {
    return QualType::getFromOpaquePtr(CT.data[0]);
}

static inline CXTranslationUnit GetTU(CXType CT) {
    return static_cast<CXTranslationUnit>(CT.data[1]);
}

CXType clang_Type_removeOuterNullability(CXType CT) {
    QualType QT = GetQualType(CT);
    if (QT.isNull())
        return CT;
    
    if (AttributedType::stripOuterNullability(QT))
        return MakeCXType(QT, GetTU(CT));
    
    return CT;
}
