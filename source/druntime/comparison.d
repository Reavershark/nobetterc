module druntime.comparison;

/**
 * Three-way compare for integrals: negative if `lhs < rhs`, positive if `lhs > rhs`, 0 otherwise.
 */
pragma(inline, true)
int cmp3(T)(const T lhs, const T rhs) if (__traits(isIntegral, T))
{
    static if (T.sizeof < int.sizeof) // Taking the difference will always fit in an int.
        return int(lhs) - int(rhs);
    else
        return (lhs > rhs) - (lhs < rhs);
}

/**
 * Three-way compare for real fp types. NaN is smaller than all valid numbers.
 * Code is small and fast, see https://godbolt.org/z/fzb877
 */
pragma(inline, true)
int cmp3(T)(const T d1, const T d2)
        if (is(T == float) || is(T == double) || is(T == real))
{
    if (d2 != d2)
        return d1 == d1; // 0 if both ar NaN, 1 if d1 is valid and d2 is NaN.
    // If d1 is NaN, both comparisons are false so we get -1, as needed.
    return (d1 > d2) - !(d1 >= d2);
}

@("cmp3 integers")
unittest
{
    assert(cmp3(short.max, short.min) > 0);
    assert(cmp3(42, 42) == 0);
    assert(cmp3(int.max, int.min) > 0);
}

@("cmp3 floats")
unittest
{
    double x, y;
    assert(cmp3(x, y) == 0);
    assert(cmp3(y, x) == 0);
    x = 42;
    assert(cmp3(x, y) > 0);
    assert(cmp3(y, x) < 0);
    y = 43;
    assert(cmp3(x, y) < 0);
    assert(cmp3(y, x) > 0);
    y = 42;
    assert(cmp3(x, y) == 0);
    assert(cmp3(y, x) == 0);
}
