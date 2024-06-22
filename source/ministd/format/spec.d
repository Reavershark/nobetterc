module ministd.format.spec;

@safe pure nothrow @nogc:

import ministd.algorithm : startsWith;
import ministd.ascii : isDigit;
import ministd.conv : parse, text, to;
import ministd.range.primitives : empty, front, isOutputRange;
import ministd.traits : Unqual;

template FormatSpec(Char) //
if (!is(Unqual!Char == Char))
{
    alias FormatSpec = FormatSpec!(Unqual!Char);
}

/**
 * A general handler for format strings.
 * 
 * This handler centers around the function $(LREF writeUpToNextSpec),
 * which parses the $(MREF_ALTTEXT format string, std,format) until the
 * next format specifier is found. After the call, it provides
 * information about this format specifier in its numerous variables.
 * 
 * Params:
 *     Char = the character type of the format string
 */
struct FormatSpec(Char) //
if (is(Unqual!Char == Char))
{
    struct Flags
    {
        /// The format specifier contained a `'-'`.
        bool dash : 1;

        /// The format specifier contained a `'0'`.
        bool zero : 1;

        /// The format specifier contained a space.
        bool space : 1;

        /// The format specifier contained a `'+'`.
        bool plus : 1;

        /// The format specifier contained a `'#'`.
        bool hash : 1;

        /// The format specifier contained a `'='`.
        bool equal : 1;

        /// The format specifier contained a `','`.
        bool separator : 1;

        static assert(typeof(this).sizeof == 1);
    }

    /**
     * Special value for `width`, `precision` and `separators`.
     *
     * It flags that these values will be passed at runtime through
     * variadic arguments.
     */
    enum int DYNAMIC = int.max;

    /**
     * Special value for `precision` and `separators`.
     *
     * It flags that these values have not been specified.
     */
    enum int UNSPECIFIED = DYNAMIC - 1;

    /// Sequence `"["` inserted before each range or range like structure.
    enum immutable(Char)[] seqBefore = "[";

    /// Sequence `"]"` inserted after each range or range like structure.
    enum immutable(Char)[] seqAfter = "]";

    /**
     * Sequence `":"` inserted between element key and element value of
     * an associative array.
     */
    enum immutable(Char)[] keySeparator = ":";

    /**
     * Sequence `", "` inserted between elements of a range, a range like
     * structure or the elements of an associative array.
     */
    enum immutable(Char)[] seqSeparator = ", ";

    /**
     * Minimum width.
     *
     * _Default: `0`.
     */
    int width = 0;

    /**
     * Precision. Its semantic depends on the format character.
     *
     * See $(MREF_ALTTEXT format string, std,format) for more details.
     * _Default: `UNSPECIFIED`.
     */
    int precision = UNSPECIFIED;

    /**
     * Number of elements between separators.
     *
     * _Default: `UNSPECIFIED`.
     */
    int separators = UNSPECIFIED;

    /**
     * The separator charactar is supplied at runtime.
     *
     * _Default: false.
     */
    bool dynamicSeparatorChar = false;

    /**
     * Character to use as separator.
     *
     * _Default: `','`.
     */
    dchar separatorChar = ',';

    /**
     * The format character.
     *
     * _Default: `'s'`.
     */
    char spec = 's';

    /**
     * Index of the argument for positional parameters.
     *
     * Counting starts with `1`. Set to `0` if not used. Default: `0`.
     */
    ubyte indexStart;

    /**
     * Index of the last argument for positional parameter ranges.
     *
     * Counting starts with `1`. Set to `0` if not used. Default: `0`.
     */
    ubyte indexEnd;

    Flags flags;

    /// The inner format string of a nested format specifier.
    const(Char)[] nested;

    /**
     * The separator of a nested format specifier.
     *
     * `null` means, there is no separator. `empty`, but not `null`,
     * means zero length separator.
     */
    const(Char)[] sep;

    /// Contains the part of the format string, that has not yet been parsed.
    const(Char)[] trailing;

// scope:

    /**
     * Creates a new `FormatSpec`.
     *
     * The string is lazily evaluated. That means, nothing is done,
     * until $(LREF writeUpToNextSpec) is called.
     *
     * Params:
     *     fmt = a $(MREF_ALTTEXT format string, std,format)
     */
    this(in Char[] fmt)
    {
        trailing = fmt;
    }

    /**
     * Writes the format string to an output range until the next format
     * specifier is found and parse that format specifier.
     *
     * See the $(MREF_ALTTEXT description of format strings, std,format) for more
     * details about the format specifier.
     *
     * Params:
     *     writer = an $(REF_ALTTEXT output range, isOutputRange, std, range, primitives),
     *              where the format string is written to
     *     OutputRange = type of the output range
     *
     * Returns:
     *     True, if a format specifier is found and false, if the end of the
     *     format string has been reached.
     *
     * Throws:
     *     A $(REF_ALTTEXT FormatException, FormatException, std,format)
     *     when parsing the format specifier did not succeed.
     */
    bool writeUpToNextSpec(OutputRange)(ref OutputRange writer) //
    if (isOutputRange!OutputRange)
    {
        if (trailing.empty)
            return false;

        for (size_t i = 0; i < trailing.length; ++i)
            if (trailing[i] == '%')
            {
                // Write and drop the previous chars
                writer.put(trailing[0 .. i]);
                trailing = trailing[i .. $];

                // Drop the %
                assert(trailing.length >= 2, `Unterminated format specifier: "%"`);
                trailing = trailing[1 .. $];

                if (trailing[0] == '%')
                {
                    // Found the second % of a %%, keep this one for writing %
                    i = 0;
                    continue;
                }
                else
                {
                    // Found a spec, read it and set struct fields.
                    readFormatSpecifier;
                    return true;
                }
            }

        // No format spec found
        writer.put(trailing);
        trailing = [];

        return false;
    }

    /**
     * Reads the format specifier without leading %, that's currently at the start of `trailing`.
     * Sets the fields in this struct to represent that format spec.
     */
    private
    void readFormatSpecifier()
    {
        // Reset content
        width = 0;
        precision = UNSPECIFIED;
        nested = null;
        flags = flags.init;

        // Parse the spec (we assume we're past '%' already)
        for (size_t i = 0; i < trailing.length;)
        {
            switch (trailing[i])
            {
            case '(':
                // Embedded format specifier.
                auto j = i + 1;
                // Get the matching balanced paren
                for (uint innerParens;;)
                {
                    assert(j + 1 < trailing.length, text("Incorrect format specifier: %", trailing[i .. $]));
                    if (trailing[j++] != '%')
                    {
                        // skip, we're waiting for %( and %)
                        continue;
                    }
                    if (trailing[j] == '-') // for %-(
                    {
                        ++j; // skip
                        assert(j < trailing.length, text("Incorrect format specifier: %", trailing[i .. $]));
                    }
                    if (trailing[j] == ')')
                    {
                        if (innerParens-- == 0)
                            break;
                    }
                    else if (trailing[j] == '|')
                    {
                        if (innerParens == 0)
                            break;
                    }
                    else if (trailing[j] == '(')
                    {
                        ++innerParens;
                    }
                }
                if (trailing[j] == '|')
                {
                    auto k = j;
                    for (++j;;)
                    {
                        if (trailing[j++] != '%')
                            continue;
                        if (trailing[j] == '%')
                            ++j;
                        else if (trailing[j] == ')')
                            break;
                        else
                            assert(false, text("Incorrect format specifier: %", trailing[j .. $]));
                    }
                    nested = trailing[i + 1 .. k - 1];
                    sep = trailing[k + 1 .. j - 1];
                }
                else
                {
                    nested = trailing[i + 1 .. j - 1];
                    sep = null; // no separator
                }
                //this = FormatSpec(innerTrailingSpec);
                spec = '(';
                // We practically found the format specifier
                trailing = trailing[j + 1 .. $];
                return;
            case '-':
                flags.dash = true;
                ++i;
                break;
            case '+':
                flags.plus = true;
                ++i;
                break;
            case '=':
                flags.equal = true;
                ++i;
                break;
            case '#':
                flags.hash = true;
                ++i;
                break;
            case '0':
                flags.zero = true;
                ++i;
                break;
            case ' ':
                flags.space = true;
                ++i;
                break;
            case '*':
                if (isDigit(trailing[++i]))
                {
                    // a '*' followed by digits and '$' is a
                    // positional format
                    trailing = trailing[1 .. $];
                    width = -parse!(typeof(width))(trailing);
                    i = 0;
                    assert(trailing[i++] == '$', text("$ expected after '*", -width, "' in format string"));
                }
                else
                {
                    // read result
                    width = DYNAMIC;
                }
                break;
            case '1': .. case '9':
                auto tmp = trailing[i .. $];
                const widthOrArgIndex = parse!uint(tmp);
                assert(tmp.length,
                    text("Incorrect format specifier %", trailing[i .. $]));
                i = trailing.length - tmp.length;
                if (tmp.startsWith('$'))
                {
                    // index of the form %n$
                    indexEnd = indexStart = to!ubyte(widthOrArgIndex);
                    ++i;
                }
                else if (tmp.startsWith(':'))
                {
                    // two indexes of the form %m:n$, or one index of the form %m:$
                    indexStart = to!ubyte(widthOrArgIndex);
                    tmp = tmp[1 .. $];
                    if (tmp.startsWith('$'))
                    {
                        indexEnd = indexEnd.max;
                    }
                    else
                    {
                        indexEnd = parse!(typeof(indexEnd))(tmp);
                    }
                    i = trailing.length - tmp.length;
                    assert(trailing[i++] == '$',
                        "$ expected");
                }
                else
                {
                    // width
                    width = to!int(widthOrArgIndex);
                }
                break;
            case ',':
                // Precision
                ++i;
                flags.separator = true;

                if (trailing[i] == '*')
                {
                    ++i;
                    // read result
                    separators = DYNAMIC;
                }
                else if (isDigit(trailing[i]))
                {
                    auto tmp = trailing[i .. $];
                    separators = parse!int(tmp);
                    i = trailing.length - tmp.length;
                }
                else
                {
                    // "," was specified, but nothing after it
                    separators = 3;
                }

                if (trailing[i] == '?')
                {
                    dynamicSeparatorChar = true;
                    ++i;
                }

                break;
            case '.':
                // Precision
                if (trailing[++i] == '*')
                {
                    if (isDigit(trailing[++i]))
                    {
                        // a '.*' followed by digits and '$' is a
                        // positional precision
                        trailing = trailing[i .. $];
                        i = 0;
                        precision = -parse!int(trailing);
                        assert(trailing[i++] == '$',
                            "$ expected");
                    }
                    else
                    {
                        // read result
                        precision = DYNAMIC;
                    }
                }
                else if (trailing[i] == '-')
                {
                    // negative precision, as good as 0
                    precision = 0;
                    auto tmp = trailing[i .. $];
                    parse!int(tmp); // skip digits
                    i = trailing.length - tmp.length;
                }
                else if (isDigit(trailing[i]))
                {
                    auto tmp = trailing[i .. $];
                    precision = parse!int(tmp);
                    i = trailing.length - tmp.length;
                }
                else
                {
                    // "." was specified, but nothing after it
                    precision = 0;
                }
                break;
            default:
                // this is the format char
                spec = cast(char) trailing[i++];
                trailing = trailing[i .. $];
                return;
            } // end switch
        } // end for
        assert(false, text("Incorrect format specifier: ", trailing));
    }
}

