module ministd.range.primitives;

import ministd.traits : isQualifierConvertible, lvalueOf, Unqual;

@safe pure nothrow @nogc:

/**
 * The element type of `R`. `R` does not have to be a range. The
 * element type is determined as the type yielded by `r.front` for an
 * object `r` of type `R`. For example, `ElementType!(T[])` is
 * `T` if `T[]` isn't a narrow string; if it is, the element type is
 * `dchar`. If `R` doesn't have `front`, `ElementType!R` is
 * `void`.
 */
template ElementType(R)
{
    static if (is(typeof(R.init.front.init) T))
        alias ElementType = T;
    else
        alias ElementType = void;
}

enum bool isInputRange(R) =
    is(typeof(R.init) == R)
    && is(typeof((R r) { return r.empty; }(R.init)) == bool)
    && (is(typeof((return ref R r) => r.front)) || is(typeof(ref(return ref R r) => r.front)))
    && !is(typeof((R r) { return r.front; }(R.init)) == void)
    && is(typeof((R r) => r.popFront));

enum bool isInputRange(R, E) = isInputRange!R && isQualifierConvertible!(ElementType!R, E); // @suppress(dscanner.suspicious.label_var_same_name)

enum bool isOutputRange(R, E) = is(typeof(lvalueOf!R.put(lvalueOf!E)));

template equalUnqualElementTypes(T1, T2)
{
    alias U1 = Unqual!T1;
    alias U2 = Unqual!T2;

    alias E1 = ElementType!U1;
    alias E2 = ElementType!U2;

    static if (is(E1 == void) || is(E2 == void))
    {
        enum bool equalUnqualElementTypes = false;
    }
    else
    {
        alias UE1 = Unqual!E1;
        alias UE2 = Unqual!E2;

        enum bool equalUnqualElementTypes = is(UE1 == UE2);
    }
}

@("equalUnqualElementTypes")
unittest
{
    static assert(equalUnqualElementTypes!(string, char[]));
    static assert(equalUnqualElementTypes!(const(string), char[]));
}

bool empty(T)(auto ref scope T a) //
if (is(typeof(a.length) : size_t))
{
    return !a.length;
}

// TODO: Breaks for utf char[]
ref inout(T) front(T)(return scope inout(T)[] a) //
if (!is(T[] == void[]))
{
    assert(a.length, "Attempting to fetch the front of an empty slice of " ~ T.stringof);
    return a[0];
}

// TODO: Breaks for utf char[]
void popFront(T)(scope ref inout(T)[] a) if (!is(T[] == void[]))
{
    assert(a.length, "Attempting to popFront() past the end of an slice of " ~ T.stringof);
    a = a[1 .. $];
}
