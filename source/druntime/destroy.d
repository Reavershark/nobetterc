module druntime.destroy;

import core.internal.lifetime : emplaceInitializer;
import core.internal.traits : hasElaborateDestructor;
import core.lifetime : emplace;

@safe @nogc:

/**
 * Destroys the given object and optionally resets to initial state. It's used to
 * _destroy an object, calling its destructor or finalizer so it no longer
 * references any other objects. It does $(I not) initiate a GC cycle or free
 * any GC memory.
 * If `initialize` is supplied `false`, the object is considered invalid after
 * destruction, and should not be referenced.
 */
// dfmt off
pure nothrow
void destroy(bool initialize = true, T)(ref T obj) // Simple value version
if (!is(T == struct) && !is(T == interface) && !is(T == class) && !__traits(isStaticArray, T))
{
    static if (initialize)
        obj = T.init;
}
// dfmt on

/// ditto
void destroy(bool initialize = true, T)(ref T obj) // Struct version
if (is(T == struct))
{
    destroyStruct(obj);

    static if (initialize)
    {
        emplaceInitializer(obj); // emplace T.init
    }
}

/// ditto
void destroy(bool initialize = true, T)(ref T obj) // Static array version
if (__traits(isStaticArray, T))
{
    foreach_reverse (ref e; obj[])
        destroy!initialize(e);
}

/// ditto
version (DRuntimeClassesAndTypeInfo) //
@trusted
void destroy(bool initialize = true, T)(T obj) // C++ class version
if (is(T == class) && __traits(getLinkage, T) == "C++")
{
    static if (__traits(hasMember, T, "__xdtor"))
    {
        obj.__xdtor;
    }

    static if (initialize)
    {
        const initializer = __traits(initSymbol, T);
        (cast(void*) obj)[0 .. initializer.length] = initializer[];
    }
}

/// ditto
version (DRuntimeClassesAndTypeInfo) //
void destroy(bool initialize = true, T)(T obj) // D class version
if (is(T == class) && __traits(getLinkage, T) == "D")
{
    // Bypass overloaded opCast
    auto ptr = (() @trusted => *cast(void**)&obj)();
    destroyClass(ptr, true, initialize);
}

/// ditto
version (DRuntimeClassesAndTypeInfo) //
void destroy(bool initialize = true, T)(T obj) // Interface version
if (is(T == interface))
{
    static assert(
        __traits(getLinkage, T) == "D",
        "Invalid call to destroy() on extern(" ~ __traits(getLinkage, T) ~ ") interface"
    );

    destroy!initialize(cast(Object) obj);
}

// ClassDtor type
version (DRuntimeClassesAndTypeInfo)
{
    alias ClassDtor = @system @nogc void function(Object);
}

private @trusted
void destroyStruct(S)(ref S s) // Single struct version
if (is(S == struct))
{
    static if (__traits(hasMember, S, "__xdtor") &&
         // Bugzilla 14746: Check that it's the exact member of S.
        __traits(isSame, S, __traits(parent, s.__xdtor)))
    {
        s.__xdtor;
    }
}

private
void destroyStruct(S, size_t n)(ref S[n] arr) // Static array version
{
    static if (hasElaborateDestructor!S)
    {
        foreach_reverse (ref elem; arr)
            destroyStruct(elem);
    }
}

// Note: not a template
version (DRuntimeClassesAndTypeInfo) //
private @trusted
void destroyClass(void* ptr, bool deterministic = true, bool resetMemory = true)
{
    if (ptr is null)
        return;

    void** typeInfoDoublePtr = cast(void**) ptr;
    void** monitorDoublePtr = typeInfoDoublePtr + 1;

    if (*typeInfoDoublePtr is null)
        return;

    TypeInfo_Class* typeInfoPtr = cast(TypeInfo_Class*)*typeInfoDoublePtr;

    void destroyClassImpl()
    {
        if (deterministic)
        {
            TypeInfo_Class typeInfo = *typeInfoPtr;
            do
            {
                if (typeInfo.destructor)
                {
                    auto dtor = cast(ClassDtor) typeInfo.destructor;
                    dtor(cast(Object) ptr);
                }
            }
            while ((typeInfo = typeInfo.base) !is null);
        }

        // TODO
        //if (*monitorDoublePtr)
        //    _d_monitordelete(cast(Object) ptr, deterministic);

        if (resetMemory)
        {
            auto w = typeInfoPtr.initializer;
            ptr[0 .. w.length] = w[];
        }
    }

    version (DRuntimeExceptions)
    {
        try
            destroyClassImpl;
        catch (Exception e)
        {
            // TODO: use format (add "exception in dtor" and typeinfo.toString)
            assert(false, e.toString);
        }
        finally
            *typeInfoDoublePtr = null; // zero vptr even if `resetMemory` is false
    }
    else
    {
        destroyClassImpl;
        *typeInfoDoublePtr = null; // zero vptr even if `resetMemory` is false
    }
}

