module druntime.typeinfo.type_attributes;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe @nogc:

mixin template TypeInfo_ConstClassBody()
{
@safe @nogc:

    TypeInfo base;

override const pure nothrow:

    //
    // Overridden TypeInfo methods
    //

    @system
    bool equals(in void* p1, in void* p2) => base.equals(p1, p2);

    @system
    int compare(in void* p1, in void* p2) => base.compare(p1, p2);

    @system
    size_t getHash(in void* p) => base.getHash(p);

    uint flags() => base.flags;

    const(void)[] initializer() => base.initializer;

    const(TypeInfo) next() => base.next;

    bool opEquals(in TypeInfo other)
    {
        if (other is null)
            return false;
        if (this is other)
            return true;
        if (typeid(this) != typeid(other))
            return false;
        auto t = cast(const TypeInfo_Const) other;
        return base.opEquals(t.base);
    }

    @system
    void swap(void* p1, void* p2) => base.swap(p1, p2);

    size_t talign() => base.talign;

    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink("const");
        sink("(");
        base.toString(sink);
        sink(")");
    }

    size_t tsize() => base.tsize;
}

mixin template TypeInfo_InvariantClassBody()
{
@safe @nogc:
override const pure nothrow:
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink("immutable");
        sink("(");
        base.toString(sink);
        sink(")");
    }
}

mixin template TypeInfo_InoutClassBody()
{
@safe @nogc:
override const pure nothrow:
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink("inout");
        sink("(");
        base.toString(sink);
        sink(")");
    }
}

mixin template TypeInfo_SharedClassBody()
{
@safe @nogc:
override const pure nothrow:
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink("shared");
        sink("(");
        base.toString(sink);
        sink(")");
    }
}
