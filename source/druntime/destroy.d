module druntime.destroy;

/**
 * Destroys the given object and optionally resets to initial state. It's used to
 * _destroy an object, calling its destructor or finalizer so it no longer
 * references any other objects. It does $(I not) initiate a GC cycle or free
 * any GC memory.
 * If `initialize` is supplied `false`, the object is considered invalid after
 * destruction, and should not be referenced.
 */
void destroy(bool initialize = true, T)(ref T obj) if (is(T == struct))
{
    import core.internal.destruction : destructRecurse;

    destructRecurse(obj);

    static if (initialize)
    {
        import core.internal.lifetime : emplaceInitializer;

        emplaceInitializer(obj); // emplace T.init
    }
}

@("destroy struct simple")
@safe unittest
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

@("destroy struct in-depth")
nothrow @safe @nogc unittest
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
            ~this() nothrow @safe @nogc
            {
                destroyed++;
            }
        }

        struct B
        {
            C c;
            string s = "B";
            ~this() nothrow @safe @nogc
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

private extern (C) void rt_finalize2(void* p, bool det = true, bool resetMemory = true) nothrow;

/// ditto
void destroy(bool initialize = true, T)(T obj) if (is(T == class))
{
    static if (__traits(getLinkage, T) == "C++")
    {
        static if (__traits(hasMember, T, "__xdtor"))
            obj.__xdtor();

        static if (initialize)
        {
            const initializer = __traits(initSymbol, T);
            (cast(void*) obj)[0 .. initializer.length] = initializer[];
        }
    }
    else
    {
        // Bypass overloaded opCast
        auto ptr = (() @trusted => *cast(void**)&obj)();
        rt_finalize2(ptr, true, initialize);
    }
}

/// ditto
void destroy(bool initialize = true, T)(T obj) if (is(T == interface))
{
    static assert(__traits(getLinkage, T) == "D", "Invalid call to destroy() on extern(" ~ __traits(getLinkage, T) ~ ") interface");

    destroy!initialize(cast(Object) obj);
}

/// Reference type demonstration
@system unittest
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

    C c = new C();
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

/// C++ classes work too
version (none) @system unittest
{
    extern (C++) class CPP
    {
        struct Agg
        {
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

    CPP cpp = new CPP();
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

/// Value type demonstration
version (none) @safe unittest
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

/// Nested struct type
version (none) @system unittest
{
    int dtorCount;
    struct A
    {
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

version (none) @system unittest
{
    extern (C++)
    static class C
    {
        void* ptr;
        this()
        {
        }
    }

    destroy!false(new C());
    destroy!true(new C());
}

version (none) @system unittest
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
        A a;
        alias a this;
        this()
        {
            a = new A;
        }

        static int dtorCount;
        ~this()
        {
            dtorCount++;
        }
    }

    auto b = new B;
    assert(A.dtorCount == 0);
    assert(B.dtorCount == 0);
    destroy(b);
    assert(A.dtorCount == 0);
    assert(B.dtorCount == 1);

    auto a = new A;
    destroy(a);
    assert(A.dtorCount == 1);
}

version (none) @system unittest
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

        auto a = new A, b = new A;
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

        auto a = new B, b = new B;
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
    // this test is invalid now that the default ctor is not run after clearing
    version (none)
    {
        class C
        {
            string s;
            this()
            {
                s = "C";
            }
        }

        auto a = new C;
        a.s = "asd";
        destroy(a);
        assert(a.s == "C");
    }
}

version (none) nothrow @safe @nogc unittest
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
            ~this() nothrow @safe @nogc
            {
                destroyed++;
            }
        }

        struct B
        {
            C c;
            string s = "B";
            ~this() nothrow @safe @nogc
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

version (none) nothrow unittest
{
    // Bugzilla 20049: Test to ensure proper behavior of `nothrow` destructors
    class C
    {
        static int dtorCount = 0;
        this() nothrow
        {
        }

        ~this() nothrow
        {
            dtorCount++;
        }
    }

    auto c = new C;
    destroy(c);
    assert(C.dtorCount == 1);
}

// https://issues.dlang.org/show_bug.cgi?id=22832
version (none) nothrow unittest
{
    static struct A
    {
    }

    static class B
    {
        A opCast(T : A)()
        {
            return A();
        }
    }

    destroy(B.init);
}

// make sure destroy!false skips re-initialization
version (none) unittest
{
    static struct S
    {
        int x;
    }

    static class C
    {
        int x;
    }

    static extern (C++) class Cpp
    {
        int x;
    }

    static void test(T)(T inst)
    {
        inst.x = 123;
        destroy!false(inst);
        assert(inst.x == 123, T.stringof);
    }

    test(S());
    test(new C());
    test(new Cpp());
}

/// ditto
void destroy(bool initialize = true, T)(ref T obj) if (__traits(isStaticArray, T))
{
    foreach_reverse (ref e; obj[])
        destroy!initialize(e);
}

version (none) @safe unittest
{
    int[2] a;
    a[0] = 1;
    a[1] = 2;
    destroy!false(a);
    assert(a == [1, 2]);
    destroy(a);
    assert(a == [0, 0]);
}

version (none) @safe unittest
{
    static struct vec2f
    {
        float[2] values;
        alias values this;
    }

    vec2f v;
    destroy!(true, vec2f)(v);
}

version (none) @system unittest
{
    // Bugzilla 15009
    static string op;
    static struct S
    {
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
version (none) @system unittest
{
    static struct S
    {
        static dtorCount = 0;
        ~this()
        {
            ++dtorCount;
        }
    }

    static interface I
    {
        ref S[3] getArray();
        alias getArray this;
    }

    static class C : I
    {
        static dtorCount = 0;
        ~this()
        {
            ++dtorCount;
        }

        S[3] a;
        alias a this;

        ref S[3] getArray()
        {
            return a;
        }
    }

    C c = new C();
    destroy(c);
    assert(S.dtorCount == 3);
    assert(C.dtorCount == 1);

    I i = new C();
    destroy(i);
    assert(S.dtorCount == 6);
    assert(C.dtorCount == 2);
}

/// ditto
void destroy(bool initialize = true, T)(ref T obj)
        if (!is(T == struct) && !is(T == interface) && !is(T == class) && !__traits(
            isStaticArray, T))
{
    static if (initialize)
        obj = T.init;
}

version (none) @safe unittest
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
        assert(a != a); // isnan
    }
}

version (none) @safe unittest
{
    // Bugzilla 14746
    static struct HasDtor
    {
        ~this()
        {
            assert(0);
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