@("destroy: simple value types")
nothrow
unittest
{
    int i;
    assert(i == 0); // `i`'s initial state is `0`
    i = 1;
    assert(i == 1); // `i` changed to `1`
    destroy!false(i);
    assert(i == 1); // `i` was not initialized
    destroy(i);
    assert(i == 0); // `i` is back to its initial state `0`
}

@("destroy: scalars")
nothrow
unittest
{
    {
        int a = 42;
        destroy!false(a);
        assert(a == 42);
        destroy(a);
        assert(a == 0);
    }
    {
        float a = 42;
        destroy!false(a);
        assert(a == 42);
        destroy(a);
        assert(a is float.nan);
    }
}

@("destroy: static array")
nothrow
unittest
{
    int[2] a;
    a[0] = 1;
    a[1] = 2;

    destroy!false(a);
    assert(a == [1, 2]);

    destroy(a);
    assert(a == [0, 0]);
}

@("destroy: structs simple")
nothrow
unittest
{
    struct A
    {
        string s = "A";
    }

    A a = {s: "B"};
    assert(a.s == "B");
    a.destroy;
    assert(a.s == "A");
}

@("destroy: structs in-depth checks")
nothrow
unittest
{
    {
        struct A
        {
            string s = "A";
        }

        A a;
        a.s = "asd";
        destroy!false(a);
        assert(a.s == "asd");
        destroy(a);
        assert(a.s == "A");
    }
    {
        static int destroyed = 0;
        struct C
        {
            string s = "C";

            ~this()
            {
                destroyed++;
            }
        }

        struct B
        {
            C c;
            string s = "B";

            ~this()
            {
                destroyed++;
            }
        }

        B a;
        a.s = "asd";
        a.c.s = "jkl";

        destroy!false(a);
        assert(destroyed == 2);
        assert(a.s == "asd");
        assert(a.c.s == "jkl");

        destroy(a);
        assert(destroyed == 4);
        assert(a.s == "B");
        assert(a.c.s == "C");
    }
}

@("destroy: static structs")
nothrow
unittest
{
    static int i = 0;

    static struct S
    {
        ~this()
        {
            i = 42;
        }
    }

    S s;

    destroyStruct(s);
    assert(i == 42);
}

@("destroy: structs with context")
@system
unittest
{
    static int dtorCount;

    struct A
    {
    @nogc: // need to reapply in @system
        int i;

        ~this()
        {
            dtorCount++; // capture local variable
        }
    }

    A a = A(5);

    destroy!false(a);
    assert(dtorCount == 1);
    assert(a.i == 5);

    destroy(a);
    assert(dtorCount == 2);
    assert(a.i == 0);

    // the context pointer is now null
    // restore it so the dtor can run
    import core.lifetime : emplace;

    emplace(&a, A(0));
    // dtor also called here
}

// https://issues.dlang.org/show_bug.cgi?id=14746
@("destroy: structs with alias this")
nothrow
unittest
{
    static struct HasDtor
    {
        ~this()
        {
            assert(false);
        }
    }

    static struct Owner
    {
        HasDtor* ptr;
        alias ptr this;
    }

    Owner o;
    assert(o.ptr is null);
    destroy(o); // must not reach in HasDtor.__dtor()
}

@("destroy: structs with static array alias this")
version (none) // TODO: need _adEq2
nothrow
unittest
{
    static struct Vec2f
    {
        float[2] values;
        alias values this;
    }

    Vec2f v;
    destroy!(true, Vec2f)(v);
}

