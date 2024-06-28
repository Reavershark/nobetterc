module test.run_tests;

version (unittest)  :  //

import ministd.stdio : write, writeln;
import ministd.string : TC = TermColor;

private @safe:

enum string[] modules = [
    "druntime.assertion",
    "druntime.classes.casting",
    "druntime.classes.comparison",
    "druntime.classes.invariant_",
    "druntime.classes.object_class",
    "druntime.comparison",
    "druntime.ctfe",
    "druntime.destroy",
    "druntime.exceptions",
    "druntime.exceptions.base_classes",
    "druntime.exceptions.functions",
    "druntime.hashing",
    "druntime.heap",
    "druntime.libc_funcs",
    "druntime.slices.casting",
    "druntime.slices.comparison",
    "druntime.slices.copying",
    "druntime.slices.equality",
    "druntime.typeinfo.base",
    "druntime.typeinfo.classes_interfaces",
    "druntime.typeinfo.common",
    "druntime.typeinfo.enums_tuples",
    "druntime.typeinfo.functions",
    "druntime.typeinfo.pointers",
    "druntime.typeinfo.primitives",
    "druntime.typeinfo.slices",
    "druntime.typeinfo.static_arrays",
    "druntime.typeinfo.structs",
    "druntime.typeinfo.structs_unions_vectors",
    "druntime.typeinfo.type_attributes",

    "ministd",
    "ministd.algorithm",
    "ministd.algorithm.move",
    "ministd.ascii",
    "ministd.conv",
    "ministd.conv.to",
    "ministd.conv.internal.to_string",
    "ministd.format",
    "ministd.format.parse",
    "ministd.format.write",
    "ministd.meta",
    "ministd.range.primitives",
    "ministd.string",
    "ministd.typecons",
    "ministd.typecons.appender",
    "ministd.typecons.heap",
    "ministd.typecons.heap_array",

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
        ct!("Running unittests for module " ~ TC.bold(moduleString) ~ ":").writeln;
        alias tests = __traits(getUnitTests, imported!moduleString);
        static foreach (alias test; tests)
        {{
            ct!("- Running unittest " ~ TC.blue(testName!test) ~ ":").write;
            (() @trusted => test())();
            ct!(TC.green("success")).writeln;
        }}
    }}
    // dfmt on
}
