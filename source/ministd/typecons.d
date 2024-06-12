module ministd.typecons;

/**
Defines a value paired with a distinctive "null" state that denotes
the absence of a value. If default constructed, a $(D
Nullable!T) object starts in the null state. Assigning it renders it
non-null. Calling `nullify` can nullify it again.

Practically `Nullable!T` stores a `T` and a `bool`.

See also:
    $(LREF apply), an alternative way to use the payload.
 */
struct Nullable(T)
{
    private union DontCallDestructorT
    {
        import std.traits : hasIndirections;
        static if (hasIndirections!T)
            T payload;
        else
            T payload = void;
    }

    private DontCallDestructorT _value = DontCallDestructorT.init;

    private bool _isNull = true;

    /**
     * Constructor initializing `this` with `value`.
     *
     * Params:
     *     value = The value to initialize this `Nullable` with.
     */
    this(inout T value) inout
    {
        _value.payload = value;
        _isNull = false;
    }

    static if (hasElaborateDestructor!T)
    {
        ~this()
        {
            if (!_isNull)
            {
                destroy(_value.payload);
            }
        }
    }

    static if (__traits(hasPostblit, T))
    {
        this(this)
        {
            if (!_isNull)
                _value.payload.__xpostblit();
        }
    }
    else static if (__traits(hasCopyConstructor, T))
    {
        this(ref return scope inout Nullable!T rhs) inout
        {
            _isNull = rhs._isNull;
            if (!_isNull)
                _value.payload = rhs._value.payload;
            else
                _value = DontCallDestructorT.init;
        }
    }

    /**
     * If they are both null, then they are equal. If one is null and the other
     * is not, then they are not equal. If they are both non-null, then they are
     * equal if their values are equal.
     */
    bool opEquals(this This, Rhs)(auto ref Rhs rhs)
    if (!is(CommonType!(This, Rhs) == void))
    {
        static if (is(This == Rhs))
        {
            if (_isNull)
                return rhs._isNull;
            if (rhs._isNull)
                return false;
            return _value.payload == rhs._value.payload;
        }
        else
        {
            alias Common = CommonType!(This, Rhs);
            return cast(Common) this == cast(Common) rhs;
        }
    }

    /// Ditto
    bool opEquals(this This, Rhs)(auto ref Rhs rhs)
    if (is(CommonType!(This, Rhs) == void) && is(typeof(this.get == rhs)))
    {
        return _isNull ? false : rhs == _value.payload;
    }

    ///
    @safe unittest
    {
        Nullable!int empty;
        Nullable!int a = 42;
        Nullable!int b = 42;
        Nullable!int c = 27;

        assert(empty == empty);
        assert(empty == Nullable!int.init);
        assert(empty != a);
        assert(empty != b);
        assert(empty != c);

        assert(a == b);
        assert(a != c);

        assert(empty != 42);
        assert(a == 42);
        assert(c != 42);
    }

    @safe unittest
    {
        // Test constness
        immutable Nullable!int a = 42;
        Nullable!int b = 42;
        immutable Nullable!int c = 29;
        Nullable!int d = 29;
        immutable e = 42;
        int f = 29;
        assert(a == a);
        assert(a == b);
        assert(a != c);
        assert(a != d);
        assert(a == e);
        assert(a != f);

        // Test rvalue
        assert(a == const Nullable!int(42));
        assert(a != Nullable!int(29));
    }

    // https://issues.dlang.org/show_bug.cgi?id=17482
    @system unittest
    {
        import std.variant : Variant;
        Nullable!Variant a = Variant(12);
        assert(a == 12);
        Nullable!Variant e;
        assert(e != 12);
    }

    size_t toHash() const @safe nothrow
    {
        static if (__traits(compiles, .hashOf(_value.payload)))
            return _isNull ? 0 : .hashOf(_value.payload);
        else
            // Workaround for when .hashOf is not both @safe and nothrow.
            return _isNull ? 0 : typeid(T).getHash(&_value.payload);
    }

    /**
     * Gives the string `"Nullable.null"` if `isNull` is `true`. Otherwise, the
     * result is equivalent to calling $(REF formattedWrite, std,format) on the
     * underlying value.
     *
     * Params:
     *     writer = A `char` accepting
     *     $(REF_ALTTEXT output range, isOutputRange, std, range, primitives)
     *     fmt = A $(REF FormatSpec, std,format) which is used to represent
     *     the value if this Nullable is not null
     * Returns:
     *     A `string` if `writer` and `fmt` are not set; `void` otherwise.
     */
    string toString()
    {
        import std.array : appender;
        auto app = appender!string();
        auto spec = singleSpec("%s");
        toString(app, spec);
        return app.data;
    }

    /// ditto
    string toString() const
    {
        import std.array : appender;
        auto app = appender!string();
        auto spec = singleSpec("%s");
        toString(app, spec);
        return app.data;
    }

    /// ditto
    void toString(W)(ref W writer, in FormatSpec!char fmt)
    if (isOutputRange!(W, char))
    {
        import std.range.primitives : put;
        if (isNull)
            put(writer, "Nullable.null");
        else
            formatValue(writer, _value.payload, fmt);
    }

    /// ditto
    void toString(W)(ref W writer, in FormatSpec!char fmt) const
    if (isOutputRange!(W, char))
    {
        import std.range.primitives : put;
        if (isNull)
            put(writer, "Nullable.null");
        else
            formatValue(writer, _value.payload, fmt);
    }

    /**
     * Check if `this` is in the null state.
     *
     * Returns:
     *     true $(B iff) `this` is in the null state, otherwise false.
     */
    @property bool isNull() const @safe pure nothrow
    {
        return _isNull;
    }

    ///
    @safe unittest
    {
        Nullable!int ni;
        assert(ni.isNull);

        ni = 0;
        assert(!ni.isNull);
    }

