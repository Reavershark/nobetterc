module ministd.traits;

public import std.traits : ConstOf, hasElaborateDestructor, ImmutableOf,
    isAggregateType, isIntegral, isQualifierConvertible, isSomeChar, isSomeString,
    lvalueOf, rvalueOf, SharedConstOf, SharedOf, Unqual;

import ministd.meta : Alias, AliasSeq;

@safe @nogc pure nothrow:

/// Unittest helper
version (unittest) alias TypeQualifierList = AliasSeq!(Alias, ConstOf, SharedOf, SharedConstOf, ImmutableOf);

/// Unittest helper
version (unittest) struct SubTypeOf(T)
{
    T val;
    alias val this;
}

/// Detect whether type `T` is a static array.
enum bool isStaticArray(T) = __traits(isStaticArray, T);

/// Detect whether type `T` is a slice.
enum bool isSlice(T) = {
    static if (is(T U == enum))
        return isSlice!U;
    else
        return is(T == U[], U);
}();

/// Detect whether type `T` is an array (static or slice).
enum bool isArray(T) = isStaticArray!T || isSlice!T;

@("isStaticArray: basic")
unittest
{
    static assert(isStaticArray!(int[3]));
    static assert(isStaticArray!(const(int)[5]));
    static assert(isStaticArray!(const(int)[][5]));

    static assert(!isStaticArray!(const(int)[]));
    static assert(!isStaticArray!(immutable(int)[]));
    static assert(!isStaticArray!(const(int)[4][]));
    static assert(!isStaticArray!(int[]));
    static assert(!isStaticArray!(int[char]));
    static assert(!isStaticArray!(int[1][]));
    static assert(!isStaticArray!(int[int]));
    static assert(!isStaticArray!int);
}

@("isSlice: basic")
unittest
{
    static assert(isSlice!(int[]));
    static assert(isSlice!(string));
    static assert(isSlice!(long[3][]));

    static assert(!isSlice!(int[5]));
    static assert(!isSlice!(typeof(null)));
}

@("isArray: basic")
unittest
{
    static assert(isArray!(int[]));
    static assert(isArray!(int[5]));
    static assert(isArray!(string));

    static assert(!isArray!uint);
    static assert(!isArray!(uint[uint]));
    static assert(!isArray!(typeof(null)));
}

@("isStaticArray: in-depth")
unittest
{
    static foreach (T; AliasSeq!(int[51], int[][2],
            char[][int][11], immutable char[13u],
            const(real)[1], const(real)[1][1], void[0]))
    {
        static foreach (Q; TypeQualifierList)
        {
            static assert(isStaticArray!(Q!T));
            static assert(!isStaticArray!(SubTypeOf!(Q!T)));
        }
    }

    enum ESA : int[1]
    {
        a = [1],
        b = [2],
    }

    static assert(isStaticArray!ESA);
}

@("isSlice: in-depth")
unittest
{
    static foreach (T; AliasSeq!(int[], char[], string, long[3][], double[string][]))
    {
        static foreach (Q; TypeQualifierList)
        {
            static assert(isSlice!(Q!T));
            static assert(!isSlice!(SubTypeOf!(Q!T)));
        }
    }

    static assert(!isSlice!(int[5]));

    static struct AliasThis
    {
        int[] values;
        alias values this;
    }

    static assert(!isSlice!AliasThis);

    enum E : string
    {
        a = "a",
        b = "b",
    }

    static assert(isSlice!E);
}

@("isArray: in-depth")
unittest
{
    static foreach (T; AliasSeq!(int[], int[5], void[]))
    {
        static foreach (Q; TypeQualifierList)
        {
            static assert(isArray!(Q!T));
            static assert(!isArray!(SubTypeOf!(Q!T)));
        }
    }
}

/// Detect whether type `T` is a reference type.
enum bool isRefType(T) = is(T == class) || is(T == interface);
