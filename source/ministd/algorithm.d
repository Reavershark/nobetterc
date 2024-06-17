module ministd.algorithm;

import druntime.heap;

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
T* move(T)(ref T* ptr)
{
    scope (exit)
        ptr = null;
    return ptr;
}

pure nothrow
T move(T)(ref T instanceRef) if (is(T == class) || is(T == interface))
{
    scope (exit)
        instanceRef = null;
    return instanceRef;
}

pure nothrow
T[] move(T)(ref T[] slice)
{
    scope (exit)
        slice = [];
    return slice;
}

@("move: pointers")
nothrow
unittest
{
    int* ptr = dalloc!int;
    assert(ptr !is null);
    dfree(ptr.move);
    assert(ptr is null);
}

@("move: slices")
nothrow
unittest
{
    int[] arr = dallocArray!int(2);
    assert(arr !is []);
    dfree(arr.move);
    assert(arr is []);
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
