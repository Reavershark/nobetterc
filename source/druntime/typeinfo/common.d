module druntime.typeinfo.common;

@safe pure nothrow @nogc:

// Some ABIs use a complex varargs implementation requiring TypeInfo.argTypes().
enum bool withArgTypes = () {
    // dfmt off
    version (GNU) {} // No TypeInfo-based core.vararg.va_arg().
    else version (X86_64)
    {
        version (DigitalMars) return true;
        else version (Windows) {}
        else return true;
    }
    else version (AArch64)
    {
        // Apple uses a trivial varargs implementation
        version (OSX) {}
        else version (iOS) {}
        else version (TVOS) {}
        else version (WatchOS) {}
        else return true;
    }
    // dfmt on
    return false;
}();
