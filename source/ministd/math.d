module ministd.math;

@safe pure nothrow @nogc:

T clamp(T)(const T value, const T min, const T max)
{
    if (value < min)
        return min;
    if (value > max)
        return max;
    return value;
}
