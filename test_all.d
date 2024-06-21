#!/usr/bin/env -S ldc2 -run
import std;
import std.format : f = format;

void run(string shellCommand)
{
    auto pid = spawnShell(shellCommand);
    auto status = pid.wait;
    enforce(status == 0, f!"Command failed with exit code %d"(status));
}

struct Target
{
    string dubArch;
    string clangTarget;
}

Target[] targets = [
    {dubArch: "x86_64-pc-linux", clangTarget: "x86_64-pc-linux"},
    // {dubArch: "i386-pc-linux"},
    // {dubArch: "arm64-pc-linux"},
    // {dubArch: "xtensa-unknown-elf"},
];

string[] configs = [
    "classes-exceptions",
    "classes",
    "minimal",
];

void main()
{
    foreach (target; targets)
        foreach (config; configs)
        {
            writefln!"Testing configuration %s"(config);
            run(f!"dub build --arch=%s --config=%s --build=unittest"(target.dubArch, config));
            if (target.clangTarget)
            {
                run(f!"clang libnobetterc.a -otest -target %s"(target.clangTarget));
                run("./test");
            }
            else
            {
                writeln("Skipping linking & running");
            }
        }
}
