module ministd.algorithm;

import ministd.range.primitives : empty, front, isInputRange, popFront;
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

bool startsWith(Range, Element)(Range r, Element e) // range and element version
if (isInputRange!Range && is(typeof(r.front == e) == bool))
{
    if (r.empty)
        return false;

    return r.front == e;
}

bool startsWith(Range)(scope Range r1, scope Range r2) // 2 ranges version
if (isInputRange!Range2 && is(typeof(r1.front == r2.front) : bool))
{
    if (r2.empty)
        return true;
    if (r1.empty)
        return false;

    static if (hasLength!Range)
    {
        if (r1.length < r2.length)
            return false;
        // Can assume r1.length >= r2.length from here on

        static if (isSlice!Range)
        {
            return r1[0 .. r2.length] == r2;
        }
        else static if (isRandomAccessRange!Range)
        {
            foreach (i; 0 .. r2.length)
                if (r1[i] != r2[i])
                    return false;
            return true;
        }
        else
        {
            while (r1.front == r2.front)
            {
                r2.popFront;
                if (r2.empty)
                    return true;
                r1.popFront;
            }
            return false;
        }
    }
    else
    {
        while (r1.front == r2.front)
        {
            r2.popFront;
            if (r2.empty)
                return true;

            r1.popFront;
            if (r1.empty)
                return false;
        }
        return false;
    }
}

auto max(T)(in T[] args...)
in (args.length >= 1)
{
    size_t maxIndex;
    foreach (i, arg; args[1 .. $])
        if (arg > args[maxIndex])
            maxIndex = i + 1;
    return args[maxIndex];
}

@("max")
unittest
{
    assert(max(1, 3, 2) == 3);
}