module ministd.conv;

import ministd.range.primitives : ElementType, isInputRange;
import ministd.traits : isAggregateType, isSomeChar, isSomeString, Unqual;
import ministd.typecons : Appender, UniqueHeapArray;

@safe nothrow @nogc:

auto to(To, From)(in From from)
{
    static if (is(To == From))
        return from;
    static if (is(typeof(cast(To) from)))
        return cast(To) from;
    else
    {
        static if (is(To == string))
        {
            static if (is(From == ushort) || is(From == uint) || is(From == ulong))
            {
                uint digits;
                {
                    uint cpy = from;
                    do
                    {
                        digits++;
                        cpy /= 10;
                    }
                    while (cpy);
                }

                auto result = UniqueHeapArray!char.create(digits);
                {
                    uint cpy = from;
                    foreach_reverse (i; 0 .. digits)
                    {
                        result[i] = '0' + cpy % 10;
                        cpy /= 10;
                    }
                }
                return result;
            }
        }
        assert(false, "to!(" ~ To.stringof ~ ", " ~ From.stringof ~ ") not implemented");
    }
}

@("to!(string, uint)")
unittest
{
    assert(0u.to!string == "0");
    assert(1u.to!string == "1");
    assert(9u.to!string == "9");
    assert(10u.to!string == "10");
    assert(1234u.to!string == "1234");
}

UniqueHeapArray!char text(Args...)(Args args) //
if (Args.length > 0)
{
    static if (Args.length == 0)
    {
        return null;
    }
    else static if (Args.length == 1)
    {
        return to!string(args[0]);
    }
    else
    {
        Appender!char appender;

        size_t toReserve;
        foreach (arg; args)
        {
            static if (is(typeof(arg.length)))
                toReserve += arg.length;
            else
                toReserve += 20; // Assume that on average, parameters will have less than 20 elements
        }
        appender.reserve(toReserve);

        foreach (arg; args)
        {
            enum bool isSomeText = isSomeChar!(typeof(arg))
                || isSomeString!(typeof(arg))
                || (isInputRange!(typeof(arg)) && isSomeChar!(ElementType!(typeof(arg))));

            static if (isSomeText)
                appender.put(arg);
            else
                appender.put(to!string(arg));
        }

        return appender.moveArray;
    }
}

bool parse(As, Source)(in Source source)
    => false; // TODO
