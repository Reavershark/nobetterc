module ministd.string;

@safe @nogc:

enum string stringzOf(string S) = (S ~ '\0');
enum immutable(char)* stringzPtrOf(string S) = (S ~ '\0').ptr;

pure nothrow
void setStringz(C1, C2)(C1[] target, in C2[] source) //
if (C1.sizeof == 1 && C2.sizeof == 1)
in (target.length >= source.length + 1)
{
    target[0 .. source.length] = cast(const C1[]) source[];
    target[source.length] = 0;
}

nothrow
UniqueHeapArray!char toStringz(S)(S s) //
if (isSomeString!S)
out (ret; ret.get.length == s.length + 1)
{
    auto sz = typeof(return).create(s.length + 1);
    sz.get.setStringz(s);
    return sz.move;
}

pure
bool startsWith(T)(in T[] a, in T[] b)
{
    return a.length >= b.length && a[0 .. b.length] == b;
}

enum TermColor : string
{
    // dfmt off
    reset     = "\x1b[0m",
    bold      = "\x1b[1m",
    underline = "\x1b[4m",
    black     = "\x1b[30m",
    red       = "\x1b[31m",
    green     = "\x1b[32m",
    yellow    = "\x1b[33m",
    blue      = "\x1b[34m",
    // dfmt on
}

// TODO: no ~ operation in runtime, find another way
/+
struct TermColor
{
const pure nothrow:
    @disable this();

static:

    private
    string wrap(in string s, in string colors)
    in (__ctfe, "TermColor only works in ctfe")
    {
        return "\x1b[" ~ colors ~ "m" ~ s ~ "\x1b[0m";
    }

    // dfmt off
    string black (in string s) => wrap(s, "30");
    string red   (in string s) => wrap(s, "31");
    string green (in string s) => wrap(s, "32");
    string yellow(in string s) => wrap(s, "33");
    string blue  (in string s) => wrap(s, "34");
    // dfmt on
}
+/
