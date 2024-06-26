module ministd.format.write;

import ministd.conv : to;
import ministd.format.parse : FormatSegment, parseFormatString;
import ministd.range.primitives : isOutputRange;

@safe nothrow @nogc:

void formattedWrite(string fmt, OutputRange, Args...)(scope ref OutputRange output, Args args) //

        if (fmt.length && isOutputRange!(OutputRange, char) && isOutputRange!(OutputRange, char[]))
{
    enum FormatSegment[] segs = parseFormatString!fmt;
    static foreach (seg; segs)
    {
        static if (!seg.isFormatSpec)
            output.put(seg.str);
        else
        {
            output.put(args[seg.argIndex].to!(char[]));
        }
    }
}

@("formattedWrite simple")
unittest
{
    import ministd.typecons : Appender;

    Appender!char appender;
    formattedWrite!"aze"(appender);
    assert(appender.get == "aze");
}

@("formattedWrite uint arg")
unittest
{
    import ministd.typecons : Appender;

    Appender!char appender;
    appender.formattedWrite!"test %s"(1u);
    assert(appender.get == "test 1");
}

@("formattedWrite integer args")
unittest
{
    import ministd.typecons : Appender;

    Appender!char appender;
    appender.formattedWrite!"unsigned: %s %s %s %s; signed: %s %s %s %s"(
        ubyte.max, ushort.max, uint.max, ulong.max,
        byte.min, short.min, int.min, long.min,
    );
    
    assert(appender.get[0 .. 53] == "unsigned: 255 65535 4294967295 18446744073709551615; ");
    assert(appender.get[53 .. 105] == "signed: -128 -32768 -2147483648 -9223372036854775808");
}
