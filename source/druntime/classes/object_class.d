module druntime.classes.object_class;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe @nogc:

mixin template ObjectClassBody()
{
@safe @nogc:
    interface Monitor
    {
        void lock();
        void unlock();
    }

const:
    static nothrow
    Object factory(string classname)
    {
        //auto ci = TypeInfo_Class.find(classname);
        //if (ci)
        //{
        //    return ci.create();
        //}
        return null;
    }

    pure nothrow
    int opCmp(in Object o)
    {
        assert(0, "disabled code");
        //throw new Exception("need opCmp for class " ~ typeid(this).name);
    }

    pure nothrow
    bool opEquals(in Object o) => this is o;

    @trusted pure nothrow
    size_t toHash()
    {
        size_t addr = cast(size_t) cast(void*) this;
        return addr ^ (addr >>> 4);
    }

    nothrow
    string toString() => typeid(this).name;
}
