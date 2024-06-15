#!/usr/bin/env rdmd
import std;

void main()
{
    foreach (config; ["minimal", "classes", "classes-exceptions"])
    {
        writefln!"Testing configuration %s"(config);
        auto pid = spawnShell(format!"dub build --config=%s --build=unittest --force"(config));
        enforce(pid.wait == 0);
    }
}
