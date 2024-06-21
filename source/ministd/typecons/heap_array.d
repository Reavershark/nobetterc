module ministd.typecons.heap_array;

import ministd.algorithm : move;
import ministd.traits : isRefType;

@safe @nogc:

struct UniqueHeapArray(T) //
if (!isRefType!T)
{
    private T[] m_slice;

    @disable this();

    private pure nothrow
    this(scope T[] slice) scope
    out (; !empty)
    {
        m_slice = slice;
    }

    /** 
     * Copy constructor (moves reference)
     * `other` can be `empty`.
     */
    this(ref scope typeof(this) other) scope
    {
        m_slice = other.m_slice.move;
    }

    ~this() scope
    {
        if (!empty)
            reset;
    }

    static
    typeof(this) create(CtorArgs...)(in size_t length, CtorArgs ctorArgs)
        => typeof(this)(dallocArray!T(length, ctorArgs));

    pure nothrow
    bool empty() const scope
        => m_slice is [];

    pure nothrow
    inout(T[]) get() inout return
        => m_slice;

    void reset() scope
    in (!empty)
    {
        dfree(m_slice.move);
    }
}

struct SharedHeapArray(T) //
if (!isRefType!T)
{
    private struct Container
    {
        UniqueHeapArray!T m_uniq;
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

    ~this() scope
    out (; empty)
    {
        if (!empty)
            reset;
    }

    static
    typeof(this) create(CtorArgs...)(in size_t length, CtorArgs ctorArgs)
    out (r; !r.empty)
        => typeof(this)(dalloc!Container(UniqueHeapArray!T.create(length, ctorArgs)));

    pure nothrow
    bool empty() const scope
        => m_container is null || m_container.m_uniq.empty;

    pure nothrow
    ref inout(T[]) get() inout return
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
