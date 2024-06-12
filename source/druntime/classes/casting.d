module druntime.classes.casting;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe pure nothrow @nogc:

/**
 * Dynamic cast from a class object `o` to class or interface `c`, where `c` is a subtype of `o`.
 * Params:
 *      o = instance of class
 *      c = a subclass of o
 * Returns:
 *      null if o is null or c is not a subclass of o. Otherwise, return o.
 */
extern (C)
void* _d_dynamic_cast(Object o, TypeInfo_Class c)
{
    void* res = null;
    size_t offset = 0;
    if (o && _d_isbaseof2(typeid(o), c, offset))
        res = (() @trusted => cast(void*) o + offset)();
    return res;
}

extern (C)
int _d_isbaseof(scope const TypeInfo_Class subClassTi, scope const TypeInfo_Class baseClassTi)
{
    size_t offset = 0;
    return _d_isbaseof2(subClassTi, baseClassTi, offset);
}

extern (C) @trusted
int _d_isbaseof2(scope const TypeInfo_Class subClassTi, scope const TypeInfo_Class baseClassTi, out size_t offset)
{
    if (areClassInfosEqual(subClassTi, baseClassTi))
        return true;

    for (const(TypeInfo_Class)* curr = &subClassTi; curr.base !is null; curr = &curr.base)
    {
        if (areClassInfosEqual(curr.base, baseClassTi))
            return true;

        // Bugzilla 2013: Use depth-first search to calculate offset
        // from the derived (oc) to the base (c).
        foreach (iface; curr.interfaces)
            if (areClassInfosEqual(iface.classinfo, baseClassTi) || _d_isbaseof2(iface.classinfo, baseClassTi, offset))
            {
                offset += iface.offset;
                return true;
            }
    }

    return false;
}

// Needed because ClassInfo.opEquals(Object) does a dynamic cast,
// but we are trying to implement dynamic cast.
private
bool areClassInfosEqual(in TypeInfo_Class a, in TypeInfo_Class b)
{
    // same class if signatures match, works with potential duplicates across binaries
    if (a is b)
        return true;

    // new fast way
    // TODO: enable when updated
    //if (a.m_flags & TypeInfo_Class.ClassFlags.hasNameSig)
    //    return a.nameSig[0] == b.nameSig[0]
    //        && a.nameSig[1] == b.nameSig[1]
    //        && a.nameSig[2] == b.nameSig[2]
    //        && a.nameSig[3] == b.nameSig[3];

    // old slow way for temporary binary compatibility
    return a.name == b.name;
}
