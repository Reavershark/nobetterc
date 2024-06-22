module ministd.ascii;

@safe pure nothrow @nogc:

/**
 * Params: c = The character to test.
 * Returns: Whether `c` is a digit (0 .. 9).
 */
bool isDigit(in dchar c)
    => '0' <= c && c <= '9';
