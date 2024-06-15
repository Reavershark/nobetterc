module test.run_tests;

version (unittest)  :  //

@safe:

enum string[] modules = [
    "app.main",
    "druntime.assertion",
    "druntime.classes.casting",
    "druntime.classes.comparison",
    "druntime.classes.object_class",
    "druntime.comparison",
    "druntime.destroy",
    "druntime.exceptions",
    "druntime.exceptions.base_classes",
    "druntime.exceptions.functions",
    "druntime.hashing",
    "druntime.heap",
    "druntime.slices.comparison",
    "druntime.slices.copying",
    "druntime.slices.equality",
    "druntime.typeinfo.base",
    "druntime.typeinfo.classes_interfaces",
    "druntime.typeinfo.enums_tuples",
    "druntime.typeinfo.functions",
    "druntime.typeinfo.pointers",
    "druntime.typeinfo.primitives",
    "druntime.typeinfo.slices",
    "druntime.typeinfo.static_arrays",
    "druntime.typeinfo.structs",
    "druntime.typeinfo.structs_unions_vectors",
    "druntime.typeinfo.type_attributes",
    "ministd.algorithm",
    "ministd.heap",
    "ministd.string",
    "ministd.typecons",
    "object",
];

nothrow @nogc
string testName(alias test)()
{
    string name = __traits(identifier, test);

    foreach (alias attribute; __traits(getAttributes, test))
    {
        static if (is(typeof(attribute) : string))
        {
            name = attribute;
            break;
        }
    }

    return name;
}

extern (C)
void main()
{
    // dfmt off
    static foreach (enum string moduleString; modules)
    {{
        printf("Running unittests for module %s:\n", &moduleString[0]);
        alias tests = __traits(getUnitTests, imported!moduleString);
        static foreach (alias test; tests)
        {{
            printf("- Running unittest %s: ", &testName!test[0]);
            (() @trusted => test())();
            printf("success\n");
        }}
    }}
    // dfmt on
}
