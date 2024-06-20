module druntime.typeinfo.classes_interfaces;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe @nogc:

mixin template TypeInfo_ClassClassBody()
{
    enum ClassFlags : uint
    {
        isCOMclass = 0x1,
        noPointers = 0x2,
        hasOffTi = 0x4,
        hasCtor = 0x8,
        hasGetMembers = 0x10,
        hasTypeInfo = 0x20,
        isAbstract = 0x40,
        isCPPclass = 0x80,
        hasDtor = 0x100,
        hasNameSig = 0x200,
    }

    byte[] m_init; /// Class static initializer (init.length gives size in bytes of class)
    string name; /// Class name
    void*[] vtbl; /// Virtual function pointer table
    Interface[] interfaces; /// Interfaces this class implements
    TypeInfo_Class base; /// Base class
    void* destructor;
    void function(Object) classInvariant;
    ClassFlags m_flags;
    static if (__VERSION__ >= 2_108) ushort depth; /// Inheritance distance from Object
    void* deallocator;
    OffsetTypeInfo[] m_offTi;
    void function(Object) defaultConstructor;
    immutable(void)* m_RTInfo; /// Data for precise GC
    static if (__VERSION__ >= 2_108) uint[4] nameSig; /// Unique signature for `name`

const @safe pure nothrow @nogc:

    //
    // Overridden TypeInfo methods
    //

    override @system
    int compare(in void* p1, in void* p2)
    {
        Object o1 = *cast(Object*) p1;
        Object o2 = *cast(Object*) p2;
        int c = 0;

        // Regard null references as always being "less than"
        if (o1 !is o2)
        {
            if (o1)
            {
                if (!o2)
                    c = 1;
                else
                    c = o1.opCmp(o2);
            }
            else
                c = -1;
        }
        return c;
    }

    override @system
    bool equals(in void* p1, in void* p2)
    {
        Object o1 = *cast(Object*) p1;
        Object o2 = *cast(Object*) p2;

        return (o1 is o2) || (o1 && o1.opEquals(o2));
    }

    override @system
    size_t getHash(in void* p)
    {
        auto o = *cast(Object*) p;
        return o ? o.toHash() : 0;
    }

    override
    const(void)[] initializer() => m_init;

    override
    bool opEquals(in TypeInfo other)
    {
        if (other is null)
            return false;
        if (this is other)
            return true;
        auto c = cast(const TypeInfo_Class) other;
        return c && this.name == c.name;
    }

    override @system
    immutable(void)* rtInfo() => m_RTInfo;

    override
    size_t tsize() => Object.sizeof;

    override
    uint flags() => 0x1;

    override
    const(OffsetTypeInfo)[] offTi() => m_offTi;

    override
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink(name);
    }

    //
    // TypeInfo_Class methods
    //

    // create() not implemented
    // find() not implemented

    final
    auto info() return  => this;

    /**
     * Returns true if the class described by `child` derives from or is
     * the class described by this `TypeInfo_Class`. Always returns false
     * if the argument is null.
     *
     * Params:
     *  child = TypeInfo for some class
     * Returns:
     *  true if the class described by `child` derives from or is the
     *  class described by this `TypeInfo_Class`.
     */
    final @trusted
    bool isBaseOf(in TypeInfo_Class childTi)
    {
        if (m_init.length)
        {
            // If this TypeInfo_Class represents an actual class we only need
            // to check the child and its direct ancestors.
            for (const(TypeInfo_Class)* curr = &childTi; curr.base !is null; curr = &curr.base)
                if (*curr is this)
                    return true;
            return false;
        }
        else
        {
            import druntime.classes.casting : _d_isbaseof;

            // If this TypeInfo_Class is the .info field of a TypeInfo_Interface
            // we also need to recursively check the child's interfaces.
            return childTi !is null && _d_isbaseof(childTi, this);
        }
    }

    final
    auto typeinfo() return  => this;
}

mixin template TypeInfo_InterfaceClassBody()
{
@safe @nogc:

    TypeInfo_Class info;

const pure nothrow:

    //
    // Overridden TypeInfo methods
    //

    override @system
    int compare(in void* p1, in void* p2) const
    {
        Interface* pi = **cast(Interface***)*cast(void**) p1;
        Object o1 = cast(Object)(*cast(void**) p1 - pi.offset);
        pi = **cast(Interface***)*cast(void**) p2;
        Object o2 = cast(Object)(*cast(void**) p2 - pi.offset);
        int c = 0;

        // Regard null references as always being "less than"
        if (o1 != o2)
        {
            if (o1)
            {
                if (!o2)
                    c = 1;
                else
                    c = o1.opCmp(o2);
            }
            else
                c = -1;
        }
        return c;
    }

    override @system
    bool equals(in void* p1, in void* p2)
    {
        Interface* pi = **cast(Interface***)*cast(void**) p1;
        Object o1 = cast(Object)(*cast(void**) p1 - pi.offset);
        pi = **cast(Interface***)*cast(void**) p2;
        Object o2 = cast(Object)(*cast(void**) p2 - pi.offset);

        return o1 == o2 || (o1 && o1.opCmp(o2) == 0);
    }

    override
    uint flags() => 1;

    override @system
    size_t getHash(in void* p)
    {
        if (!*cast(void**) p)
        {
            return 0;
        }
        Interface* pi = **cast(Interface***)*cast(void**) p;
        Object o = cast(Object)(*cast(void**) p - pi.offset);
        // assert(o);
        return o.toHash();
    }

    override @trusted
    const(void)[] initializer()
    {
        return (cast(void*) null)[0 .. Object.sizeof];
    }

    override
    bool opEquals(in TypeInfo other)
    {
        if (other is null)
            return false;
        if (this is other)
            return true;
        auto c = cast(const TypeInfo_Interface) other;
        return c && this.info.name == typeid(c).name;
    }

    override
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink(info.name);
    }

    override
    size_t tsize() => Object.sizeof;

    //
    // TypeInfo_Interface methods
    //

    /**
     * Returns true if the class described by `child` derives from the
     * interface described by this `TypeInfo_Interface`. Always returns
     * false if the argument is null.
     *
     * Params:
     *  child = TypeInfo for some class
     * Returns:
     *  true if the class described by `child` derives from the
     *  interface described by this `TypeInfo_Interface`.
     */
    final pure nothrow
    bool isBaseOf(in TypeInfo_Class child)
    {
        import druntime.classes.casting : _d_isbaseof;

        return child !is null && _d_isbaseof(child, this.info);
    }

    /**
     * Returns true if the interface described by `child` derives from
     * or is the interface described by this `TypeInfo_Interface`.
     * Always returns false if the argument is null.
     *
     * Params:
     *  child = TypeInfo for some interface
     * Returns:
     *  true if the interface described by `child` derives from or is
     *  the interface described by this `TypeInfo_Interface`.
     */
    final pure nothrow
    bool isBaseOf(in TypeInfo_Interface child)
    {
        import druntime.classes.casting : _d_isbaseof;

        return child !is null && _d_isbaseof(child.info, this.info);
    }
}
