#!/usr/bin/env -S ldc2 -run
import std;
import std.format : f = format;

void run(string shellCommand)
{
    auto pid = spawnShell(shellCommand);
    enforce(pid.wait == 0);
}

struct Target
{
    string dubArch;
    string clangTarget;
}

Target[] targets = [
    {dubArch: "x86_64-pc-linux", clangTarget: "x86_64-pc-linux"},
    {dubArch: "i386-pc-linux"},
    {dubArch: "arm64-pc-linux"},
    {dubArch: "xtensa-unknown-elf"},
];

string[] configs = ["minimal", "classes", "classes-exceptions"];

void main()
{
    foreach (target; targets)
        foreach (config; configs)
        {
            writefln!"Testing configuration %s"(config);
            run(f!"dub build --arch=%s --config=%s --build=unittest --force"(target.dubArch, config));
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