@("destroy: classes")
version (DRuntimeClassesAndTypeInfo) //
unittest
{
    class C
    {
        struct Agg
        {
            static int dtorCount;

            int x = 10;

            ~this()
            {
                dtorCount++;
            }
        }

        static int dtorCount;

        string s = "S";
        Agg a;

        ~this()
        {
            dtorCount++;
        }
    }

    C c = dalloc!C;
    scope (exit)
        dfree(c);

    assert(c.dtorCount == 0); // destructor not yet called
    assert(c.s == "S"); // initial state `c.s` is `"S"`
    assert(c.a.dtorCount == 0); // destructor not yet called
    assert(c.a.x == 10); // initial state `c.a.x` is `10`
    c.s = "T";
    c.a.x = 30;
    assert(c.s == "T"); // `c.s` is `"T"`

    destroy(c);
    assert(c.dtorCount == 1); // `c`'s destructor was called
    assert(c.s == "S"); // `c.s` is back to its inital state, `"S"`
    assert(c.a.dtorCount == 1); // `c.a`'s destructor was called
    assert(c.a.x == 10); // `c.a.x` is back to its inital state, `10`
}

@("destroy: C++ classes")
version (DRuntimeClassesAndTypeInfo) //
@system
unittest
{
    extern (C++) class CPP
    {
    @nogc: // need to reapply in @system
        struct Agg
        {
        @nogc: // need to reapply in @system
            __gshared int dtorCount;

            int x = 10;

            ~this()
            {
                dtorCount++;
            }
        }

        __gshared int dtorCount;

        string s = "S";
        Agg a;

        ~this()
        {
            dtorCount++;
        }
    }

    CPP cpp = dalloc!CPP;
    scope (exit)
        dfree(cpp);

    assert(cpp.dtorCount == 0); // destructor not yet called
    assert(cpp.s == "S"); // initial state `cpp.s` is `"S"`
    assert(cpp.a.dtorCount == 0); // destructor not yet called
    assert(cpp.a.x == 10); // initial state `cpp.a.x` is `10`
    cpp.s = "T";
    cpp.a.x = 30;
    assert(cpp.s == "T"); // `cpp.s` is `"T"`

    destroy!false(cpp); // destroy without initialization
    assert(cpp.dtorCount == 1); // `cpp`'s destructor was called
    assert(cpp.s == "T"); // `cpp.s` is not initialized
    assert(cpp.a.dtorCount == 1); // `cpp.a`'s destructor was called
    assert(cpp.a.x == 30); // `cpp.a.x` is not initialized

    destroy(cpp);
    assert(cpp.dtorCount == 2); // `cpp`'s destructor was called again
    assert(cpp.s == "S"); // `cpp.s` is back to its inital state, `"S"`
    assert(cpp.a.dtorCount == 2); // `cpp.a`'s destructor was called again
    assert(cpp.a.x == 10); // `cpp.a.x` is back to its inital state, `10`
}

@("destroy: static C++ classes")
version (DRuntimeClassesAndTypeInfo) //
nothrow
unittest
{
    extern (C++)
    static class C
    {
        void* ptr;

        this()
        {
        }

        ~this()
        {
        }
    }

    C c1 = dalloc!C;
    C c2 = dalloc!C;

    scope (exit)
    {
        dfree(c1);
        dfree(c2);
    }

    destroy!false(c1);
    destroy!true(c2);
}

@("destroy: classes with alias this")
version (DRuntimeClassesAndTypeInfo) //
unittest
{
    // class with an `alias this`
    class A
    {
        static int dtorCount;

        ~this()
        {
            dtorCount++;
        }
    }

    class B
    {
        static int dtorCount;

        A a;
        alias a this;

        this()
        {
            a = dalloc!A;
        }

        ~this()
        {
            dtorCount++;
        }
    }

    B b = dalloc!B;
    A a = b.a;

    scope (exit)
    {
        dfree(a);
        dfree(b);
    }

    assert(A.dtorCount == 0);
    assert(B.dtorCount == 0);

    destroy(b);
    assert(A.dtorCount == 0);
    assert(B.dtorCount == 1);

    destroy(a);
    assert(A.dtorCount == 1);
}

// https://issues.dlang.org/show_bug.cgi?id=20049
@("destroy: proper behaviour of nothrow dtors")
version (DRuntimeClassesAndTypeInfo) //
unittest
{
    class C
    {
    nothrow:
        static int dtorCount = 0;

        this()
        {
        }

        ~this()
        {
            dtorCount++;
        }
    }

    C c = dalloc!C;
    scope (exit)
        dfree(c);

    destroy(c);
    assert(C.dtorCount == 1);
}

// https://issues.dlang.org/show_bug.cgi?id=22832
@("destroy: classes with opCast")
version (DRuntimeClassesAndTypeInfo) //
unittest
{
    static struct A
    {
    }

    static class B
    {
        A opCast(T : A)() const
        {
            return A();
        }
    }

    destroy(B.init);
}

