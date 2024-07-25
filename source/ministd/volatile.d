module ministd.volatile;

import ministd.algorithm : among;
import ministd.meta : AliasSeq;
import ministd.traits : isAggregateType, isPointer, Unqual;

import core.volatile : volatileLoad, volatileStore;

@safe nothrow @nogc:

enum bool bitfieldsSupported = __traits(compiles, __traits(isBitfield, null));

private
template loadStoreTypeOf(T) //
{
    alias UT = Unqual!T;
    static foreach (alias el; AliasSeq!(ubyte, ushort, uint, ulong))
        static if (UT.sizeof == el.sizeof)
            alias loadStoreTypeOf = el;

    static assert(is(loadStoreTypeOf), "Incompatible type for volatile load/store");
}

struct VolatileRef(T) //
if (!isAggregateType!T)
{
nothrow @nogc:
    alias LST = loadStoreTypeOf!T;

    private LST* m_ref;

scope:
    @trusted
    this(T* reference)
    {
        m_ref = cast(LST*) cast(void*) reference;
    }

    @trusted
    T get()
    {
        LST lstValue = volatileLoad(m_ref);
        T value = *(cast(T*) cast(void*)&lstValue);
        return value;
    }

    alias get this;

    @trusted
    void set(T value)
    {
        LST lstValue = *(cast(LST*) cast(void*)&value);
        volatileStore(m_ref, lstValue);
    }

    T opAssign(T value)
    {
        set(value);
        return value;
    }

    T opOpAssign(string op)(T arg)
    {
        T value = get;
        mixin("value " ~ op ~ "= arg;");
        set(value);
        return value;
    }

    auto opUnary(string op)() //
    if (op.among("-", "+", "~"))
    {
        mixin("return " ~ op ~ "get;");
    }

    ref auto opUnary(string op)() //
    if (op == "*" && isPointer!T)
    {
        return *get;
    }

    T opUnary(string op)() //
    if (op.among("++", "--"))
    {
        T value = get;
        mixin(op ~ "value;");
        set(value);
        return value;
    }
}

struct VolatileRef(T) //
if (is(T == struct) || is(T == union))
{
nothrow @nogc:
    private T* m_ref;

    this(T* reference)
    {
        m_ref = reference;
    }

    auto opDispatch(string member)() //
    if (is(typeof(mixin("T." ~ member))))
    {
        alias M = typeof(mixin("T." ~ member));
        static assert(is(M == struct) || is(M == union) || !isAggregateType!M);
        static if (bitfieldsSupported && __traits(isBitfield, mixin("T." ~ member)))
            return VolatileBitfieldRef!(T, member)(m_ref);
        else
            return VolatileRef!M(&mixin("m_ref." ~ member));
    }
}

struct VolatileBitfieldRef(T, string member) //
if (bitfieldsSupported && is(typeof(mixin("T." ~ member))))
{
nothrow @nogc:
    alias M = typeof(mixin("T." ~ member));
    alias LST = loadStoreTypeOf!M;
    enum size_t memberBitOffset = mixin("T." ~ member).bitoffsetof;

    private T* m_ref;

    this(T* reference)
    {
        m_ref = reference;
    }
}

@("VolatileRef: ubyte")
unittest
{
    ubyte* a = dalloc!ubyte;
    scope (exit)
        dfree(a);
    auto v = VolatileRef!ubyte(a);

    assert(*a == 0);
    assert(v.get == 0);
    assert(v == 0);

    v = 2;
    assert(*a == 2);
    assert(v == 2);
    assert(v.get == 2);

    v *= 10;
    assert(v == 20);

    v /= 5;
    assert(v == 4);

    v -= 5;
    assert(v == 255);

    v >>= 1;
    assert(v == 127);
}

@("VolatileRef: byte")
unittest
{
    byte a;
    auto v = VolatileRef!byte(&a);

    assert(a == 0);
    assert(v.get == 0);
    assert(v == 0);

    v = 2;
    assert(a == 2);
    assert(v == 2);
    assert(v.get == 2);

    v *= 10;
    assert(v == 20);

    v /= 5;
    assert(v == 4);

    v -= 5;
    assert(v == -1);

    v <<= 4;
    assert(v == -16);
}

@("VolatileRef: pointers")
unittest
{
    int a;
    int* ptr = null;
    auto v = VolatileRef!(int*)(&ptr);

    assert(a == 0);
    assert(ptr is null);
    assert(v.get is null);
    assert(v is null);

    v = &a;
    assert(a == 0);
    assert(ptr is &a);
    assert(v.get is &a);
    assert(v is &a);

    (*v)++; // Changing the referenced value is not volatile
    assert(a == 1);

    VolatileRef!int(v.get) += 1; // But here, every operation is volatile
    assert(a == 2);
}

@("VolatileRef: structs")
unittest
{
    import ministd.traits : ReturnType;

    struct S
    {
        struct Embedded
        {
            int b;
        }

        int a;
        Embedded e;
    }

    S s;
    auto v = VolatileRef!S(&s);
    static assert(is(ReturnType!(typeof(v.a)) == VolatileRef!int));
    static assert(is(ReturnType!(typeof(v.e)) == VolatileRef!(S.Embedded)));
    static assert(is(ReturnType!(typeof(v.e.b)) == VolatileRef!int));

    assert(++v.a == 1);
    assert(++v.e.b == 1);
}
