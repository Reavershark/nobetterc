module ministd.typecons.appender;

import ministd.algorithm : max, move;
import ministd.traits : isRefType;
import ministd.typecons.heap_array : UniqueHeapArray;

@safe nothrow @nogc:

struct Appender(T)
{
    private UniqueHeapArray!T m_arr;
    private size_t m_used;

scope:

    private
    this(bool disableFieldCtor)
    {
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

    UniqueHeapArray!T moveArray() return scope
    out(; empty)
    out(; m_arr.empty)
    {
        m_used = 0;
        return m_arr;
    }

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
        // (tmp = m_arr.moveEmplaceInit; m_arr.copyCtor(newArr); destroy(tmp))
        m_arr = newArr;
    }

    private pure
    size_t nextNaturalSize() const
        => max(1, reserved * 2);
}

@("Appender")
unittest
{
    Appender!char a;
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

    auto moved = a.moveArray;
    assert(a.empty);
}
