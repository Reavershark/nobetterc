module ministd.conv.to;

import ministd.conv.internal.to_string : integerToCharArray;
import ministd.meta : staticAmong;
import ministd.range.primitives : equalUnqualElementTypes;
import ministd.traits : isSlice;
import ministd.typecons : UniqueHeapArray;

@safe @nogc:

auto to(T, S)(in S src)
{
    static if (is(T : S)) // Implicitly convertible or equal
        return src;
    else static if (isSlice!T && is(T == char[]))
        return toCharArray(src);
    else
        static assert(false, S.stringof ~ " to " ~ T.stringof ~ " is not implemented");
}

private
UniqueHeapArray!char toCharArray(S)(in S src) // To char[]
{
    static if (staticAmong!(S, ubyte, ushort, uint, ulong))
        return integerToCharArray!ulong(src);
    else static if (staticAmong!(S, byte, short, int, long))
        return integerToCharArray!long(src);
    else
        static assert(false, S.stringof ~ " to char[] is not implemented");
}

@("to!(char[], uint)")
unittest
{
    assert(0u.to!(char[]) == "0");
    assert(1u.to!(char[]) == "1");
    assert(9u.to!(char[]) == "9");
    assert(10u.to!(char[]) == "10");
    assert(1234u.to!(char[]) == "1234");
}

@("to!(char[], int)")
unittest
{
    assert(0.to!(char[]) == "0");
    assert(1.to!(char[]) == "1");
    assert(9.to!(char[]) == "9");
    assert(10.to!(char[]) == "10");
    assert(1234.to!(char[]) == "1234");

    assert((-0).to!(char[]) == "0");
    assert((-1).to!(char[]) == "-1");
    assert((-9).to!(char[]) == "-9");
    assert((-10).to!(char[]) == "-10");
    assert((-1234).to!(char[]) == "-1234");
}
