module ministd.format.write;

import ministd.conv : to;
import ministd.format.parse : FormatSegment, parseFormatString;
import ministd.range.primitives : equalUnqualElementTypes, isOutputRange;
import ministd.typecons : Appender, DynArray;

@safe nothrow @nogc:

DynArray!char format(string fmt, Args...)(Args args)
{
    Appender!char output;
    output.formattedWrite!fmt(args);
    return output;
}

@("format string int uint")
unittest
{
    assert(format!"1 %s 3 %s"("2", 4) == "1 2 3 4"); 
    assert(format!"1 %s 3 %s"("2", 4u) == "1 2 3 4");
    assert(format!"1 %s 3 %s"("2", -4) == "1 2 3 -4");
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

// dfmt off
void formattedWrite(string fmt, OutputRange, Args...)(scope ref OutputRange output, Args args)
if (fmt.length && isOutputRange!(OutputRange, char) && isOutputRange!(OutputRange, char[]))
{
    enum FormatSegment[] segs = parseFormatString!fmt;
    static foreach (seg; segs)
    {{
        static if (seg.isFormatSpec)
        {
            alias Arg = typeof(args[seg.argIndex]);
            alias arg = args[seg.argIndex];
        }

        static if (!seg.isFormatSpec) // Not a format spec, print segment raw
            output.put(seg.str);
        else static if (is(Unqual!Arg == char)) // Some char
            output.put(arg);
        else static if (equalUnqualElementTypes!(Arg, char[])) // Some char[]
            output.put(arg);
        else // Something else
            output.put(arg.to!(char[]));
    }}
}
// dfmt on

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
