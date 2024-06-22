module druntime.exceptions.functions;

version (DRuntimeExceptions)  :  //

@safe @nogc:

version (DRuntimeExceptionsImplSimpleNoCatch)
{
nothrow extern (C):
    noreturn _d_throw_exception(Throwable throwable)
    {
        printf("Exception thrown: %s", &throwable.toString[0]);
        assert(false, "Exception thrown with SimpleNoCatch exceptions impl");
    }

pure:
    noreturn _d_eh_enter_catch() => assert(false);
    noreturn _d_delThrowable(scope Throwable t) => assert(false);
    noreturn _d_eh_personality() => assert(false);
}
else version (DRuntimeExceptionsImplLibunwind)
{
    static assert(false, "Exceptions using libunwind is TODO");
}
