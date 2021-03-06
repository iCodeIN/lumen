#ifndef EIR_BASE_TD
#define EIR_BASE_TD

include "EIRDialect.td"

//===----------------------------------------------------------------------===//
// Term Representation
//===----------------------------------------------------------------------===//

class eir_EC<string name, int flag> : BitEnumAttrCase<name, flag>;

/// Constants
def eir_EC_ConstNone  : eir_EC<"ConstNone", 0x0000>;
def eir_EC_ConstNil   : eir_EC<"ConstNil", 0x0001>;
def eir_EC_ConstFalse : eir_EC<"ConstFalse", 0x0002>;
def eir_EC_ConstTrue  : eir_EC<"ConstTrue", 0x0004>;

/// Representation
def eir_EC_Arch32     : eir_EC<"Arch32", 0x0008>;
def eir_EC_Arch64     : eir_EC<"Arch64", 0x0010>;
def eir_EC_Arch64n    : eir_EC<"Arch64Nanboxed", 0x0020>;
def eir_EC_Immediate  : eir_EC<"Immediate", 0x0040>;
def eir_EC_Boxed      : eir_EC<"Boxed", 0x0080>;
def eir_EC_Literal    : eir_EC<"Literal", 0x0100>;
def eir_EC_Header     : eir_EC<"Header", 0x0200>;

def eir_EncodingAttr : BitEnumAttr<"Encoding", "term encoding metadata", [
  eir_EC_ConstNone,
  eir_EC_ConstNil,
  eir_EC_ConstFalse,
  eir_EC_ConstTrue,
  eir_EC_Arch32,
  eir_EC_Arch64,
  eir_EC_Arch64n,
  eir_EC_Immediate,
  eir_EC_Boxed,
  eir_EC_Literal,
]> {
  let cppNamespace = "lumen::eir";
}

//===----------------------------------------------------------------------===//
// Types
//===----------------------------------------------------------------------===//

class eir_TermKind<string name, int kind> : I32EnumAttrCase<name, kind>;

def eir_TK_None    : eir_TermKind<"None", 0>;
def eir_TK_Term    : eir_TermKind<"Term", 1>;
def eir_TK_List    : eir_TermKind<"List", 2>;
def eir_TK_Number  : eir_TermKind<"Number", 3>;
def eir_TK_Integer : eir_TermKind<"Integer", 4>;
def eir_TK_Float   : eir_TermKind<"Float", 5>;
def eir_TK_Atom    : eir_TermKind<"Atom", 6>;
def eir_TK_Boolean : eir_TermKind<"Boolean", 7>;
def eir_TK_Fixnum  : eir_TermKind<"Fixnum", 8>;
def eir_TK_BigInt  : eir_TermKind<"BigInt", 9>;
def eir_TK_Nil     : eir_TermKind<"Nil", 10>;
def eir_TK_Cons    : eir_TermKind<"Cons", 11>;
def eir_TK_Tuple   : eir_TermKind<"Tuple", 12>;
def eir_TK_Map     : eir_TermKind<"Map", 13>;
def eir_TK_Closure : eir_TermKind<"Closure", 14>;
def eir_TK_Binary  : eir_TermKind<"Binary", 15>;
def eir_TK_HeapBin : eir_TermKind<"HeapBin", 16>;
def eir_TK_ProcBin : eir_TermKind<"ProcBin", 17>;
def eir_TK_Box     : eir_TermKind<"Box", 18>;
def eir_TK_Pid     : eir_TermKind<"Pid", 19>;
def eir_TK_Reference : eir_TermKind<"Reference", 20>;

class eir_TermTypeBase<eir_TermKind kind, string description> : DialectType<
  eir_Dialect,
  CPred<"$_self.isa<::lumen::eir::" # kind.symbol # "Type>()">,
  description> {
  eir_TermKind termKind = kind;
}

class eir_BuildableTermType<eir_TermKind kind, string description, code builder> :
  eir_TermTypeBase<kind, description>,
  BuildableType<builder> {
}

class eir_TermType<eir_TermKind kind, string description, string typename = kind.symbol> :
  eir_BuildableTermType<kind, description, "$_builder.getType<::lumen::eir::" # typename # "Type>()"> {
}

class eir_ReceiveStatus<string name, int kind> : IntEnumAttrCaseBase<I8, name, name, kind>;

def eir_RS_Error    : eir_ReceiveStatus<"Error", 0>;
def eir_RS_Ready    : eir_ReceiveStatus<"Ready", 1>;
def eir_RS_Received : eir_ReceiveStatus<"Received", 2>;
def eir_RS_Timeout  : eir_ReceiveStatus<"Timeout", 3>;

