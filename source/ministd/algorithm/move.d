module ministd.algorithm.move;

import ministd.traits : isRefType;

@safe @nogc:

/** 
 * Moves the argument lvalue, setting to null
 * The argument must be a pointer, class instance reference or slice.
 * 
 * Returns: 
 */
pure nothrow
T* move(T)(ref T* ptr) // lvalue pointer version
{
    scope (exit)
        ptr = null;
    return ptr;
}

// dfmt off
pure nothrow
T* move(T)(T* ptr) // rvalue pointer version
    => ptr;
// dfmt on

pure nothrow
T move(T)(ref T instanceRef) // lvalue reference version
if (isRefType!T)
{
    scope (exit)
        instanceRef = null;
    return instanceRef;
}

pure nothrow
T move(T)(T instanceRef) // rvalue reference version
if (isRefType!T)
    => instanceRef;

pure nothrow
T[] move(T)(ref T[] slice) // lvalue slice version
{
    scope (exit)
        slice = [];
    return slice;
}

// dfmt off
pure nothrow
T[] move(T)(T[] slice) // rvalue slice version
    => slice;
// dfmt on

@("move: pointers")
nothrow
unittest
{
    int* ptr = dalloc!int;
    assert(ptr !is null);
    dfree(ptr.move); // lvalue move
    assert(ptr is null);
    ptr.init.move; // rvalue move
}

@("move: slices")
nothrow
unittest
{
    int[] arr = dallocArray!int(2);
    assert(arr !is []);
    dfree(arr.move); // lvalue move
    assert(arr is []);
    arr.init.move; // rvalue move
}

version (DRuntimeClassesAndTypeInfo) //
@("move: class instance refs")
unittest
{
    Object objectRef = dalloc!Object;
    assert(objectRef !is null);
    dfree(objectRef.move);
    assert(objectRef is null);
}
