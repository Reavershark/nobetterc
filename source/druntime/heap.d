module druntime.heap;

import druntime.libc_funcs : malloc, free;

import core.lifetime : emplace;

import std.traits : isAggregateType;

@safe @nogc:

@trusted nothrow
void[] mallocWrapper(size_t size)
{
    void* ptr = malloc(size);
    if (ptr is null)
        assert(false, "malloc failed");
    return ptr[0 .. size];
}

@trusted nothrow
T* dalloc(T)(T initValue = T.init) // POD version
if (T.sizeof && !isAggregateType!T)
{
    void[] allocatedHeapMem = mallocWrapper(T.sizeof);
    T* ptr = cast(T*) allocatedHeapMem.ptr;
    *ptr = initValue;
    return ptr;
}

@trusted
T* dalloc(T, CtorArgs...)(CtorArgs ctorArgs) // Struct/union version
if (T.sizeof && (is(T == struct) || is(T == union)))
{
    void[] allocatedHeapMem = mallocWrapper(T.sizeof);
    allocatedHeapMem.emplace!T(ctorArgs);
    return cast(T*) allocatedHeapMem.ptr;
}

version (DRuntimeClassesAndTypeInfo) @trusted
T dalloc(T, CtorArgs...)(CtorArgs ctorArgs) // Non-abstract class version
if (is(T == class))
{
    // Classes are reference types, so T.sizeof is just size_t.sizeof
    // Use initializer.length to get the real size
    const(void)[] initializer = __traits(initSymbol, T);
    void[] allocatedHeapMem = mallocWrapper(initializer.length);
    allocatedHeapMem.emplace!T(ctorArgs);
    return cast(T) allocatedHeapMem.ptr;
}

@trusted
T[] dallocArray(T)(size_t length, T initValue = T.init) // POD version
if (T.sizeof && !isAggregateType!T)
in (length > 0)
{
    void[] allocatedHeapMem = mallocWrapper(T.sizeof * length);
    T[] slice = cast(T[]) allocatedHeapMem;
    foreach (ref T el; slice)
        el = initValue;
    return slice;
}

@trusted
T[] dallocArray(T, CtorArgs...)(size_t length, CtorArgs ctorArgs) // Struct/union version
if (T.sizeof && (is(T == struct) || is(T == union)))
in (length > 0)
{
    void[] allocatedHeapMem = mallocWrapper(T.sizeof * length);
    T[] slice = cast(T[]) allocatedHeapMem;
    foreach (ref T el; slice)
        (&el).emplace!T(ctorArgs);
    return slice;
}

nothrow
void dfree(T)(T* instance) // Non-aggregate version
if (T.sizeof && !isAggregateType!T)
in (instance !is null)
{
    free(instance);
}

void dfree(T)(T* instance) // Struct/union version
if (T.sizeof && (is(T == struct) || is(T == union)))
in (instance !is null)
{
    destroy(*instance);
    free(instance);
}

version (DRuntimeClassesAndTypeInfo) //
@trusted
void dfree(T)(T instance) // Class version
if (is(T == class))
in (instance !is null)
{
    destroy(instance);
    free(cast(void*) instance);
}

version (DRuntimeClassesAndTypeInfo) //
@trusted
void dfree(T)(T instance) // Interface version
if (is(T == interface))
in (instance !is null)
in (cast(Object) instance)
{
    // Object cast needed to get the right address to free.
    // Cast needs to happen before destroy
    Object instanceAsObject = cast(Object) instance;
    destroy(instance);
    free(cast(void*) instanceAsObject);
}

@trusted
void dfree(T)(T[] arr) // Array version
if (T.sizeof && !is(T == class) && !is(T == interface))
in (arr !is null)
{
    destroy(arr);
    free(arr.ptr);
}

@("dalloc: scalars")
unittest
{
    int* a = dalloc!int;
    int* b = dalloc!int(-1);
    double* c = dalloc!double;

    scope (exit)
    {
        dfree(a);
        dfree(b);
        dfree(c);
    }

    assert(*a == 0);
    assert(*b == -1);
    assert(*c is double.nan);
}

@("dalloc: pointers")
unittest
{
    struct S;
    static int i; // Static so we can pass &i to non-scope parameter of dalloc

    void** a = dalloc!(void*);
    int** b = dalloc!(int*)(&i);
    S** c = dalloc!(S*);

    scope (exit)
    {
        dfree(a);
        dfree(b);
        dfree(c);
    }

    assert(*a == null);
    assert(*b == &i);
    assert(*c == null);
}

