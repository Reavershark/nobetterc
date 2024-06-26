module ministd.conv.to;

import ministd.conv.internal.to_string : integerToCharArray;
import ministd.traits : amongTypes, Unqual;
import ministd.typecons : UniqueHeapArray;

S to(T, S)(in S src) // Types are the same
if (is(T == S))
    => src;

UniqueHeapArray!char to(T, S)(in S src) // To char[]
if (is(T == char[]))
{
    static if (amongTypes!(S, ubyte, ushort, uint, ulong))
        return integerToCharArray!ulong(src);
    else static if (amongTypes!(S, byte, short, int, long))
        return integerToCharArray!long(src);
    else
        static assert(false, S.stringof ~ " to char[] is not implemented");
}

T to(T, S)(in S src) // Castable
if (is(typeof(cast(T) src)))
    => cast(T) src;

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