@("destroy: interfaces")
version (none) // TODO: need _d_interface_cast
// version (DRuntimeClassesAndTypeInfo) //
unittest
{
    interface I
    {
    }

    {
        class A : I
        {
            string s = "A";

            this()
            {
            }
        }

        A a = dalloc!A;
        A b = dalloc!A;

        scope (exit)
        {
            dfree(a);
            dfree(b);
        }

        a.s = b.s = "asd";
        destroy(a);
        assert(a.s == "A");

        I i = b;
        destroy(i);
        assert(b.s == "A");
    }
    {
        static bool destroyed = false;

        class B : I
        {
            string s = "B";

            this()
            {
            }

            ~this()
            {
                destroyed = true;
            }
        }

        B a = dalloc!B;
        B b = dalloc!B;

        scope (exit)
        {
            dfree(a);
            dfree(b);
        }

        a.s = b.s = "asd";

        destroy(a);
        assert(destroyed);
        assert(a.s == "B");

        destroyed = false;
        I i = b;
        destroy(i);
        assert(destroyed);
        assert(b.s == "B");
    }

    // The default ctor should not be run after clearing
    {
        class C
        {
            string s;

            this()
            {
                s = "C";
            }
        }

        C a = dalloc!C;
        scope (exit)
            destroy(a);

        a.s = "asd";

        destroy(a);
        assert(a.s == "asd");
    }
}

@("destroy: make sure destroy!false skips re-initialization")
unittest
{
    static void test(T)(T inst)
    {
        inst.x = 123;
        destroy!false(inst);
        assert(inst.x == 123, T.stringof);
    }

    static struct S
    {
        int x;
    }

    test(S());

    version (DRuntimeClassesAndTypeInfo)
    {
        static class C
        {
            int x;
        }

        static extern (C++) class Cpp
        {
            int x;
        }

        C c = dalloc!C;
        Cpp cpp = dalloc!Cpp;

        scope (exit)
        {
            dfree(c);
            dfree(cpp);
        }

        test(c);
        test(cpp);
    }
}

version (none) // TODO: need __ArrayDtor
@system
unittest
{
    // Bugzilla 15009
    static string op;

    static struct S
    {
    @nogc: // need to reapply in @system
        int x;

        this(int x)
        {
            op ~= "C" ~ cast(char)('0' + x);
            this.x = x;
        }

        this(this)
        {
            op ~= "P" ~ cast(char)('0' + x);
        }

        ~this()
        {
            op ~= "D" ~ cast(char)('0' + x);
        }
    }

    {
        S[2] a1 = [S(1), S(2)];
        op = "";
    }
    assert(op == "D2D1"); // built-in scope destruction

    {
        S[2] a1 = [S(1), S(2)];
        op = "";
        destroy(a1);
        assert(op == "D2D1"); // consistent with built-in behavior
    }

    {
        S[2][2] a2 = [[S(1), S(2)], [S(3), S(4)]];
        op = "";
    }
    assert(op == "D4D3D2D1");

    {
        S[2][2] a2 = [[S(1), S(2)], [S(3), S(4)]];
        op = "";
        destroy(a2);
        assert(op == "D4D3D2D1", op);
    }
}

// https://issues.dlang.org/show_bug.cgi?id=19218
version (none) // TODO: need __ArrayDtor
// version (DRuntimeClassesAndTypeInfo) //
@system
unittest
{
    static struct S
    {
    @nogc: // need to reapply in @system
        static dtorCount = 0;

        ~this()
        {
            ++dtorCount;
        }
    }

    static interface I
    {
    @nogc: // need to reapply in @system
        ref S[3] getArray();
        ref S[3] getArray();
        alias getArray this;
    }

    static class C : I
    {
    @nogc: // need to reapply in @system
        ref S[3] getArray();
        static dtorCount = 0;

        S[3] a;

        ~this()
        {
            ++dtorCount;
        }

        ref S[3] getArray()
        {
            return a;
        }

        alias a this;
    }

    C c = dalloc!C;
    I i = dalloc!C;

    scope (exit)
    {
        dfree(c);
        dfree(i);
    }

    destroy(c);
    assert(S.dtorCount == 3);
    assert(C.dtorCount == 1);

    destroy(i);
    assert(S.dtorCount == 6);
    assert(C.dtorCount == 2);
}
