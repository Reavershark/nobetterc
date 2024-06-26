module ministd.meta;

public import std.meta : Alias, AliasSeq;

@safe @nogc pure nothrow:

enum bool staticAmong(needle, haystack...) = {
    foreach (el; haystack)
        if (is(needle == el))
            return true;
    return false;
}();

@("staticAmong")
unittest
{
    static assert(staticAmong!(int, ushort, int, string));
    static assert(!staticAmong!(int, ushort, uint, string));
}
