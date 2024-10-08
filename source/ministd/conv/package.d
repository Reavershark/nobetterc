module ministd.conv;

public import ministd.conv.to;

import ministd.range.primitives : ElementType, isInputRange;
import ministd.traits : isSomeChar, isSomeString;
import ministd.typecons : Appender, UniqueHeapArray;

@safe nothrow @nogc:

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