class eir_ProcessSignal<string name, int kind> : IntEnumAttrCaseBase<I8, name, name, kind>;

def eir_PS_None           : eir_ProcessSignal<"None", 0>;
def eir_PS_Yield          : eir_ProcessSignal<"Yield", 1>;
def eir_PS_GarbageCollect : eir_ProcessSignal<"GarbageCollect", 2>;
def eir_PS_Error          : eir_ProcessSignal<"Error", 3>;
def eir_PS_Exit           : eir_ProcessSignal<"Exit", 4>;

def eir_ReceiveStatusAttr : IntEnumAttr<I8, "ReceiveStatus", "receive wait status", [
  eir_RS_Error,
  eir_RS_Ready,
  eir_RS_Received,
  eir_RS_Timeout,
]> {
  let cppNamespace = "lumen::eir";
}

def eir_ReceiveStatusType : TypeAlias<I8, "receive wait status type">;

def eir_NoneType : eir_TermType<eir_TK_None, "none">;
def eir_AtomType : eir_TermType<eir_TK_Atom, "atom">;
def eir_BoolType : eir_TermType<eir_TK_Boolean, "bool">;
def eir_FixnumType : eir_TermType<eir_TK_Fixnum, "fixnum">;
def eir_BigIntType : eir_TermType<eir_TK_BigInt, "bigint">;
def eir_NumberType : eir_TermType<eir_TK_Number, "number">;
def eir_IntegerType : eir_TermType<eir_TK_Integer, "integer">;
def eir_FloatType : eir_TermType<eir_TK_Float, "float">;
def eir_NilType : eir_TermType<eir_TK_Nil, "nil">;
def eir_ConsType : eir_TermType<eir_TK_Cons, "cons">;
def eir_ListType : eir_TermType<eir_TK_List, "list">;
def eir_TupleType : eir_TermType<eir_TK_Tuple, "tuple">;
def eir_MapType : eir_TermType<eir_TK_Map, "map">;
def eir_ClosureType : eir_TermType<eir_TK_Closure, "closure">;
def eir_BinaryType : eir_TermType<eir_TK_Binary, "binary">;
def eir_HeapBinType : eir_TermType<eir_TK_HeapBin, "heapbin">;
def eir_ProcBinType : eir_TermType<eir_TK_ProcBin, "procbin">;
def eir_BoxType : eir_TermTypeBase<eir_TK_Box, "box">;
def eir_PidType : eir_TermTypeBase<eir_TK_Pid, "pid">;
def eir_ReferenceType : eir_TermTypeBase<eir_TK_Reference, "reference">;

// NOTE: Adding a custom type which is _not_ a term type that is in the TermKind enumeration
// such as those below, require adding the type to eirDialect::initialize manually. If you
// forget this step, things will explode at some point during compilation, so its important
// to make sure you make the change in both places at the same time
def eir_RefType : Type<CPred<"$_self.isa<eir::RefType>()">, "pointer type">;
def eir_PtrType : Type<CPred<"$_self.isa<eir::PtrType>()">, "raw pointer type">;
def eir_ReceiveRefType : Type<CPred<"$_self.isa<eir::ReceiveRefType>()">, "opaque receive reference">;
def eir_TraceRefType : Type<CPred<"$_self.isa<eir::TraceRefType>()">, "opaque trace reference">;

// These are simply type constraints, they have no actual type definition in EIRTypes.h
def eir_AnyTerm : Type<CPred<"$_self.isa<::lumen::eir::TermType>()">, "dynamic term type">,
                   BuildableType<"$_builder.getType<::lumen::eir::TermType>()">;
def eir_AnyType : Type<CPred<"$_self.isa<::lumen::eir::OpaqueTermType>()">, "any term type">,
                   BuildableType<"$_builder.getType<::lumen::eir::TermType>()">;
def eir_BoolLike : AnyTypeOf<[I1, eir_BoolType], "boolean-like type">;
def eir_FixnumLike : AnyTypeOf<[AnyInteger, eir_FixnumType], "fixed-width integer type">;
def eir_FloatLike : AnyTypeOf<[F64, eir_FloatType], "float-like type">;
def eir_ListLike : AnyTypeOf<[eir_NilType, eir_ConsType, eir_ListType], "list-like type">;
def eir_BinaryLike : AnyTypeOf<[eir_BinaryType, eir_HeapBinType, eir_ProcBinType], "binary-like type">;
def eir_PointerLike : AnyTypeOf<[eir_BoxType, eir_RefType, eir_PtrType], "pointer-like type">;

