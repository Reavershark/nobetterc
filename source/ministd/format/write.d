module ministd.format.write;

import ministd.format.parse : FormatSegment, parseFormatString;
import ministd.range.primitives : isOutputRange;

@safe nothrow @nogc:

void formattedWrite(string fmt, OutputRange, Args...)(scope ref OutputRange output, Args args) //
if (fmt.length)
{
    enum FormatSegment[] segs = parseFormatString!fmt;
    static foreach(seg; segs)
    {
        static if (!seg.isFormatSpec)
            output.put(seg.str);
        else
        {
            output.put("TODO");
        }
    }
}

unittest
{
    import ministd.typecons : Appender;

    Appender!char appender;
    formattedWrite!"aze"(appender);
    assert(appender.get == "aze");
}

unittest
{
    import ministd.typecons : Appender;

    Appender!char appender;
    formattedWrite!"test %s"(appender);
    assert(appender.get == "test TODO");
}
