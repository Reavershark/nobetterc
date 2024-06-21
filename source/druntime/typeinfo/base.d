module druntime.typeinfo.base;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe @nogc:

mixin template TypeInfoClassBody()
{
const @safe @nogc:

    //
    // Overridden Object methods
    //

    final override
    int opCmp(in Object other)
    {
        if (this is other)
            return 0;
        auto ti = cast(const TypeInfo) other;
        if (ti is null)
            return 1;

        return __cmp(toString, ti.toString);
    }

    /// Redirects to opEquals(const TypeInfo)
    final override pure nothrow
    bool opEquals(in Object other) => opEquals(cast(const TypeInfo) other);

    override pure nothrow
    size_t toHash() => toString.hashOf;

    final override pure nothrow @trusted
    string toString() scope
    {
        string ret;

        scope auto sink = (in string s) @trusted pure nothrow @nogc {
            // TODO
            ret /*~*/  = s;
        };
        toString(sink);

        return ret;
    }

    //
    // TypeInfo methods with const args
    //

    /// Compares two instances for <, ==, or >.
    @system pure nothrow
    int compare(in void* p1, in void* p2) => assert(0, "TypeInfo.compare is not implemented");

    /// Compares two instances for equality.
    @system pure nothrow
    bool equals(in void* p1, in void* p2) => p1 == p2;

    /**
     * Get flags for type:
     * - bit `0x1` means GC should scan for pointers.
     * - bit `0x2` means arg of this type is passed in SIMD register(s) if available.
     */
    pure nothrow
    uint flags() => 0;

    /**
     * Computes a hash of the instance of a type.
     * Params:
     *    p = pointer to start of instance of the type
     * Returns:
     *    the hash
     * Bugs:
     *    fix https://issues.dlang.org/show_bug.cgi?id=12516 e.g. by changing this to a truly safe interface.
     */
    @system pure nothrow
    size_t getHash(in void* p) => hashOf(p);

    /**
     * Return default initializer.  If the type should be initialized to all
     * zeros, an array with a null ptr and a length equal to the type size will
     * be returned. For static arrays, this returns the default initializer for
     * a single element of the array, use tsize to get the correct size.
     */
    @trusted nothrow pure
    const(void)[] initializer()
    {
        return (cast(const(void)*) null)[0 .. typeof(null).sizeof];
    }

    /// Get TypeInfo for 'next' type, as defined by what kind of type this is, null if none.
    pure nothrow
    const(TypeInfo) next() => null;

    /// Get type information on the contents of the type; null if not available
    pure nothrow
    const(OffsetTypeInfo)[] offTi() => null;

    pure nothrow
    bool opEquals(in TypeInfo other)
    {
        if (other is null)
            return false;
        if (this is other)
            return true;
        return other && __equals(toString, other.toString);
    }

    @system pure nothrow
    immutable(void)* rtInfo() => null;

    /// Return alignment of type
    pure nothrow
    size_t talign() => tsize;

    /// Returns size of the type.
    pure nothrow
    size_t tsize() => 0;

    //
    // TypeInfo methods with mutable args
    //

    /// Run the destructor on the object and all its sub-objects
    @system
    void destroy(void* p)
    {
    }

    /// Run the postblit on the object and all its sub-objects
    @system
    void postblit(void* p)
    {
    }

    /// Swaps two instances of the type.
    @system pure nothrow
    void swap(void* p1, void* p2)
    {
        size_t remaining = tsize;
        // If the type might contain pointers perform the swap in pointer-sized
        // chunks in case a garbage collection pass interrupts this function.
        if ((cast(size_t) p1 | cast(size_t) p2) % (void*).alignof == 0)
        {
            while (remaining >= (void*).sizeof)
            {
                void* tmp = *cast(void**) p1;
                *cast(void**) p1 = *cast(void**) p2;
                *cast(void**) p2 = tmp;
                p1 += (void*).sizeof;
                p2 += (void*).sizeof;
                remaining -= (void*).sizeof;
            }
        }
        for (size_t i = 0; i < remaining; i++)
        {
            byte t = (cast(byte*) p1)[i];
            (cast(byte*) p1)[i] = (cast(byte*) p2)[i];
            (cast(byte*) p2)[i] = t;
        }
    }

    pure nothrow
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        const TypeInfo_Class ti = typeid(this);
        sink(ti.name);
    }
}

mixin template OffsetTypeInfoStructBody()
{
    size_t offset; /// Offset of member from start of object
    TypeInfo ti; /// TypeInfo for this member
}

@("TypeInfo")
unittest
{
    auto ti = dalloc!TypeInfo;
    dfree(ti);
}
