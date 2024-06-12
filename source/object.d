module object;

@safe @nogc:

version (LDC) {}
else static assert(false, "Only ldc is supported");

///////////////////////////////////
// Always-available type aliases //
///////////////////////////////////

alias size_t = typeof(int.sizeof);
alias ptrdiff_t = typeof(cast(void*) 0 - cast(void*) 0);

alias noreturn = typeof(*null);

alias string = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];

//////////////////////////////////////////////
// Always-available functions and templates //
//////////////////////////////////////////////

public import druntime.hashing : hashOf;
public import druntime.heap : dalloc, dfree;
public import druntime.slices.comparison : __cmp;
public import druntime.slices.equality : __equals;
public import druntime.destroy : destroy;

public import druntime.libc_funcs : printf;

/// Writes `s` to `stderr` during CTFE (does nothing at runtime).

pure nothrow
void __ctfeWrite(scope const(char)[] s) {}

template imported(string moduleName)
{
    mixin("import imported = " ~ moduleName ~ ";");
}

/////////////
// Classes //
/////////////

version (DRuntimeClassesAndTypeInfo)
{
    public import druntime.classes.comparison : opEquals;

    import druntime.classes.object_class : ObjectClassBody;
    
    // dfmt off
    /// All other base classes implicitly inherit from this class
    class Object { mixin ObjectClassBody; }
    // dfmt on

    /**
     * Information about an interface.
     * When an object is accessed via an interface, an Interface* appears as the
     * first entry in its vtbl.
     */
    struct Interface
    {
        /// Class info returned by `typeid` for this interface (not for containing class)
        TypeInfo_Class classinfo;
        void*[] vtbl;
        size_t offset; /// offset to Interface 'this' from Object 'this'
    }
}

//////////////////////////////////
// The runtime type info system //
//////////////////////////////////

version (DRuntimeClassesAndTypeInfo)
{
    // dfmt off
    import druntime.typeinfo.base : TypeInfoClassBody, OffsetTypeInfoStructBody;
    import druntime.typeinfo.type_attributes : TypeInfo_ConstClassBody, TypeInfo_InoutClassBody,
        TypeInfo_InvariantClassBody, TypeInfo_SharedClassBody;
    import druntime.typeinfo.classes_interfaces : TypeInfo_ClassClassBody, TypeInfo_InterfaceClassBody;
    import druntime.typeinfo.structs : TypeInfo_StructClassBody;
    import druntime.typeinfo.pointers : TypeInfo_PointerClassBody;
    import druntime.typeinfo.slices : TypeInfo_ArrayClassBody, TypeInfo_PrimitiveArrayClassBody,
        TypeInfo_VoidArrayClassBody;
    import druntime.typeinfo.static_arrays : TypeInfo_StaticArrayClassBody;
    
    // These are the symbols that are required too be available everywhere.
    // In some cases these symbols are also required to be defined here. That's why
    // we use body mixins from modules under `druntime.typeinfo` instead of symbol imports.
    
    class TypeInfo { mixin TypeInfoClassBody; }
    struct OffsetTypeInfo { mixin OffsetTypeInfoStructBody; }
    
    class TypeInfo_Const : TypeInfo { mixin TypeInfo_ConstClassBody; }
    class TypeInfo_Invariant : TypeInfo_Const { mixin TypeInfo_InvariantClassBody; }
    class TypeInfo_Inout : TypeInfo_Const { mixin TypeInfo_InoutClassBody; }
    class TypeInfo_Shared : TypeInfo_Const { mixin TypeInfo_SharedClassBody; }
    
    class TypeInfo_Class : TypeInfo { mixin TypeInfo_ClassClassBody; }
    class TypeInfo_Interface : TypeInfo { mixin TypeInfo_InterfaceClassBody; }
    
    class TypeInfo_Struct : TypeInfo { mixin TypeInfo_StructClassBody; }
    
    class TypeInfo_Pointer : TypeInfo { mixin TypeInfo_PointerClassBody; }
    
    class TypeInfo_Array : TypeInfo { mixin TypeInfo_ArrayClassBody; }
    
    class TypeInfo_h : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!ubyte; }
    class TypeInfo_g : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!byte; }
    class TypeInfo_b : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!bool; }
    class TypeInfo_a : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!char; }
    class TypeInfo_v : TypeInfo_h { mixin TypeInfo_VoidArrayClassBody; }
    
    class TypeInfo_t : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!ushort; }
    class TypeInfo_s : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!short; }
    class TypeInfo_u : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!wchar; }
    
    class TypeInfo_k : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!uint; }
    class TypeInfo_i : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!int; }
    class TypeInfo_w : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!dchar; }
    
    class TypeInfo_m : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!ulong; }
    class TypeInfo_l : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!long; }
    
    class TypeInfo_StaticArray : TypeInfo { mixin TypeInfo_StaticArrayClassBody; }
    
    static if (is(ucent)) class TypeInfo_zk : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!ucent; }
    static if (is(cent)) class TypeInfo_zi : TypeInfo_Array { mixin TypeInfo_PrimitiveArrayClassBody!cent; }
    // dfmt on

    bool _xopCmp(in void*, in void*) => assert(false, "TypeInfo.compare is not implemented");
    bool _xopEquals(in void*, in void*) => assert(false, "TypeInfo.equals is not implemented");
}

////////////////
// Exceptions //
////////////////

version (DRuntimeExceptions)
{
    public import druntime.exceptions.functions : _d_delThrowable;

    import druntime.exceptions.base_classes : Throwable_ClassBody, Exception_ClassBody, Error_ClassBody;
    
    // dfmt off
    class Throwable { mixin Throwable_ClassBody; }
    class Exception : Throwable { mixin Exception_ClassBody; }
    class Error : Throwable { mixin Error_ClassBody; }
    // dfmt on
}
