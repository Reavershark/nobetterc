module ministd.conv.internal.to_string;

import ministd.traits : amongTypes, Unqual;
import ministd.typecons : UniqueHeapArray;

package(ministd.conv) @safe nothrow @nogc:

UniqueHeapArray!char integerToCharArray(S)(in S src) //
if (amongTypes!(S, ulong, long))
{
    UniqueHeapArray!char result;
    uint digits;
    S cpy;
    bool isNegative; // Optimized out for ulong

    static if (is(S == long))
        isNegative = src < 0;

    // Calc needed digits
    cpy = src;
    do
    {
        digits++;
        cpy /= 10;
    }
    while (cpy);

    // Build result string
    result = result.create(isNegative + digits);

    if (isNegative)
        result[0] = '-';

    cpy = src;
    foreach_reverse (i; 0 .. digits)
    {
        int digit = cpy % 10;
        if (digit < 0)
            digit = -digit;
        result[isNegative + i] = cast(char)('0' + digit);
        cpy /= 10;
    }

    return result;
}
