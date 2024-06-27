module ministd.algorithm;

public import ministd.algorithm.move;

import ministd.range.primitives : empty, front, isInputRange, popFront;
import ministd.traits : isCallable;

@safe @nogc:

pure nothrow
uint among(Value, Values...)(Value value, Values values) //
if (Values.length != 0)
{
    foreach (uint i, ref v; values)
        if (value == v)
            return i + 1;
    return 0;
}

void each(alias fn, Range)(scope Range input)
if (isCallable!fn && isInputRange!Range)
{
    foreach (ref el; input)
        fn(el);
}

bool startsWith(Range, Element)(Range r, Element e) // range and element version
if (isInputRange!Range && is(typeof(r.front == e) == bool))
{
    if (r.empty)
        return false;

    return r.front == e;
}

bool startsWith(Range)(scope Range r1, scope Range r2) // 2 ranges version
if (isInputRange!Range2 && is(typeof(r1.front == r2.front) : bool))
{
    if (r2.empty)
        return true;
    if (r1.empty)
        return false;

    static if (hasLength!Range)
    {
        if (r1.length < r2.length)
            return false;
        // Can assume r1.length >= r2.length from here on

        static if (isSlice!Range)
        {
            return r1[0 .. r2.length] == r2;
        }
        else static if (isRandomAccessRange!Range)
        {
            foreach (i; 0 .. r2.length)
                if (r1[i] != r2[i])
                    return false;
            return true;
        }
        else
        {
            while (r1.front == r2.front)
            {
                r2.popFront;
                if (r2.empty)
                    return true;
                r1.popFront;
            }
            return false;
        }
    }
    else
    {
        while (r1.front == r2.front)
        {
            r2.popFront;
            if (r2.empty)
                return true;

            r1.popFront;
            if (r1.empty)
                return false;
        }
        return false;
    }
}

auto max(T)(in T[] args...)
in (args.length >= 1)
{
    size_t maxIndex;
    foreach (i, arg; args[1 .. $])
        if (arg > args[maxIndex])
            maxIndex = i + 1;
    return args[maxIndex];
}

@("max")
unittest
{
    assert(max(1, 3, 2) == 3);
}