/**
 * Helper function that returns a `FormatSpec` for a single format specifier.
 * 
 * Params:
 *     fmt = a $(MREF_ALTTEXT format string, std,format)
 *           containing a single format specifier
 *     Char = character type of `fmt`
 * 
 * Returns:
 *     A $(LREF FormatSpec) with the format specifier parsed.
 * 
 * Throws:
 *     A $(REF_ALTTEXT FormatException, FormatException, std,format) when the
 *     format string contains no format specifier or more than a single format
 *     specifier or when the format specifier is malformed.
 */
FormatSpec!Char singleSpec(Char)(Char[] fmt)
{
    assert(fmt.length >= 2, "fmt must be at least 2 characters long");
    assert(fmt.front == '%', "fmt must start with a '%' character");
    assert(fmt[1] != '%', "'%%' is not a permissible format specifier");

    static struct DummyOutputRange
    {
        void put(C)(scope const C[] buf)
        {
        } // eat elements
    }

    auto a = DummyOutputRange();
    auto spec = FormatSpec!Char(fmt);
    //dummy write
    spec.writeUpToNextSpec(a);

    assert(spec.trailing.empty, text("Trailing characters in fmt string: '", spec.trailing));

    return spec;
}

@("FormatSpec")
unittest
{
    auto spec = FormatSpec!char("%s%d%f");
}
