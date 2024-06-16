module druntime.classes.invariant_;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe:

/// Runs the invariant of a class instance and all its base classes.
pragma(mangle, "_D9invariant12_d_invariantFC6ObjectZv") // Hardcoded in ldc
void _d_invariant(Object o)
{
    // BUG: needs to be filename/line of caller, not library routine
    assert(o !is null); // just do null check, not invariant check

    for (TypeInfo_Class c = typeid(o); c; c = c.base)
        if (c.classInvariant)
            (*c.classInvariant)(o);
}
