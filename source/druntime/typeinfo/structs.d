module druntime.typeinfo.structs;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe @nogc:

mixin template TypeInfo_StructClassBody()
{
    import druntime.libc_funcs : memcmp;
    import druntime.typeinfo.common : withArgTypes;

@safe @nogc:

    enum StructFlags : uint
    {
        hasPointers = 0x1,
        isDynamicType = 0x2, /// Built at runtime, needs type info in xdtor
    }

    string mangledName;

    void[] m_init; /// Initializer; m_init.ptr == null if 0 initialized

    @safe pure nothrow
    {
        size_t function(in void*) xtoHash;
        bool function(in void*, in void*) xopEquals;
        int function(in void*, in void*) xopCmp;
        string function(in void*) xtoString;
    }

    StructFlags m_flags;

    union
    {
        void function(void*) xdtor;
        void function(void*, const TypeInfo_Struct ti) xdtorti;
    }

    void function(void*) xpostblit;

    uint m_align;

    static if (withArgTypes)
    {
        TypeInfo m_arg1;
        TypeInfo m_arg2;
    }

    immutable(void)* m_RTInfo; // data for precise GC

const:

    final override @system
    void destroy(void* p)
    {
        if (xdtor)
        {
            if (m_flags & StructFlags.isDynamicType)
                (*xdtorti)(p, this);
            else
                (*xdtor)(p);
        }
    }

    override @system
    void postblit(void* p)
    {
        if (xpostblit)
            (*xpostblit)(p);
    }

pure nothrow:

    //
    // Overridden Object methods
    //

    override
    size_t toHash() => hashOf(mangledName);

    //
    // Overridden TypeInfo methods
    //

    override @system
    int compare(in void* p1, in void* p2)
    {
        // Regard null references as always being "less than"
        if (p1 != p2)
        {
            if (p1)
            {
                if (!p2)
                    return true;
                else if (xopCmp)
                {
                    const dg = MemberFunc(p1, xopCmp);
                    return dg.xopCmp(p2);
                }
                else // BUG: relies on the GC not moving objects
                    return memcmp(p1, p2, initializer().length);
            }
            else
                return -1;
        }
        return 0;
    }

    override @system
    bool equals(in void* p1, in void* p2)
    {
        if (!p1 || !p2)
            return false;
        else if (xopEquals)
        {
            const dg = MemberFunc(p1, xopEquals);
            return dg.xopEquals(p2);
        }
        else if (p1 == p2)
            return true;
        else // BUG: relies on the GC not moving objects
            return memcmp(p1, p2, initializer().length) == 0;
    }

    override
    const(void)[] initializer() => m_init;

    override
    uint flags() => m_flags;

    override @system
    size_t getHash(in void* p)
    {
        assert(p);
        if (xtoHash)
        {
            return (*xtoHash)(p);
        }
        else
        {
            return hashOf(p[0 .. initializer().length]);
        }
    }

    override
    bool opEquals(in TypeInfo other)
    {
        if (other is null)
            return false;
        if (this is other)
            return true;
        auto s = cast(const TypeInfo_Struct) other;
        return s && mangledName == s.mangledName;
    }

    override
    size_t tsize() => initializer.length;

    override
    size_t talign() => m_align;

    override
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink(name);
    }

    override @system
    immutable(void)* rtInfo() => m_RTInfo;

    //
    // TypeInfo_Struct methods
    //

    final
    string name()
    {
        // ToDo: demangle
        return mangledName;
    }

    // The xopEquals and xopCmp members are function pointers to member
    // functions, which is not guaranteed to share the same ABI, as it is not
    // known whether the `this` parameter is the first or second argument.
    // This wrapper is to convert it to a delegate which will always pass the
    // `this` parameter in the correct way.
    private struct MemberFunc
    {
        union
        {
            struct  // delegate
            {
                const void* ptr;
                const void* funcptr;
            }

            @safe pure nothrow @nogc
            {
                bool delegate(in void*) xopEquals;
                int delegate(in void*) xopCmp;
            }
        }
    }
}

@("TypeInfo_Struct")
unittest
{
    struct S
    {
    }

    TypeInfo_Struct ti = typeid(S);
    assert(ti !is null);
    assert(ti.tsize == S.sizeof);
}
