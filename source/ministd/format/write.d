module ministd.format.write;

import ministd.conv : to;
import ministd.format.parse : FormatSegment, parseFormatString;
import ministd.range.primitives : isOutputRange;

@safe nothrow @nogc:

void formattedWrite(string fmt, OutputRange, Args...)(scope ref OutputRange output, Args args) //
if (fmt.length && isOutputRange!(OutputRange, char) && isOutputRange!(OutputRange, char[]))
{
    enum FormatSegment[] segs = parseFormatString!fmt;
    static foreach(seg; segs)
    {
        static if (!seg.isFormatSpec)
            output.put(seg.str);
        else
        {
            alias Arg = Args[seg.argIndex];
            auto arg = args[seg.argIndex];
            output.put(arg.to!string);
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
    appender.formattedWrite!"test %s"(1u);
    assert(appender.get == "test 1");
}