//===----------------------------------------------------------------------===//
// Attributes
//===----------------------------------------------------------------------===//

class APIntAttrBase<Type attrValType, Pred condition, string descr> :
  DialectAttr<
    eir_Dialect,
    And<[CPred<"$_self.isa<APIntAttr>()">, condition]>,
    descr> {

  let constBuilderCall = "::lumen::eir::APIntAttr::get($_builder.getContext(), " # attrValType.builderCall # ", $0)";
  let storageType = "::lumen::eir::APIntAttr";
  let returnType = "::llvm::APInt";
  let valueType = attrValType;
}

def FixnumAttr : APIntAttrBase<eir_FixnumType, CPred<"$_self.cast<APIntAttr>().getType().isa<FixnumType>()">, "fixed-width integer attribute">;
def BigIntAttr : APIntAttrBase<eir_BigIntType, CPred<"$_self.cast<APIntAttr>().getType().isa<BigIntType>()">, "arbitrary-width integer attribute">;

def APFloatAttr : DialectAttr<eir_Dialect, CPred<"$_self.isa<APFloatAttr>()">,
                     "floating-point attribute"> {
  let storageType = "::lumen::eir::APFloatAttr";
  let returnType = "::llvm::APFloat";
  let valueType = eir_FloatType;
}

def AtomAttr : DialectAttr<eir_Dialect, CPred<"$_self.isa<AtomAttr>()">, "atom attribute"> {
  let storageType = "::lumen::eir::AtomAttr";
  let returnType = "::llvm::APInt";
}

def BinaryAttr : DialectAttr<eir_Dialect, CPred<"$_self.isa<BinaryAttr>()">,
                                  "binary attribute"> {
  let storageType = "::lumen::eir::BinaryAttr";
  let returnType = "::llvm::StringRef";
}

def SeqAttr : DialectAttr<eir_Dialect, CPred<"$_self.isa<SeqAttr>()">,
                               "seq attribute"> {
  let storageType = "::lumen::eir::SeqAttr";
  let returnType = "::llvm::ArrayRef<Attribute>";
}

def eir_NilAttr : TypeAttrBase<"NilType", "nil type">;

//===----------------------------------------------------------------------===//
// Traits
//===----------------------------------------------------------------------===//

def eir_OpInterface : OpInterface<"eir_Op"> {
  let description = [{
    Common interface used for EIR ops
  }];

  let cppNamespace = "::lumen::eir";

  let methods = [];
}

def eir_RuntimeBuiltinOpInterface : OpInterface<"eir_RuntimeBuiltinOp"> {
  let description = "Common interface for operations which correspond to runtime builtins, e.g. __lumen_builtin_*";

  let cppNamespace = "::lumen::eir";

  let methods = [
    StaticInterfaceMethod<"get the builtin symbol name for this op",
      "StringRef", "builtinSymbol">
  ];
}

def eir_IntrinsicOpInterface : OpInterface<"eir_IntrinsicOp"> {
  let description = "Common interface for operations which correspond to compiler intrinsics, e.g. __lumen_*";

  let cppNamespace = "::lumen::eir";

  let methods = [
    StaticInterfaceMethod<"get the intrinsic symbol name for this op",
    "StringRef", "intrinsicSymbol">
  ];
}

def YieldPoint : NativeOpTrait<"YieldPoint">;

//===----------------------------------------------------------------------===//
// Base Operations
//===----------------------------------------------------------------------===//

// Base class for EIR dialect operations.
//
//This operation inherits from the base `Op` class in mlir/IR/OpBase.td, which provides:
//   * The parent dialect of the operation.
//   * The mnemonic for the operation, or the name without the dialect prefix.
//   * A list of traits for the operation.
class eir_Op<string mnemonic, list<OpTrait> traits = []> :
    Op<eir_Dialect, mnemonic, !listconcat(traits, [eir_OpInterface])> {

  // For each EIR op, the following static functions need to be defined
  // in Ops.cpp:
  //
  // * static M::ParseResult parse<op-c++-class-name>(M::OpAsmParser &parser,
  //                                                  M::OperationState &result)
  // * static void print(M::OpAsmPrinter &p, <op-c++-class-name> op)
  // * static M::LogicalResult verify(<op-c++-class-name> op)
  let parser = [{ return ::parse$cppClass(parser, result); }];
  let printer = [{ return ::print(p, *this); }];
  let verifier = [{ return ::verify(*this); }];
}

#endif
