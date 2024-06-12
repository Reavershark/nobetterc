module druntime.heap;

import druntime.libc_funcs : malloc, free;

import core.lifetime : emplace;

@safe nothrow @nogc:

@trusted
void[] mallocWrapper(size_t size)
{
    void* ptr = malloc(size);
    if (ptr is null)
        assert(false, "malloc failed");
    return ptr[0 .. size];
}

@trusted
T* dalloc(T)(T initValue = T.init) if (!is(T == struct) && !is(T == class))
{
    void[] allocatedHeapMem = mallocWrapper(T.sizeof);
    T* ptr = cast(T*) allocatedHeapMem.ptr;
    *ptr = initValue;
    return ptr;
}

@trusted
T* dalloc(T, CtorArgs...)(CtorArgs ctorArgs) if (is(T == struct))
{
    void[] allocatedHeapMem = mallocWrapper(T.sizeof);
    allocatedHeapMem.emplace!T(ctorArgs);
    return cast(T*) allocatedHeapMem.ptr;
}

version (DRuntimeClassesAndTypeInfo) @trusted
T dalloc(T, CtorArgs...)(CtorArgs ctorArgs) if (is(T == class))
{
    // initializer.ptr can be null, which means it's zero-initialized
    // initializer.length is always correct
    const(void)[] initializer = __traits(initSymbol, T);
    void[] allocatedHeapMem = mallocWrapper(initializer.length);
    allocatedHeapMem[] = initializer is null ? 0 : initializer[];
    allocatedHeapMem.emplace!T(ctorArgs);
    return cast(T) allocatedHeapMem.ptr;
}

/+
@trusted
T[] dallocArray(T)(size_t length, ubyte initValue = 0) if (!is(T == class))
{
    ubyte* ptr = cast(ubyte*) malloc(T.sizeof * length);
    assert(ptr, "dallocArray: malloc failed");
    ubyte[] slice = ptr[0 .. T.sizeof * length];
    foreach (ref b; slice)
        b = initValue;
    return cast(T[]) slice;
}
+/

void dfree(T)(T* instance) if (!is(T == struct) && !is(T == class))
in (instance !is null)
{
    free(instance);
}

void dfree(T)(T* instance) if (is(T == struct))
in (instance !is null)
{
    destroy(*instance);
    free(instance);
}

version (DRuntimeClassesAndTypeInfo) @trusted
void dfree(T)(T instance) if (is(T == class))
in (instance !is null)
{
    destroy(instance);
    free(cast(void*) instance);
}

@("dalloc primitives")
unittest
{
    int* a = dalloc!int;
    scope (exit)
        dfree(a);

    int* b = dalloc!int(-1);
    scope (exit)
        dfree(b);

    assert(*a == 0);
    assert(*b == -1);
}

@("dalloc struct zero-init")
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

@("dalloc struct field init")
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

@("dalloc struct with ctor")
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
