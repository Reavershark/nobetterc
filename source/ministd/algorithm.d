module ministd.algorithm;

uint among(Value, Values...)(Value value, Values values) if (Values.length != 0)
{
    foreach (uint i, ref v; values)
        if (value == v)
            return i + 1;
    return 0;
}
