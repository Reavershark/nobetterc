module druntime.typeinfo.static_arrays;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe @nogc:

mixin template TypeInfo_StaticArrayClassBody()
{
@safe @nogc:
    TypeInfo value;
    size_t len;

override const:
    @system
    void destroy(void* p)
    {
        immutable sz = value.tsize;
        p += sz * len;
        foreach (i; 0 .. len)
        {
            p -= sz;
            value.destroy(p);
        }
    }

    @system
    void postblit(void* p)
    {
        immutable sz = value.tsize;
        foreach (i; 0 .. len)
        {
            value.postblit(p);
            p += sz;
        }
    }

pure nothrow:
    @system
    int compare(in void* p1, in void* p2)
    {
        size_t sz = value.tsize;

        for (size_t u = 0; u < len; u++)
        {
            immutable int result = value.compare(p1 + u * sz, p2 + u * sz);
            if (result)
                return result;
        }
        return 0;
    }

    @trusted
    bool equals(in void* p1, in void* p2)
    {
        size_t sz = value.tsize;

        for (size_t u = 0; u < len; u++)
        {
            if (!value.equals(p1 + u * sz, p2 + u * sz))
                return false;
        }
        return true;
    }

    @system
    size_t getHash(in void* p)
    {
        import druntime.hashing : getArrayHash;

        return getArrayHash(value, p, len);
    }

    uint flags() => value.flags;

    const(void)[] initializer() => value.initializer();

    const(TypeInfo) next() => value;

    bool opEquals(in TypeInfo other)
    {
        if (other is null)
            return false;
        if (this is other)
            return true;
        auto c = cast(const TypeInfo_StaticArray) other;
        return c && this.len == c.len &&
            this.value == c.value;
    }

    @system
    immutable(void)* rtInfo() => value.rtInfo();

    @system
    void swap(void* p1, void* p2)
    {
        import core.stdc.string : memcpy;

        size_t remaining = value.tsize * len;
        void[size_t.sizeof * 4] buffer = void;
        while (remaining > buffer.length)
        {
            memcpy(buffer.ptr, p1, buffer.length);
            memcpy(p1, p2, buffer.length);
            memcpy(p2, buffer.ptr, buffer.length);
            p1 += buffer.length;
            p2 += buffer.length;
            remaining -= buffer.length;
        }
        memcpy(buffer.ptr, p1, remaining);
        memcpy(p1, p2, remaining);
        memcpy(p2, buffer.ptr, remaining);
    }

    size_t talign() => value.talign;

    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink("[arrayLenTodo]");
    }

    size_t tsize() => len * value.tsize;
}
