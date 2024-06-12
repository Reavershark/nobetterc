module druntime.typeinfo.slices;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe @nogc:

mixin template TypeInfo_ArrayClassBody()
{
@safe @nogc:

    TypeInfo value;

const pure nothrow:

    //
    // Overridden TypeInfo methods
    //

    override @system
    int compare(in void* p1, in void* p2)
    {
        void[] a1 = *cast(void[]*) p1;
        void[] a2 = *cast(void[]*) p2;
        size_t sz = value.tsize;
        size_t len = a1.length;

        if (a2.length < len)
            len = a2.length;
        for (size_t u = 0; u < len; u++)
        {
            immutable int result = value.compare(a1.ptr + u * sz, a2.ptr + u * sz);
            if (result)
                return result;
        }
        return (a1.length > a2.length) - (a1.length < a2.length);
    }

    override @system
    bool equals(in void* p1, in void* p2)
    {
        void[] a1 = *cast(void[]*) p1;
        void[] a2 = *cast(void[]*) p2;
        if (a1.length != a2.length)
            return false;
        size_t sz = value.tsize;
        for (size_t i = 0; i < a1.length; i++)
        {
            if (!value.equals(a1.ptr + i * sz, a2.ptr + i * sz))
                return false;
        }
        return true;
    }

    override
    uint flags() => 0x1;

    override @system
    size_t getHash(in void* p)
    {
        import druntime.hashing : getArrayHash;

        void[] a = *cast(void[]*) p;
        return getArrayHash(value, a.ptr, a.length);
    }

    override @trusted
    const(void)[] initializer()
    {
        return (cast(void*) null)[0 .. (void[]).sizeof];
    }

    override @system
    void swap(void* p1, void* p2)
    {
        void[] tmp = *cast(void[]*) p1;
        *cast(void[]*) p1 = *cast(void[]*) p2;
        *cast(void[]*) p2 = tmp;
    }

    override
    const(TypeInfo) next() => value;

    override
    bool opEquals(in TypeInfo other)
    {
        if (other is null)
            return false;
        if (this is other)
            return true;
        auto c = cast(const TypeInfo_Array) other;
        return c && this.value == c.value;
    }

    override
    size_t talign() => (void[]).alignof;

    override
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink(value.toString);
        sink("[]");
    }

    override
    size_t tsize() => (void[]).sizeof;
}

mixin template TypeInfo_PrimitiveArrayClassBody(T)
{
@safe @nogc:
const pure nothrow:

    //
    // Overridden TypeInfo methods
    //

    override @trusted
    int compare(in void* p1, in void* p2)
    {
        template cmp3()
        {
            // Three-way compare for integrals: negative if `lhs < rhs`, positive if `lhs > rhs`, 0 otherwise.
            pragma(inline, true)
            int cmp3(T)(const T lhs, const T rhs) if (__traits(isIntegral, T))
            {
                static if (T.sizeof < int.sizeof) // Taking the difference will always fit in an int.
                    return int(lhs) - int(rhs);
                else
                    return (lhs > rhs) - (lhs < rhs);
            }

            // Three-way compare for real fp types. NaN is smaller than all valid numbers.
            // Code is small and fast, see https://godbolt.org/z/fzb877
            pragma(inline, true)
            int cmp3(T)(const T d1, const T d2)
                    if (is(T == float) || is(T == double) || is(T == real))
            {
                if (d2 != d2)
                    return d1 == d1; // 0 if both ar NaN, 1 if d1 is valid and d2 is NaN.
                // If d1 is NaN, both comparisons are false so we get -1, as needed.
                return (d1 > d2) - !(d1 >= d2);
            }
        }

        // Can't reuse __cmp in object.d because that handles NaN differently.
        // (Q: would it make sense to unify behaviors?)
        // return __cmp(*cast(const T[]*) p1, *cast(const T[]*) p2);
        auto lhs = *cast(const T[]*) p1;
        auto rhs = *cast(const T[]*) p2;
        size_t len = lhs.length;
        if (rhs.length < len)
            len = rhs.length;
        for (size_t u = 0; u < len; u++)
        {
            if (int result = cmp3(lhs.ptr[u], rhs.ptr[u]))
                return result;
        }
        return cmp3(lhs.length, rhs.length);
    }

    override @system
    bool equals(in void* p1, in void* p2)
    {
        // Just reuse the builtin.
        return *cast(const(T)[]*) p1 == *cast(const(T)[]*) p2;
    }

    override @system
    size_t getHash(in void* p)
    {
        return hashOf(*cast(const T[]*) p);
    }

    override
    const(TypeInfo) next()
    {
        return cast(const) typeid(T);
    }

    override
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink(T[].stringof);
    }
}

mixin template TypeInfo_VoidArrayClassBody()
{
@safe @nogc:
const pure nothrow:

    //
    // Overridden TypeInfo methods
    //

    override
    const(TypeInfo) next()
    {
        return cast(const) typeid(void);
    }

    override
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink((void[]).stringof);
    }
}
