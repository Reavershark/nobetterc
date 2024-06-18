module druntime.assertion;

version (DRuntimeAssertion)  :  //

@safe @nogc:

/// Handle assert failed
extern (C)
noreturn _d_assert(const string file, const uint line)
{
    handleAssertFailure(file, line);
}

/// Handle assert with message failed
extern (C)
noreturn _d_assert_msg(const string msg, const string file, const uint line)
{
    handleAssertFailure(file, line, msg);
}

/// Handle out of bounds array indexing
extern (C)
noreturn _d_arraybounds_index(const string file, const uint line, const size_t index, const size_t length)
{
    handleAssertFailure(file, line, "slice index out of bounds"); // TODO: details
}

/// Handle when an out of bounds slice is taken of another slice
extern (C)
void _d_arraybounds_slice(const string file, const uint line,
    const size_t lower, const size_t upper, const size_t length)
{
    handleAssertFailure(file, line, "out of bounds slice taken"); // TODO: details
}

private noreturn handleAssertFailure(in string file, in uint line, in string msg = "")
{
    import druntime.libc_funcs : abort, putchar;

    void putstr(in string s)
    {
        foreach (const char c; s)
            putchar(c);
    }

    putstr("\n");
    putstr("Assert failiure in file ");
    putstr(file);
    printf(":%d", line);
    if (msg.length)
    {
        putstr(": \"");
        putstr(msg);
        putstr("\"");
    }
    putstr("\n");

    abort;
}
