module druntime.typeinfo.primitives;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe @nogc:

mixin template TypeInfo_PrimitiveClassBody(T)
{
@safe @nogc:
override const pure nothrow:

    //
    // Overridden TypeInfo methods
    //

    @system
    int compare(in void* p1, in void* p2)
    {
        import druntime.comparison : cmp3;

        return cmp3(*cast(const T*) p1, *cast(const T*) p2);
    }

    @system
    bool equals(in void* p1, in void* p2)
    {
        return *cast(const T*) p1 == *cast(const T*) p2;
    }

    static if (__traits(isFloating, T) && T.mant_dig != 64)
    {
        // FP types except 80-bit X87 are passed in SIMD register.
        uint flags() => 0x2;
    }

    @system
    size_t getHash(in void* p) => hashOf(*cast(const T*) p);

    @trusted
    const(void)[] initializer()
    {
        static if (__traits(isZeroInit, T))
        {
            return (cast(void*) null)[0 .. T.sizeof];
        }
        else
        {
            static immutable T[1] c;
            return c;
        }
    }

    @system
    void swap(void* p1, void* p2)
    {
        auto t = *cast(T*) p1;
        *cast(T*) p1 = *cast(T*) p2;
        *cast(T*) p2 = t;
    }

    size_t talign() => T.alignof;

    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink(T.stringof);
    }

    size_t tsize() => T.sizeof;
}

mixin template TypeInfo_VoidClassBody()
{
@safe @nogc:
const pure nothrow:

    //
    // Overridden TypeInfo methods
    //

    override
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink(void.stringof);
    }
}
