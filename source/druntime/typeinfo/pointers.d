module druntime.typeinfo.pointers;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe @nogc:

mixin template TypeInfo_PointerClassBody()
{
@safe @nogc:

    TypeInfo m_next;

const pure nothrow:

    //
    // Overridden TypeInfo methods
    //

    override @system
    int compare(in void* p1, in void* p2)
    {
        const v1 = *cast(void**) p1, v2 = *cast(void**) p2;
        return (v1 > v2) - (v1 < v2);
    }

    override @system
    bool equals(in void* p1, in void* p2)
    {
        return *cast(void**) p1 == *cast(void**) p2;
    }

    override
    uint flags() => 0x1;

    override @system
    size_t getHash(in void* p)
    {
        size_t addr = cast(size_t)*cast(const void**) p;
        return addr ^ (addr >> 4);
    }

    override @trusted
    const(void)[] initializer()
    {
        return (cast(void*) null)[0 .. (void*).sizeof];
    }

    override
    const(TypeInfo) next() => m_next;

    override
    bool opEquals(in TypeInfo other)
    {
        if (other is null)
            return false;
        if (this is other)
            return true;
        auto c = cast(const TypeInfo_Pointer) other;
        return c && this.m_next == c.m_next;
    }

    override @system
    void swap(void* p1, void* p2)
    {
        void* tmp = *cast(void**) p1;
        *cast(void**) p1 = *cast(void**) p2;
        *cast(void**) p2 = tmp;
    }

    override
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        m_next.toString(sink);
        sink("*");
    }

    override
    size_t tsize() => (void*).sizeof;
}
