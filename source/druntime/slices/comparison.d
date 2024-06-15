module druntime.slices.comparison;

import druntime.libc_funcs : memcmp;

import core.internal.string : dstrcmp;
import core.internal.traits : Unqual;

@safe @nogc:

/**
 * Compares 2 slices.
 * Every comparison operator for 2 slices is implemented using this template.
 */
@trusted pure nothrow
int __cmp(T)(in T[] lhs, in T[] rhs) //
if (__traits(isScalar, T))
{
    // Compute U as the implementation type for T
    static if (is(T == ubyte) || is(T == void) || is(T == bool))
        alias U = char;
    else static if (is(T == wchar))
        alias U = ushort;
    else static if (is(T == dchar))
        alias U = uint;
    else static if (is(T == ifloat))
        alias U = float;
    else static if (is(T == idouble))
        alias U = double;
    else static if (is(T == ireal))
        alias U = real;
    else
        alias U = T;

    static if (is(U == char))
    {
        return dstrcmp(cast(char[]) lhs, cast(char[]) rhs);
    }
    else static if (!is(U == T))
    {
        // Reuse another implementation
        return __cmp(cast(U[]) lhs, cast(U[]) rhs);
    }
    else
    {
        version (BigEndian)
            static if (__traits(isUnsigned, T) ? !is(T == __vector) :  is(T : P*, P))
            {
                if (!__ctfe)
                {
                    int c = memcmp(lhs.ptr, rhs.ptr,
                        (lhs.length <= rhs.length ? lhs.length : rhs.length) * T.sizeof);
                    if (c)
                        return c;
                    static if (size_t.sizeof <= uint.sizeof && T.sizeof >= 2)
                        return cast(int) lhs.length - cast(int) rhs.length;
                    else
                        return int(lhs.length > rhs.length) - int(lhs.length < rhs.length);
                }
            }

        immutable len = lhs.length <= rhs.length ? lhs.length : rhs.length;
        foreach (const u; 0 .. len)
        {
            auto a = lhs.ptr[u], b = rhs.ptr[u];
            static if (is(T : creal))
            {
                // Use rt.cmath2._Ccmp instead ?
                // Also: if NaN is present, numbers will appear equal.
                auto r = (a.re > b.re) - (a.re < b.re);
                if (!r)
                    r = (a.im > b.im) - (a.im < b.im);
            }
            else
            {
                // This pattern for three-way comparison is better than conditional operators
                // See e.g. https://godbolt.org/z/3j4vh1
                const r = (a > b) - (a < b);
            }
            if (r)
                return r;
        }
        return (lhs.length > rhs.length) - (lhs.length < rhs.length);
    }
}

/// ditto
pure nothrow
int __cmp(T1, T2)(T1[] s1, T2[] s2) //
if (!__traits(isScalar, T1) && !__traits(isScalar, T2))
{
    alias U1 = Unqual!T1;
    alias U2 = Unqual!T2;

    static if (is(U1 == void) && is(U2 == void))
        static @trusted ref inout(ubyte) at(inout(void)[] r, size_t i)
        {
            return (cast(inout(ubyte)*) r.ptr)[i];
        }
    else
        static @trusted ref R at(R)(R[] r, size_t i)
        {
            return r.ptr[i];
        }

    // All unsigned byte-wide types = > dstrcmp
    immutable len = s1.length <= s2.length ? s1.length : s2.length;

    foreach (const u; 0 .. len)
    {
        static if (__traits(compiles, __cmp(at(s1, u), at(s2, u))))
        {
            auto c = __cmp(at(s1, u), at(s2, u));
            if (c != 0)
                return c;
        }
        else static if (__traits(compiles, at(s1, u).opCmp(at(s2, u))))
        {
            auto c = at(s1, u).opCmp(at(s2, u));
            if (c != 0)
                return c;
        }
        else static if (__traits(compiles, at(s1, u) < at(s2, u)))
        {
            if (int result = (at(s1, u) > at(s2, u)) - (at(s1, u) < at(s2, u)))
                return result;
        }
        else
        {
            // TODO: fix this legacy bad behavior, see
            // https://issues.dlang.org/show_bug.cgi?id=17244
            static assert(is(U1 == U2), "Internal error.");

            auto c = (() @trusted => memcmp(&at(s1, u), &at(s2, u), U1.sizeof))();
            if (c != 0)
                return c;
        }
    }
    return (s1.length > s2.length) - (s1.length < s2.length);
}

@("slice __cmp")
unittest
{
    int[3] a, b;
    assert(a[] >= b[]);
    assert(a[] <= b[]);
    assert(!(a[] > b[]));
    assert(!(a[] < b[]));
    a[1] = 1;
    assert(a[] >= b[]);
    assert(a[] > b[]);
    assert(!(a[] <= b[]));
    assert(!(a[] < b[]));
}
