module ministd.typecons.heap;

import ministd.algorithm : move;
import ministd.traits : isRefType;

@safe @nogc:

struct UniqueHeap(T)
{
    static if (isRefType!T)
        private alias TRef = T;
    else
        private alias TRef = T*;

    private TRef m_ref;

    @disable this();

    private pure nothrow
    this(scope TRef reference) scope
    out (; !empty)
    {
        m_ref = reference;
    }

    /** 
     * Copy constructor (moves reference)
     * `other` can be `empty`.
     */
    this(ref scope typeof(this) other) scope
    {
        m_ref = other.m_ref.move;
    }

    ~this() scope
    out (; empty)
    {
        if (!empty)
            reset;
    }

    static
    typeof(this) create(CtorArgs...)(CtorArgs ctorArgs) scope
    out (r; !r.empty)
        => typeof(this)(dalloc!T(ctorArgs));

    pure nothrow
    bool empty() const scope
        => m_ref is null;

    static if (isRefType!T)
    {
        pure nothrow
        inout(T) get() inout return
        in (!empty)
            => m_ref;
    }
    else
    {
        pure nothrow
        ref inout(T) get() inout return
        in (!empty)
            => *m_ref;
    }

    void reset() scope
    in (!empty)
    out (; empty)
    {
        dfree(m_ref.move);
    }
}

struct SharedHeap(T)
{
    private struct Container
    {
        UniqueHeap!T m_uniq;
        int m_refCount = 1;
    }

    private Container* m_container;

    @disable this();

    private pure nothrow
    this(scope Container* container) scope
    out (; !empty)
    {
        m_container = container;
    }

    /// Copy constructor
    pure nothrow
    this(ref return scope typeof(this) other) scope
    {
        m_container = other.m_container;
        m_container.m_refCount++;
    }

    ~this()
    out (; empty)
    {
        if (!empty)
            reset;
    }

    static
    typeof(this) create(CtorArgs...)(CtorArgs ctorArgs)
    out (r; !r.empty)
        => typeof(this)(dalloc!Container(UniqueHeap!T.create(ctorArgs)));

    pure nothrow
    bool empty() const scope
        => m_container is null || m_container.m_uniq.empty;

    pure nothrow
    ref inout(T) get() inout return
    in (!empty)
        => m_container.m_uniq.get;

    void reset() scope
    in (!empty)
    out (; empty)
    {
        m_container.m_refCount--;
        if (m_container.m_refCount == 0)
            dfree(m_container.move);
        else
            m_container = null;
    }
}

@("UniqueHeap: ints")
unittest
{
    UniqueHeap!int uniq = UniqueHeap!int.create(5);

    assert(!uniq.empty);
    assert(uniq.get == 5);

    uniq.reset;
    assert(uniq.empty);
}

@("UniqueHeap: structs")
unittest
{
    static int ctorCalled, dtorCalled;

    struct S
    {
        int m_a = 1;

    nothrow scope:

        this(in int a)
        {
            m_a = a;
            ctorCalled++;
        }

        this(in bool[3] a...)
        {
            m_a = 0;
            foreach (el; a)
                if (el)
                    m_a++;
            ctorCalled++;
        }

        this(ref scope typeof(this) other)
        {
            assert(false); // Never called
        }

        ~this()
        {
            dtorCalled++;
        }
    }

    {
        auto uniq = UniqueHeap!S.create;

        assert(!uniq.empty);
        assert(uniq.get.m_a == 1);
        assert(ctorCalled == 0);
        assert(dtorCalled == 0);

        uniq.reset;
        assert(uniq.empty);
        assert(ctorCalled == 0);
        assert(dtorCalled == 1);
    }
    {
        auto uniq = UniqueHeap!S.create(5);

        assert(!uniq.empty);
        assert(uniq.get.m_a == 5);
        assert(ctorCalled == 1);
        assert(dtorCalled == 1);
    }
    assert(ctorCalled == 1);
    assert(dtorCalled == 2);
    {
        auto uniq = UniqueHeap!S.create(true, false, true);

        assert(!uniq.empty);
        assert(uniq.get.m_a == 2);
        assert(ctorCalled == 2);
        assert(dtorCalled == 2);

        auto cpy = uniq; // Doesn't call S copy ctor
        assert(uniq.empty);
        assert(!cpy.empty);
        assert(cpy.get.m_a == 2);
        assert(ctorCalled == 2);
        assert(dtorCalled == 2);
    }
    assert(ctorCalled == 2);
    assert(dtorCalled == 3); // Only cpy calls S dtor
}

version (DRuntimeClassesAndTypeInfo) //
@("UniqueHeap: classes")
unittest
{
    static int ctorCalled, dtorCalled;

    class C
    {
        int m_a = 1;

    nothrow scope:

        this(in int a)
        {
            m_a = a;
            ctorCalled++;
        }

        this(in bool[3] a...)
        {
            m_a = 0;
            foreach (el; a)
                if (el)
                    m_a++;
            ctorCalled++;
        }

        this(ref scope typeof(this) other)
        {
            assert(false); // Never called
        }

        ~this()
        {
            dtorCalled++;
        }
    }

    // No default or 0-arg ctor
    assert(__traits(compiles, UniqueHeap!C.create));

    {
        auto uniq = UniqueHeap!C.create(5);

        assert(!uniq.empty);
        assert(uniq.get.m_a == 5);
        assert(ctorCalled == 1);
        assert(dtorCalled == 0);
    }
    assert(ctorCalled == 1);
    assert(dtorCalled == 1);
    {
        auto uniq = UniqueHeap!C.create(true, false, true);

        assert(!uniq.empty);
        assert(uniq.get.m_a == 2);
        assert(ctorCalled == 2);
        assert(dtorCalled == 1);

        auto cpy = uniq; // Doesn't call S copy ctor
        assert(uniq.empty);
        assert(!cpy.empty);
        assert(cpy.get.m_a == 2);
        assert(ctorCalled == 2);
        assert(dtorCalled == 1);
    }
    assert(ctorCalled == 2);
    assert(dtorCalled == 2); // Only cpy calls S dtor
}

@("SharedHeap: ints")
unittest
{
    SharedHeap!int sh = SharedHeap!int.create(5);

    assert(!sh.empty);
    assert(sh.m_container !is null);
    assert(sh.m_container.m_refCount == 1);
    assert(!sh.m_container.m_uniq.empty);
    sh.m_container.m_uniq.get;
    assert(sh.get == 5);

    auto cpy1 = sh;
    assert(sh.m_container.m_refCount == 2);
    assert(cpy1.m_container.m_refCount == 2);

    auto cpy2 = SharedHeap!int(cpy1);
    assert(sh.m_container.m_refCount == 3);
    assert(cpy1.m_container.m_refCount == 3);
    assert(cpy2.m_container.m_refCount == 3);

    cpy1.reset;
    assert(sh.m_container.m_refCount == 2);
    assert(cpy1.empty);
    assert(cpy2.m_container.m_refCount == 2);

    sh.reset;
    assert(sh.empty);
    assert(cpy2.m_container.m_refCount == 1);
    cpy2.reset;
    assert(cpy2.empty);
}
