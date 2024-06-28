module druntime.slices.casting;

import ministd.format : f;

@safe nothrow @nogc:

/**
 * The compiler lowers expressions of `cast(TTo[])TFrom[]` to
 * this implementation. Note that this does not detect alignment problems.
 * 
 * Params:
 *     from = the array to reinterpret-cast
 * 
 * Returns:
 *     `from` reinterpreted as `TTo[]`
 */
@trusted
T[] __ArrayCast(S, T)(return scope S[] src)
{
    const srcSize = src.length * S.sizeof;
    const toLength = srcSize / T.sizeof;

    if ((srcSize % T.sizeof) != 0)
    {
        auto msg = f!"cannot cast %s[] with length %s and sizeof %s to %s[] with sizeof %s"(
            S.stringof, src.length, S.sizeof,
            T.stringof, T.sizeof,
        );
        assert(false, msg.get);
    }

    struct Slice
    {
        size_t length;
        void* ptr;
    }

    auto a = cast(Slice*)&src;
    a.length = toLength; // jam new length
    return *cast(T[]*) a;
}

@("slice __ArrayCast")
unittest
{
    byte[int.sizeof * 3] b = cast(byte) 0xab;
    int[] i;
    short[] s;

    i = __ArrayCast!(byte, int)(b);
    assert(i.length == 3);
    foreach (v; i)
        assert(v == cast(int) 0xabab_abab);

    s = __ArrayCast!(byte, short)(b);
    assert(s.length == 6);
    foreach (v; s)
        assert(v == cast(short) 0xabab);

    s = __ArrayCast!(int, short)(i);
    assert(s.length == 6);
    foreach (v; s)
        assert(v == cast(short) 0xabab);
}

@("slice __ArrayCast fail tests (commented out)")
unittest
{
    ubyte[3] a;

    // int[] b = __ArrayCast!(ubyte, int)(a[]);
}
