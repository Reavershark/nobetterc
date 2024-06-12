module druntime.hashing;

@safe @nogc pure nothrow:

/** 
 * Calculates a `size_t` hash of `value`.
 * The hash of multiple ordered values can be calculated by repeatedly passing the previous
 * hash to the `seed` argument.
 */
size_t hashOf(T)(in T value, size_t seed = 0)
{
    static import core.internal.hash;

    return core.internal.hash.hashOf(value, seed);
}

version (DRuntimeClassesAndTypeInfo)
{
    /// Used by TypeInfo_(Static)Array
    @trusted
    size_t getArrayHash(in TypeInfo element, in void* ptr, in size_t count)
    {
        if (!count)
            return 0;

        const size_t elementSize = element.tsize;
        if (!elementSize)
            return 0;

        static @trusted
        bool hasCustomToHash(in TypeInfo value)
        {
            const element = getElement(value);

            if (const struct_ = cast(const TypeInfo_Struct) element)
                return !!struct_.xtoHash;
            return cast(const TypeInfo_Array) element
                || cast(const TypeInfo_Class) element
                || cast(const TypeInfo_Interface) element;
            //  || cast(const TypeInfo_AssociativeArray) element
        }

        if (!hasCustomToHash(element))
            return hashOf(ptr[0 .. elementSize * count]);

        size_t hash = 0;
        foreach (size_t i; 0 .. count)
            hash = hashOf(element.getHash(ptr + i * elementSize), hash);
        return hash;
    }

    /// Helper function for getArrayHash
    private @trusted
    inout(TypeInfo) getElement(return scope inout TypeInfo value)
    {
        TypeInfo element = cast() value;
        for (;;)
        {
            if (auto qualified = cast(TypeInfo_Const) element)
                element = qualified.base;
            // else if (auto redefined = cast(TypeInfo_Enum) element)
            //     element = redefined.base;
            else if (auto staticArray = cast(TypeInfo_StaticArray) element)
                element = staticArray.value;
            // else if (auto vector = cast(TypeInfo_Vector) element)
            //     element = vector.base;
            else
                break;
        }
        return cast(inout) element;
    }
}

@("hashOf array")
unittest
{
    auto h1 = "my.string".hashOf;
    assert(h1 == "my.string".hashOf);
}

@("hashOf float edge cases")
pure nothrow unittest
{
    assert(hashOf(+0.0) == hashOf(-0.0)); // Same hash for +0.0 and -0.0.
    assert(hashOf(double.nan) == hashOf(-double.nan)); // Same hash for different NaN.
}
