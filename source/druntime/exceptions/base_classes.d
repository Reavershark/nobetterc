/// Provides the `Throwable`, `Exception` and `Error` body mixins for use in object.d
module druntime.exceptions.base_classes;

version (DRuntimeExceptions)  :  //

@safe @nogc:

mixin template Throwable_ClassBody()
{
@safe @nogc:

    string msg;
    string file;
    size_t line;

    pure nothrow
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        this.msg = msg;
        this.file = file;
        this.line = line;
    }

    pure nothrow ~this()
    {
    }

const:

    override nothrow @trusted
    string toString()
    {
        string ret;
        scope auto sink = (in string s) @trusted pure nothrow @nogc {
            // TODO
            ret /*~*/  = s;
        };
        toString(sink);
        return ret;
    }

    @trusted pure nothrow
    void toString(scope void delegate(in string) @safe pure nothrow @nogc sink)
    {
        // TODO: also pass file, line, msg
        sink(typeid(this).name);
    }
}

mixin template Exception_ClassBody()
{
@safe @nogc pure nothrow:

    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

mixin template Error_ClassBody()
{
@safe @nogc pure nothrow:

    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}