@("dalloc: slice values")
@trusted
unittest
{
    static int[5] a;

    int[]* b = dalloc!(int[]);
    scope (exit)
        dfree(b);

    assert(b.ptr == null);
    assert(b.length == 0);
    assert(*b is []);
    *b = a[];
    assert(b.ptr == a[].ptr);
    assert(b.length == a.length);
    assert(*b is a[]);
}

@("dalloc: static int arrays")
@trusted
unittest
{
    int[4]* a = dalloc!(int[4]);
    scope (exit)
        dfree(a);

    assert(*a == [0, 0, 0, 0]);
    (*a)[3] = -1;
    assert(*a == [0, 0, 0, -1]);
}

@("dalloc: static char arrays")
@trusted
unittest
{
    char[4] s = "abcd";

    char[4]* a = dalloc!(char[4])(s);
    scope (exit)
        dfree(a);

    assert(*a == "abcd");
    assert((*a)[].ptr != s.ptr);
}

@("dalloc: delegate ptrs")
@trusted
unittest
{
    static int a = 5;
    int f() => a;

    auto dgPtr = dalloc!(int delegate() @safe nothrow @nogc);
    scope (exit)
        dfree(dgPtr);

    assert(*dgPtr is null);
    *dgPtr = &f;
    assert(*dgPtr is &f);
    assert((*dgPtr)() == 5);
    a = 0;
    assert((*dgPtr)() == 0);
}

@("dalloc: enums")
@trusted
unittest
{
    enum A
    {
        zero,
        one
    }

    A* a = dalloc!A;
    scope (exit)
        dfree(a);

    assert(*a == A.zero);
    *a = A.one;
    assert(*a == A.one);
}

@("dalloc: structs zero-init")
unittest
{
    struct S
    {
        int a;
    }

    S* s = dalloc!S;
    scope (exit)
        dfree(s);

    assert(s.a == 0);
}

@("dalloc: structs field init")
unittest
{
    struct S
    {
        int a = -1;
    }

    S* s = dalloc!S;
    scope (exit)
        dfree(s);

    assert(s.a == -1);
}

@("dalloc: structs with ctor")
unittest
{
    struct S
    {
        int a = -1;
        int b = -2;

        this(int x)
        {
            b = x;
        }
    }

    S* s = dalloc!S(5);
    scope (exit)
        dfree(s);

    assert(s.a == -1);
    assert(s.b == 5);
}

@("dalloc: classes")
version (DRuntimeClassesAndTypeInfo) //
unittest
{
    class C
    {
        int a = -1;
        int b = -2;

        this()
        {
            a = -3;
        }
    }

    C c = dalloc!C;
    scope (exit)
        dfree(c);

    assert(c.a == -3);
    assert(c.b == -2);
}

@("dallocArray: non-aggregates")
nothrow
unittest
{
    int[] arr = dallocArray!int(3, -1);
    scope(exit)
        dfree(arr);

    assert(arr.length == 3);
    foreach (ref el; arr)
        assert(el == -1);
}

@("dallocArray: structs")
nothrow
unittest
{
    static int dtorCalled = 0;

    struct S
    {
        int a = 1;
        int b = 2;

        this(int x)
        {
            assert(a == 1);
            assert(b == 2);
            b = x;
        }

        ~this()
        {
            dtorCalled++;
        }
    }

    S[] arr = dallocArray!S(2, 3);

    assert(arr.length == 2);
    foreach (ref S s; arr)
    {
        assert(s.a == 1);
        assert(s.b == 3);
    }

    assert(dtorCalled == 0);
    dfree(arr);
    assert(dtorCalled == 2);
}

@("dfree: dynamic casted classes")
version (DRuntimeClassesAndTypeInfo) //
@trusted
unittest
{
    interface I
    {
    @safe @nogc:
        int foo();
    }

    class C : I
    {
    @nogc:
        int m_a;

        this(int a)
        {
            m_a = a;
        }

        int foo() => m_a;
    }

    C c = dalloc!C(1);
    C co = dalloc!C(2);
    C ci = dalloc!C(3);
    Object o = co;
    I i = ci;

    scope (exit)
    {
        dfree(c);
        dfree(o);
        dfree(i);
    }

    assert(c.foo == 1);

    assert(cast(C) o);
    assert((cast(C) o).foo == 2);
    assert(typeid(c) is typeid(o));

    assert(i.foo == 3);
    assert(cast(C) i);
    assert((cast(C) i).foo == 3);
}
