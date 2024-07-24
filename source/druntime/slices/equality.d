module druntime.slices.equality;

@safe nothrow @nogc pure:

/**
 * Returns whether 2 slices are equal.
 * This is used by the compiler to implement `slice1 == slice2` in most cases.
 */
bool __equals(T1, T2)(in T1[] slice1, in T2[] slice2)
{
    // Compare length
    if (slice1.length != slice2.length)
        return false;

    // Compare elements
    foreach (const i; 0 .. slice1.length)
        if (slice1.at(i) != slice2.at(i))
            return false;

    return true;
}

/**
 * Returns a reference to an array element, eliding bounds check and
 * casting void to ubyte.
 */
pragma(inline, true)
private ref T at(T)(T[] slice, size_t i) @trusted if (!IsOpaqueStruct!T) // exclude opaque structs due to https://issues.dlang.org/show_bug.cgi?id=20959
{
    static if (is(immutable T == immutable void))
        return (cast(ubyte*) slice.ptr)[i];
    else
        return slice.ptr[i];
}

private enum bool IsOpaqueStruct(T) = is(T == struct) && !is(typeof(T.sizeof));

@("slice __equals")
unittest
{
    int[3] a, b;
    assert(a[] == b[]);
    a[1] = 1;
    assert(a[] != b[]);
    b[1] = 1;
    assert(a[] == b[]);
}
