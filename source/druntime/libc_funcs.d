module druntime.libc_funcs;

@safe @nogc:

nothrow extern (C)
{
    void* malloc(size_t size);
    void free(void* ptr);
    int putchar(const char c);
    int puts(scope const char* s);
    pragma(printf) int printf(scope const char* fmt, scope const ...);
    noreturn abort();
pure:
    void* memcpy(return scope void* dest, scope const void* src, size_t n);
    int memcmp(scope const void* s1, scope const void* s2, size_t n);
}

version (DRuntimeExternLibcFuncs)
{
}
else version (DRuntimeBuiltinLibcFuncs)
{
    static assert(false, "TODO");
}
else static assert(false, "Either version DRuntimeExternLibcFuncs or DRuntimeBuiltinLibcFuncs is required");
