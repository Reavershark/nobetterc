module ministd.stdio;

import druntime.libc_funcs : puts, putchar;

import ministd.algorithm : each;
import ministd.conv : to;
import ministd.format : formattedWrite;
import ministd.range.primitives : equalUnqualElementTypes, isOutputRange;
import ministd.traits : Unqual;
import ministd.string : toStringz;

@safe @nogc:

void write(Args...)(in Args args)
{
    StdoutWriter writer;

    foreach (arg; args)
    {
        alias Arg = typeof(arg);

        static if (is(Unqual!Arg == char)) // Some char
            writer.put(arg);
        else static if (equalUnqualElementTypes!(Arg, char[])) // Some char[]
            writer.put(arg);
        else
            writer.put(arg.to!(char[]));
    }
}

void writeln(Args...)(in Args args)
    => write(args, '\n');

void writef(string fmt, Args...)(in Args args)
    => StdoutWriter().formattedWrite!fmt(args);

void writefln(string fmt, Args...)(in Args args)
    => StdoutWriter().formattedWrite!(fmt ~ '\n')(args);

private
struct StdoutWriter
{
nothrow @nogc:
    static assert(isOutputRange!(typeof(this), char));
    static assert(isOutputRange!(typeof(this), char[]));

static:
    void put(in char c)
    {
        putchar(c);
    }

    void put(in char[] s)
    {
        if (s && s.length)
        {
            if (s[$ - 1] == '\0')
                puts(&s[0]);
            else
                s.each!putchar;
        }
    }
}
