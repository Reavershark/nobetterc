/**
 * Make ctfe happy.
 *
 * Declares some functions that are only available during ctfe.
 * Trying to call these at runtime will give linker errors.
 */
module druntime.ctfe;

@safe:

/// Writes `s` to `stderr` during CTFE.
pure nothrow @nogc
void __ctfeWrite(scope const(char)[] s);

T[] _d_arrayappendcTX(T)(return ref scope T[] arr, size_t n);

@("Using CTFE-only functions in if (__ctfe) links")
unittest
{
    if (__ctfe)
    {
        __ctfeWrite("");
        _d_arrayappendcTX([], 1);
    }
}
