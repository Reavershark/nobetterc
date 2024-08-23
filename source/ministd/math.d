module ministd.math;

@safe pure nothrow @nogc:

T abs(T)(const T value)
    => value >= 0 ? value : -value;

T clamp(T)(const T value, const T min, const T max)
{
    if (value < min)
        return min;
    if (value > max)
        return max;
    return value;
}

bool inRange(string spec = "[[", T)(const T value, const T lower, const T upper)
{
    static assert(spec.length == 2, "Range spec must have 2 characters");
    static foreach (c; spec)
        static assert(c == '[' || c == ']', "Only '[' and ']' are valid spec characters");

    bool lowerCheck, upperCheck;

    static if (spec[0] == ']')
        lowerCheck = lower < value;
    else
        lowerCheck = lower <= value;

    static if (spec[1] == '[')
        upperCheck = value < upper;
    else
        upperCheck = value <= upper;

    return lowerCheck && upperCheck;
}