    // https://issues.dlang.org/show_bug.cgi?id=14940
    @safe unittest
    {
        import std.array : appender;
        import std.format.write : formattedWrite;

        auto app = appender!string();
        Nullable!int a = 1;
        formattedWrite(app, "%s", a);
        assert(app.data == "1");
    }

    // https://issues.dlang.org/show_bug.cgi?id=19799
    @safe unittest
    {
        import std.format : format;

        const Nullable!string a = const(Nullable!string)();

        format!"%s"(a);
    }

    /**
     * Forces `this` to the null state.
     */
    void nullify()()
    {
        static if (is(T == class) || is(T == interface))
            _value.payload = null;
        else
            .destroy(_value.payload);
        _isNull = true;
    }

    ///
    @safe unittest
    {
        Nullable!int ni = 0;
        assert(!ni.isNull);

        ni.nullify();
        assert(ni.isNull);
    }

    /**
     * Assigns `value` to the internally-held state. If the assignment
     * succeeds, `this` becomes non-null.
     *
     * Params:
     *     value = A value of type `T` to assign to this `Nullable`.
     */
    Nullable opAssign()(T value)
    {
        import std.algorithm.mutation : moveEmplace, move;

        // the lifetime of the value in copy shall be managed by
        // this Nullable, so we must avoid calling its destructor.
        auto copy = DontCallDestructorT(value);

        if (_isNull)
        {
            // trusted since payload is known to be uninitialized.
            () @trusted { moveEmplace(copy.payload, _value.payload); }();
        }
        else
        {
            move(copy.payload, _value.payload);
        }
        _isNull = false;
        return this;
    }

    /**
     * If this `Nullable` wraps a type that already has a null value
     * (such as a pointer), then assigning the null value to this
     * `Nullable` is no different than assigning any other value of
     * type `T`, and the resulting code will look very strange. It
     * is strongly recommended that this be avoided by instead using
     * the version of `Nullable` that takes an additional `nullValue`
     * template argument.
     */
    @safe unittest
    {
        //Passes
        Nullable!(int*) npi;
        assert(npi.isNull);

        //Passes?!
        npi = null;
        assert(!npi.isNull);
    }

    /**
     * Gets the value if not null. If `this` is in the null state, and the optional
     * parameter `fallback` was provided, it will be returned. Without `fallback`,
     * calling `get` with a null state is invalid.
     *
     * When the fallback type is different from the Nullable type, `get(T)` returns
     * the common type.
     *
     * Params:
     *     fallback = the value to return in case the `Nullable` is null.
     *
     * Returns:
     *     The value held internally by this `Nullable`.
     */
    @property ref inout(T) get() inout @safe pure nothrow
    {
        enum message = "Called `get' on null Nullable!" ~ T.stringof ~ ".";
        assert(!isNull, message);
        return _value.payload;
    }

    /// ditto
    @property inout(T) get()(inout(T) fallback) inout
    {
        return isNull ? fallback : _value.payload;
    }

    /// ditto
    @property auto get(U)(inout(U) fallback) inout
    {
        return isNull ? fallback : _value.payload;
    }

    /// $(MREF_ALTTEXT Range interface, std, range, primitives) functions.
    alias empty = isNull;

    /// ditto
    alias popFront = nullify;

    /// ditto
    alias popBack = nullify;

    /// ditto
    @property ref inout(T) front() inout @safe pure nothrow
    {
        return get();
    }

    /// ditto
    alias back = front;

    /// ditto
    @property inout(typeof(this)) save() inout
    {
        return this;
    }

    /// ditto
    inout(typeof(this)) opIndex(size_t[2] dim) inout
    in (dim[0] <= length && dim[1] <= length && dim[1] >= dim[0])
    {
        return (dim[0] == 0 && dim[1] == 1) ? this : this.init;
    }
    /// ditto
    size_t[2] opSlice(size_t dim : 0)(size_t from, size_t to) const
    {
        return [from, to];
    }

    /// ditto
    @property size_t length() const @safe pure nothrow
    {
        return !empty;
    }

    /// ditto
    alias opDollar(size_t dim : 0) = length;

    /// ditto
    ref inout(T) opIndex(size_t index) inout @safe pure nothrow
    in (index < length)
    {
        return get();
    }

    /**
     * Converts `Nullable` to a range. Works even when the contained type is `immutable`.
     */
    auto opSlice(this This)()
    {
        static struct NullableRange
        {
            private This value;

            // starts out true if value is null
            private bool empty_;

            @property bool empty() const @safe pure nothrow
            {
                return empty_;
            }

            void popFront() @safe pure nothrow
            {
                empty_ = true;
            }

            alias popBack = popFront;

            @property ref inout(typeof(value.get())) front() inout @safe pure nothrow
            {
                return value.get();
            }

            alias back = front;

            @property inout(typeof(this)) save() inout
            {
                return this;
            }

            size_t[2] opSlice(size_t dim : 0)(size_t from, size_t to) const
            {
                return [from, to];
            }

            @property size_t length() const @safe pure nothrow
            {
                return !empty;
            }

            alias opDollar(size_t dim : 0) = length;

            ref inout(typeof(value.get())) opIndex(size_t index) inout @safe pure nothrow
            in (index < length)
            {
                return value.get();
            }

            inout(typeof(this)) opIndex(size_t[2] dim) inout
            in (dim[0] <= length && dim[1] <= length && dim[1] >= dim[0])
            {
                return (dim[0] == 0 && dim[1] == 1) ? this : this.init;
            }

            auto opIndex() inout
            {
                return this;
            }
        }
        return NullableRange(this, isNull);
    }
}

/// ditto
auto nullable(T)(T t)
{
    return Nullable!T(t);
}