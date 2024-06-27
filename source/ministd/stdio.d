module ministd.stdio;

import druntime.libc_funcs : puts, putchar;

import ministd.algorithm : each;
import ministd.string : toStringz;

@safe @nogc:

void write(in char[] s = "")
{
    if (s && s.length)
    {
        if (s[$ - 1] == '\0')
            puts(&s[0]);
        else
            s.each!putchar;
    }
}

void writeln(in char[] s = "")
{
    write(s);
    putchar('\n');
}
