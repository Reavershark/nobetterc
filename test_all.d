#!/usr/bin/env rdmd
import std;

static immutable VersionSets = [
    [
        "DRuntimeAssertion",
        "DRuntimeExternLibcFuncs",
    ],
    [
        "DRuntimeAssertion",
        "DRuntimeClassesAndTypeInfo",
        "DRuntimeExternLibcFuncs",
    ],
    [
        "DRuntimeAssertion",
        "DRuntimeClassesAndTypeInfo",
        "DRuntimeExceptions",
        "DRuntimeExceptionsImplSimpleNoCatch",
        "DRuntimeExternLibcFuncs",
    ],
];

void main()
{
    foreach (versionSet; VersionSets)
    {
        writefln!"Testing %s"(versionSet);
        auto pid = spawnShell(format!"dub build --force --build=unittest %(--d-version=%s %)"(versionSet));
        enforce(pid.wait == 0);
    }
}
