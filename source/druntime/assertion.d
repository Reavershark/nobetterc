module druntime.assertion;

version (DRuntimeAssertion)  :  //

import druntime.libc_funcs : abort;

import ministd.format : f;
import ministd.stdio : writeln, writefln;

@safe @nogc:

/// Handle assert failed
extern (C)
noreturn _d_assert(const string file, const uint line)
    => handleAssertFailure(file, line);

/// Handle assert with message failed
extern (C)
noreturn _d_assert_msg(const string msg, const string file, const uint line)
    => handleAssertFailure(file, line, msg);

/// Handle out of bounds array indexing
extern (C)
noreturn _d_arraybounds_index(
    const string file, const uint line,
    const size_t index, const size_t length
)
{
    auto msg = f!"slice index %s out of bounds for length %s"(index, length);
    handleAssertFailure(file, line, msg.get);
}

/// Handle when an out of bounds slice is taken of another slice
extern (C)
noreturn _d_arraybounds_slice(
    const string file, const uint line,
    const size_t lower, const size_t upper, const size_t length
)
{
    auto msg = f!"out of bounds slice [%s .. %s] taken for length %s"(lower, upper, length);
    handleAssertFailure(file, line, msg.get);
}

/// Handle hitting the end of a final switch
noreturn __switch_error()(const string file = __FILE__, const uint line = __LINE__)
    => handleAssertFailure(file, line, "Hit the end of a final switch");

private
noreturn handleAssertFailure(string file, uint line, const(char)[] msg = "")
{
    writeln;
    writefln!"Assert failiure in file %s:%s"(file, line);
    if (msg && msg.length)
        writefln!`Message: "%s"`(msg);

    abort;
}

@("Assert tests (commented out)")
unittest
{
    int[4] arr;
    int[] slice = arr[];

    // assert(false);
    // assert(false, "message");
    // slice[4] = 1;
    // slice[0 .. 5] = 1;
}
