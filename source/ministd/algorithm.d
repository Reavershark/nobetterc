module ministd.algorithm;

import ministd.traits : isRefType;

@safe @nogc:

pure nothrow
uint among(Value, Values...)(Value value, Values values) //
if (Values.length != 0)
{
    foreach (uint i, ref v; values)
        if (value == v)
            return i + 1;
    return 0;
}

pure nothrow
T* move(T)(ref T* ptr) // lvalue pointer version
{
    scope (exit)
        ptr = null;
    return ptr;
}

pure nothrow
T* move(T)(T* ptr) // rvalue pointer version
{
    return ptr;
}

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
{
    return instanceRef;
}

pure nothrow
T[] move(T)(ref T[] slice) // lvalue slice version
{
    scope (exit)
        slice = [];
    return slice;
}

pure nothrow
T[] move(T)(T[] slice) // rvalue slice version
{
    return slice;
}

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
