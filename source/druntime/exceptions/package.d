module druntime.exceptions;

version (DRuntimeExceptions)  :  //

@safe @nogc:

// dfmt off
version (DRuntimeClassesAndTypeInfo) {}
else static assert(false, "Version DRuntimeExceptions requires version DRuntimeClassesAndTypeInfo");

version (DRuntimeExceptionsImplSimpleNoCatch) {}
else version (DRuntimeExceptionsImplLibunwind) {}
else static assert(false, "Version DRuntimeExceptions requires a DRuntimeExceptionsImpl version");
// dfmt on
