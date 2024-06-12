module druntime.classes.comparison;

version (DRuntimeClassesAndTypeInfo)  :  //

@safe pure nothrow @nogc:

/**
 * Implementation for class opEquals override. Calls the class-defined methods after a null check.
 * Please note this is not nogc right now, even if your implementation is, because of
 * the typeinfo name string compare. This is because of dmd's dll implementation. However,
 * it can infer to @safe if your class' opEquals is.
 */
bool opEquals(LHS, RHS)(LHS lhs, RHS rhs)
        if ((is(LHS : const Object) || is(LHS : const shared Object)) &&
        (is(RHS : const Object) || is(RHS : const shared Object)))
{
    static if (__traits(compiles, lhs.opEquals(rhs)) && __traits(compiles, rhs.opEquals(lhs)))
    {
        // If aliased to the same object or both null => equal
        if (lhs is rhs)
            return true;

        // If either is null => non-equal
        if (lhs is null || rhs is null)
            return false;

        if (!lhs.opEquals(rhs))
            return false;

        // If same exact type => one call to method opEquals
        if (typeid(lhs) is typeid(rhs) ||
            !__ctfe && typeid(lhs).opEquals(typeid(rhs))) /*
                CTFE doesn't like typeid much. 'is' works, but opEquals doesn't
                (issue 7147). But CTFE also guarantees that equal TypeInfos are
                always identical. So, no opEquals needed during CTFE.
            */
        {
            return true;
        }

        // General case => symmetric calls to method opEquals
        return rhs.opEquals(lhs);
    }
    else
    {
        // this is a compatibility hack for the old const cast behavior
        // if none of the new overloads compile, we'll go back plain Object,
        // including casting away const. It does this through the pointer
        // to bypass any opCast that may be present on the original class.
        return .opEquals!(Object, Object)(*cast(Object*)&lhs, *cast(Object*)&rhs);

    }
}
