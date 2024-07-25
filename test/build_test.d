#!/usr/bin/env dub
/+ dub.sdl:
    name "build_test"
    dependency "argparse" version="~>1.3.0"
+/
import std;
import std.format : f = format;
import argparse;

enum libFileName = "libnobetterc.a";

enum BuildType
{
    local,
    idf,
}

struct Config
{
    @(NamedArgument.Required)
    BuildType buildType = BuildType.local;

    @(NamedArgument.Required)
    string dubConfig;

    @(NamedArgument.Optional)
    string dubBuild = "unittest";

    @(NamedArgument.Optional)
    string triple;

    @(NamedArgument.Optional)
    string dflags;

    @(NamedArgument.Optional)
    string idfTarget = "esp32";
}

void run(string shellCommand)
{
    auto pid = spawnShell(shellCommand);
    auto status = pid.wait;
    enforce(status == 0, f!"Command failed with exit code %d"(status));
}

mixin CLI!Config.main!((Config config)
{
    if (config.dflags)
        environment["DFLAGS"] = config.dflags;
    f!"dub build %(%s %)"({
        string[] args;
        args ~= "--root=..";
        args ~= f!"--config=%s"(config.dubConfig);
        args ~= f!"--build=%s"(config.dubBuild);
        if (config.triple)
            args ~= f!"--arch=%s"(config.triple);
        return args;
    }()).run;

    std.file.copy(
        f!"../%s"(libFileName),
        f!"./%s/%s"(config.buildType, libFileName)
    );

    if (config.buildType == BuildType.local)
    {
        f!"cc %(%s %)"({
            string[] args;
            args ~= f!"./%s/%s"(config.buildType, libFileName);
            args ~= f!"-o./%s/test"(config.buildType);
            if (config.triple)
                args ~= f!"--target=%s"(config.triple);
            return args;
        }()).run;
    }
    else
    {
        f!"cd idf && idf.py set-target %s && idf.py build"(config.idfTarget).run;
    }
});
