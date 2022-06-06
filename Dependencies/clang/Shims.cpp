
#include "CIndexDiagnostic.h"
#include "CIndexer.h"
#include "CLog.h"
#include "CXCursor.h"
#include "CXSourceLocation.h"
#include "CXString.h"
#include "CXTranslationUnit.h"
#include "CXType.h"
#include "CursorVisitor.h"
#include "clang-c/FatalErrorHandler.h"
#include "clang/AST/Attr.h"
#include "clang/AST/DeclObjCCommon.h"
#include "clang/AST/Mangle.h"
#include "clang/AST/OpenMPClause.h"
#include "clang/AST/StmtVisitor.h"
#include "clang/Basic/Diagnostic.h"
#include "clang/Basic/DiagnosticCategories.h"
#include "clang/Basic/DiagnosticIDs.h"
#include "clang/Basic/Stack.h"
#include "clang/Basic/TargetInfo.h"
#include "clang/Basic/Version.h"
#include "clang/Frontend/ASTUnit.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Index/CommentToXML.h"
#include "clang/Lex/HeaderSearch.h"
#include "clang/Lex/Lexer.h"
#include "clang/Lex/PreprocessingRecord.h"
#include "clang/Lex/Preprocessor.h"
#include "llvm/ADT/Optional.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/Config/llvm-config.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/CrashRecoveryContext.h"
#include "llvm/Support/Format.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Program.h"
#include "llvm/Support/SaveAndRestore.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/Threading.h"
#include "llvm/Support/Timer.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/thread.h"
#include <mutex>

#if LLVM_ENABLE_THREADS != 0 && defined(__APPLE__)
#define USE_DARWIN_THREADS
#endif

#ifdef USE_DARWIN_THREADS
#include <pthread.h>
#endif

using namespace clang;
using namespace clang::cxcursor;
using namespace clang::cxtu;
using namespace clang::cxindex;
using cxtype::MakeCXType;

extern "C" unsigned clang_Cursor_isImplicit(CXCursor C);
extern "C" CXType clang_Type_removeOuterNullability(CXType CT);
extern "C" CXString clang_getTargetPlatformName(CXTargetInfo TargetInfo);

unsigned clang_Cursor_isImplicit(CXCursor C) {
  if (!clang_isDeclaration(C.kind))
    return 0;

  const Decl *D = getCursorDecl(C);
  return D && D->isImplicit();
}

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

CXString clang_getTargetPlatformName(CXTargetInfo TargetInfo) {
  if (!TargetInfo)
    return cxstring::createEmpty();

  CXTranslationUnit CTUnit = TargetInfo->TranslationUnit;
  assert(!isNotUsableTU(CTUnit) &&
         "Unexpected unusable translation unit in TargetInfo");

  ASTUnit *CXXUnit = cxtu::getASTUnit(CTUnit);
  StringRef Triple =
      CXXUnit->getASTContext().getTargetInfo().getPlatformName();
  return cxstring::createDup(Triple);
}
