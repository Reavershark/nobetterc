module ministd.heap;

import ministd.algorithm : move;
import ministd.traits : isRefType;

@safe @nogc:

struct UniqueHeap(T)
{
    static if (isRefType!T)
        alias TRef = T;
    else
        alias TRef = T*;

    private TRef m_ref;

    @disable this();

    private nothrow
    this(ref TRef ref_) // lvalue version
    out (; !empty)
    {
        m_ref = ref_.move;
    }

    static TRef tref;

    private pure nothrow
    this(TRef ref_) // rvalue version
    out (; !empty)
    {
        m_ref = ref_;
    }

    ~this()
    out (; empty)
    {
        if (!empty)
            reset;
    }

    @disable this(typeof(this));

    static
    typeof(this) create(CtorArgs...)(CtorArgs ctorArgs)
    out (r; !r.empty)
    {
        return typeof(this)(dalloc!T(ctorArgs));
    }

    pure nothrow
    bool empty() const => m_ref is null;

    pure nothrow
    inout(TRef) get() inout
    in (!empty)
    {
        return m_ref;
    }

    nothrow
    typeof(this) move()
    in (!empty)
    out (; empty)
    {
        return typeof(this)(m_ref.move);
    }

    void reset()
    in (!empty)
    out (; empty)
    {
        dfree(m_ref.move);
    }
}

struct SharedHeap(T)
{
    private alias TRef = UniqueHeap!T.TRef;

    private struct Container
    {
        UniqueHeap!T m_uniq;
        int m_refCount = 1;

        @disable this();

        nothrow
        this(ref UniqueHeap!T uniq)
        {
            m_uniq = uniq.move;
        }
    }

    private Container* m_container;

    @disable this();

    private pure nothrow
    this(ref return scope Container* container) // lvalue version
    out (; !empty)
    {
        m_container = container.move;
    }

    private pure nothrow
    this(return scope Container* container) // rvalue version
    out (; !empty)
    {
        m_container = container;
    }

    /// Copy constructor
    pure nothrow
    this(ref return scope typeof(this) other)
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
    {
        return typeof(this)(dalloc!Container(UniqueHeap!T.create(ctorArgs)));
    }

    pure nothrow
    bool empty() const => m_container is null || m_container.m_uniq.empty;

    pure nothrow
    inout(TRef) get() inout
    in (!empty)
    {
        return m_container.m_uniq.get;
    }

    nothrow
    typeof(this) move()
    in (!empty)
    out (; empty)
    {
        return typeof(this)(m_container.move);
    }

    void reset()
    in (!empty)
    out (; empty)
    {
        m_container.m_refCount--;
        if (m_container.m_refCount == 0)
            dfree(m_container.move);
        m_container = null;
    }
}

struct UniqueHeapArray(T)
{
    private T[] m_arr;

    @disable this();
    @disable this(typeof(this));

    private pure nothrow
    this(ref T[] arr)
    {
        m_arr = arr.move;
    }

    ~this()
    {
        if (!empty)
            reset;
    }

    static
    typeof(this) create(CtorArgs...)(size_t length, CtorArgs ctorArgs)
    {
        T[] arr = dallocArray!T(length, ctorArgs);
        return typeof(this)(arr);
    }

    pure nothrow
    bool empty() const => m_arr is [];

    pure nothrow
    inout(T[]) get() inout => m_arr;

    nothrow
    typeof(this) move()
    out (; empty)
    {
        T[] arr = m_arr.move;
        return typeof(this)(m_arr);
    }

    void reset()
    in (!empty)
    {
        dfree(m_arr);
        m_arr = [];
    }
}

@("UniqueHeap: ints")
unittest
{
    UniqueHeap!int uniq = UniqueHeap!int.create(5);

    assert(!uniq.empty);
    assert(*uniq.get == 5);

    uniq.reset;
    assert(uniq.empty);
}

@("SharedHeap: ints")
unittest
{
    SharedHeap!int shrd = SharedHeap!int.create(5);

    assert(!shrd.empty);
    assert(shrd.m_container !is null);
    assert(shrd.m_container.m_refCount == 1);
    assert(!shrd.m_container.m_uniq.empty);
    assert(shrd.m_container.m_uniq.get !is null);
    assert(*shrd.get == 5);

    SharedHeap!int cpy1 = shrd;
    assert(shrd.m_container.m_refCount == 2);
    assert(cpy1.m_container.m_refCount == 2);

    SharedHeap!int cpy2 = SharedHeap!int(cpy1);
    assert(shrd.m_container.m_refCount == 3);
    assert(cpy1.m_container.m_refCount == 3);
    assert(cpy2.m_container.m_refCount == 3);

    cpy1.reset;
    assert(shrd.m_container.m_refCount == 2);
    assert(cpy1.empty);
    assert(cpy2.m_container.m_refCount == 2);

    shrd.reset;
    assert(shrd.empty);
    assert(cpy2.m_container.m_refCount == 1);
    cpy2.reset;
    assert(cpy2.empty);
}

@("UniqueHeapArray: ints")
unittest
{
    UniqueHeapArray!int arr = UniqueHeapArray!int.create(5, 1);

    assert(!arr.empty);
    assert(arr.get.length == 5);
    foreach (ref int el; arr.get)
        assert(el == 1);

    arr.reset;
    assert(arr.empty);
    assert(arr.get is []);
}
