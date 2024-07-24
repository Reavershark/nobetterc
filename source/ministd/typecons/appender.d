module ministd.typecons.appender;

import ministd.algorithm : max, move;
import ministd.traits : isRefType;
import ministd.typecons.dynarray : DynArray;

@safe nothrow @nogc:

struct Appender(T)
{
nothrow @nogc:
    private DynArray!T m_dynArr;

scope:
    private
    this(bool disableFieldCtor)
    {
    }

    this(scope return ref typeof(this) other)
    {
        m_dynArr = other.m_dynArr;
    }

    ref DynArray!T getArray()
        => m_dynArr;

    alias getArray this;

    DynArray!T moveArray() return scope
    out (; m_dynArr.empty)
        => m_dynArr;
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
