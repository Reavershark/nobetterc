module ministd.format.parse;

@safe pure nothrow @nogc:

enum FormatSegment[] parseFormatString(string fmt) = {
    FormatSegment[] segments;

    string remaining = fmt;
    while (remaining.length)
        segments ~= parseNextSegment(remaining);

    uint nextArgIndex;
    foreach (ref seg; segments)
        if (seg.isFormatSpec)
            seg.argIndex = nextArgIndex++;

    return segments;
}();

struct FormatSegment
{
    string str;
    bool isFormatSpec;

    uint argIndex;
}

private
FormatSegment parseNextSegment(ref string remaining)
in (remaining.length)
{
    if (remaining[0] == '%') // Parse one format specifier
    {
        assert(remaining.length >= 2);

        if (remaining[1] == '%') // %% becomes single % as text
        {
            FormatSegment seg;
            seg.str = remaining[0 .. 1]; // Return the first %
            remaining = remaining[2 .. $]; // Skip the second %
            return seg;
        }
        else
        {
            assert(remaining[1] == 's');

            FormatSegment seg;
            seg.str = remaining[0 .. 2];
            seg.isFormatSpec = true;
            remaining = remaining[2 .. $];
            return seg;
        }
    }
    else // Read normal text until a format specifier or the end
    {
        foreach (i; 0 .. remaining.length)
            if (remaining[i] == '%')
            {
                FormatSegment seg;
                seg.str = remaining[0 .. i];
                remaining = remaining[i .. $];
                return seg;
            }

        FormatSegment seg;
        seg.str = remaining[0 .. $];
        remaining = remaining[$ .. $];
        return seg;
    }
}

@("parseFormatString: simple")
unittest
{
    enum segs = parseFormatString!"a";
    static assert(segs.length == 1);
    static assert(segs[0].str == "a");
    static assert(!segs[0].isFormatSpec);
}

@("parseFormatString: %s")
unittest
{
    enum segs = parseFormatString!"line %s, col %s";

    static assert(segs.length == 4);

    static assert(segs[0].str == "line ");
    static assert(!segs[0].isFormatSpec);

    static assert(segs[1].str == "%s");
    static assert(segs[1].isFormatSpec);

    static assert(!segs[2].isFormatSpec);
    static assert(segs[2].str == ", col ");

    static assert(segs[3].str == "%s");
    static assert(segs[3].isFormatSpec);
}

@("parseFormatString: %%")
unittest
{
    enum segs = parseFormatString!"%%%s";

    static assert(segs.length == 2);

    static assert(segs[0].str == "%");
    static assert(!segs[0].isFormatSpec);

    static assert(segs[1].str == "%s");
    static assert(segs[1].isFormatSpec);
}
