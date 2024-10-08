module druntime.typeinfo.type_attributes;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe pure nothrow @nogc:

mixin template TypeInfo_ConstClassBody()
{
@safe pure nothrow @nogc:
    TypeInfo base;

override const:
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
@safe pure nothrow @nogc:
override const:
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
@safe pure nothrow @nogc:
override const:
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
@safe pure nothrow @nogc:
override const:
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        sink("shared");
        sink("(");
        base.toString(sink);
        sink(")");
    }
}

@("TypeInfo_Const")
unittest
{
    TypeInfo_Const ti = typeid(const int);
    assert(ti !is null);
    assert(ti.base is typeid(int));
}

@("TypeInfo_Invariant")
unittest
{
    TypeInfo_Invariant ti = typeid(immutable int);
    assert(ti !is null);
    assert(ti.base is typeid(int));
    assert(cast(TypeInfo_Const) ti !is null);
}

@("TypeInfo_Inout")
unittest
{
    TypeInfo_Inout ti = typeid(inout int);
    assert(ti !is null);
    assert(ti.base is typeid(int));
    assert(cast(TypeInfo_Const) ti !is null);
}

@("TypeInfo_Shared")
unittest
{
    TypeInfo_Shared ti = typeid(shared int);
    assert(ti !is null);
    assert(ti.base is typeid(int));
    assert(cast(TypeInfo_Const) ti !is null);
}
