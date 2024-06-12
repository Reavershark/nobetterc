module app.main;

// dfmt off
version (unittest) {}
else:
// dfmt on

@safe:

extern (C)
void main()
{
    class C{}
    C c = new C();
}
