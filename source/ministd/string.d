module ministd.string;

import ministd.traits : isSomeString;
import ministd.typecons : UniqueHeapArray;

@safe nothrow @nogc:

enum string stringzOf(string S) = (S ~ '\0');
enum immutable(char)* stringzPtrOf(string S) = (S ~ '\0').ptr;

pure
void setStringz(C1, C2)(C1[] target, in C2[] source) //
if (C1.sizeof == 1 && C2.sizeof == 1)
in (target.length >= source.length + 1)
{
    target[0 .. source.length] = cast(const C1[]) source[];
    target[source.length] = 0;
}

UniqueHeapArray!char toStringz(S)(S s) //
if (isSomeString!S)
out (ret; ret.get.length == s.length + 1)
{
    auto sz = typeof(return).create(s.length + 1);
    sz.get.setStringz(s);
    return sz;
}

pure
bool startsWith(T)(in T[] a, in T[] b)
{
    return a.length >= b.length && a[0 .. b.length] == b;
}

struct TermColor
{
const nothrow:
    @disable this();

static:
    private
    string wrap(in string s, in string colors)
    {
        if (__ctfe)
            return "\x1b[" ~ colors ~ "m" ~ s ~ "\x1b[0m";
        else
            assert (false, "TermColor only works in ctfe");
    }

    // dfmt off
    string bold      (in string s) => wrap(s, "1");
    string underline (in string s) => wrap(s, "4");
    string black     (in string s) => wrap(s, "30");
    string red       (in string s) => wrap(s, "31");
    string green     (in string s) => wrap(s, "32");
    string yellow    (in string s) => wrap(s, "33");
    string blue      (in string s) => wrap(s, "34");
    // dfmt on
}