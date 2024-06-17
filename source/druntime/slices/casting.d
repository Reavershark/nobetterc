module druntime.slices.casting;

@safe @nogc:

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
pure @trusted
TTo[] __ArrayCast(TFrom, TTo)(return scope TFrom[] from)
{
    const fromSize = from.length * TFrom.sizeof;
    const toLength = fromSize / TTo.sizeof;

    if ((fromSize % TTo.sizeof) != 0)
    {
        // TODO: format error
        // onArrayCastError(TFrom.stringof, fromSize, from.length, TTo.stringof, TTo.sizeof);
        assert(false, "__ArrayCast error");
    }

    struct Slice
    {
        size_t length;
        void* ptr;
    }

    auto a = cast(Slice*)&from;
    a.length = toLength; // jam new length
    return *cast(TTo[]*) a;
}

@("slice __ArrayCast")
pure nothrow
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
