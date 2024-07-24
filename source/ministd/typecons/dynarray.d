module ministd.typecons.dynarray;

import ministd.algorithm : max, move;
import ministd.traits : isRefType;
import ministd.typecons.heap_array : UniqueHeapArray;

@safe nothrow @nogc:

struct DynArray(T)
{
nothrow @nogc:
    UniqueHeapArray!T m_arr;
    size_t m_used;

scope:
    private
    this(bool disableFieldCtor)
    {
    }

    this(scope return ref typeof(this) other)
    {
        m_arr = other.m_arr;
        m_used = other.m_used;
        other.m_used = 0;
    }

    static
    typeof(this) create(in size_t length)
    {
        typeof(this) res;
        res.m_arr = typeof(m_arr).create(length);
        res.m_used = length;
        return res;
    }

    const pure
    {
        bool empty() => length == 0;
        size_t length() => m_used;
        size_t reserved() => empty ? 0 : m_arr.get.length;
    }

    pure
    inout(T[]) get() inout
    in (!empty)
        => m_arr.get[0 .. m_used];

    alias get this;

    void put(const ref T value)
    {
        reserve(1);
        m_arr.get[m_used++] = value;
    }

    void put(const ref T[] values)
    {
        reserve(values.length);
        m_arr.get[m_used .. m_used + values.length] = values[];
        m_used += values.length;
    }

    void reserve(in size_t extraSpaces)
    {
        size_t requiredSize = length + extraSpaces;
        if (reserved > requiredSize)
            return;

        // Allocate new array
        size_t newSize = max(requiredSize, nextNaturalSize);
        auto newArr = typeof(m_arr).create(newSize);

        // Copy used part of old array
        if (!empty)
            newArr.get[0 .. m_used] = m_arr.get[0 .. m_used];

        // Replace old array with new array
        // (does tmp = m_arr.moveEmplaceInit; m_arr.copyCtor(newArr); destroy(tmp))
        m_arr = newArr;
    }

    void increaseSize(in size_t length)
    {
        reserve(length);
        m_used += length;
    }

    private pure
    size_t nextNaturalSize() const
        => max(1, reserved * 2);
}

@("DynArray create")
unittest
{
    auto a = DynArray!char.create(123);

    assert(!a.empty);
    assert(a.length == 123);
    assert(a.reserved == 123); // Exactly the same

    a.increaseSize(7);
    assert(!a.empty);
    assert(a.length == 130);
    assert(a.reserved >= 130); // Not the same

    auto moved = a;
    assert(a.empty);
}

@("DynArray as OutputRange")
unittest
{
    import ministd.range.primitives : isOutputRange;

    DynArray!char a;

    static assert(isOutputRange!(typeof(a), char));
    static assert(isOutputRange!(typeof(a), char[]));

    assert(a.empty);
    assert(a.length == 0);
    assert(a.reserved == 0);

    a.put('d');
    assert(!a.empty);
    assert(a.length == 1);
    assert(a.reserved == 1);

    a.put('m');
    assert(!a.empty);
    assert(a.length == 2);
    assert(a.reserved == 2);

    a.put('a');
    assert(!a.empty);
    assert(a.length == 3);
    assert(a.reserved == 4);

    a.reserve(20);
    assert(!a.empty);
    assert(a.length == 3);
    assert(a.reserved == 23);

    a.put("n!");
    assert(!a.empty);
    assert(a.length == 5);
    assert(a.reserved == 23);

    a.reserve(1);
    assert(!a.empty);
    assert(a.length == 5);
    assert(a.reserved == 23);

    assert(a.get == "dman!");

    auto moved = a;
    assert(a.empty);
}
