module fixedpoint.fixedpoint;

import std.conv : to;
import std.format : format;
import std.string : split;
import std.stdio;
import std.traits;

/// FixedPoint Class
struct FixedPoint(int scaling)
{
    /// Value of the FixedPoint
    long value = 0;
    /// Factor of the scaling
    enum factor = 10 ^^ scaling;

    //TODO opAsignment
    //TODO unittests
    //TODO init?

    /// Smalest FixedPoint
    static immutable FixedPoint min = make(long.min);
    /// Largest FixedPoint
    static immutable FixedPoint max = make(long.max);

    /// Create a new FixedPoint, given a number
    this(T)(T i) if (isNumeric!T)
    {
        value = to!long(i * factor);
    }
    ///
    unittest
    {
        auto p1 = FixedPoint!4(1);
        assert(p1.value == 1 * 10 ^^ 4);

        auto p2 = FixedPoint!4(1.1);
        assert(p2.value == 1.1 * 10 ^^ 4);

        auto p3 = FixedPoint!5(1);
        assert(p3.value == 1 * 10 ^^ 5);
    }

    /// Create a new FixPoint given a string
    this(string s)
    {
        if (s != "")
        {
            auto spl = s.split(".");
            value = to!long(spl[0]) * factor;
            if (spl.length > 1 && spl[1] != "")
            {
                if (spl[1].length > scaling)
                    value += to!long(spl[1]) / 10 ^^ (spl[1].length - scaling);
                else
                    value += to!long(spl[1]) * 10 ^^ (scaling - spl[1].length);
            }
        }
    }
    ///
    unittest
    {
        auto p1 = FixedPoint!4("1.1");
        assert(p1.value == 11_000);

        auto p2 = FixedPoint!4("1.");
        assert(p2.value == 10_000);

        auto p3 = FixedPoint!4("0");
        assert(p3.value == 0);

        auto p4 = FixedPoint!4("");
        assert(p4.value == 0);
    }

    /// Direct construction of a FixedPoint
    static pure nothrow FixedPoint make(long v)
    {
        FixedPoint fixed;
        fixed.value = v;
        return fixed;
    }
    ///
    unittest
    {
        auto p1 = FixedPoint!3.make(1);
        assert(p1.value = 1);

        auto p2 = FixedPoint!3(1);
        assert(p2.value = 1000);
    }

    string toString() const
    {
        return format!"%d.%0*d"(value / factor, scaling, value % factor);
    }

    /// Creating FixedPoint from a string, needed by vibed: http://vibed.org/api/vibe.data.serialization/isStringSerializable
    static FixedPoint fromString(string v)
    {
        return FixedPoint(v);
    }

    bool opEquals(const FixedPoint other) const
    {
        return other.value == value;
    }

    bool opEquals(point)(const FixedPoint!point other) const
    {
        return other.value * other.factor == value * factor;
    }

    bool opEquals(T)(T other) const if (isNumeric!T)
    {
        return value == other * factor;
    }

    int opCmp(const FixedPoint other) const
    {
        if (value < other.value)
            return -1;
        else if (value > other.value)
            return 1;
        else
            return 0;
    }

    //int opCmp(point)(const FixedPoint!point other) const
    //{
    //    //TODO
    //    return 0;
    //}

    int opCmp(T)(const T other) const if (isNumeric!T)
    {
        if (value < other * factor)
            return -1;
        else if (value > other * factor)
            return 1;
        else
            return 0;
    }

    unittest
    {
        auto p = FixedPoint!4(3);
        assert(p == FixedPoint!4(3));
        assert(p == 3.0);
        assert(p == 3);
        assert(p == FixedPoint!4(3));
        auto p2 = Fixed4(2);
        assert(p > p2);
        assert(p2 < p);
    }

    FixedPoint!scaling opUnary(string s)() if (s == "--" || s == "++")
    {
        mixin("value" ~ s[0] ~ "= factor;");
        return this;
    }

    FixedPoint!scaling opUnary(string s)() if (s == "-" || s == "+")
    {
        auto f = FixedPoint!scaling();
        f.value = mixin(s ~ "value");
        return f;
    }

    unittest
    {
        auto p = FixedPoint!1(1.1);
        assert(to!string(p) == "1.1");
        p++;
        ++p;
        assert(p.value == 31);
        assert((-p).value == -31);
    }

    //FixedPoint!point opCast(FixedPoint)() const
    //{
    //    return FixedPoint!point.make(value / 10 ^^ (abs(scaling - point)));
    //}

    T opCast(T)() const if (isNumeric!T)
    {
        return (to!T(value) / factor).to!T;
    }

    unittest
    {
        auto p = FixedPoint!4(1.1);
        assert(cast(int) p == 1);
        assert(to!int(p) == 1);
        assert(to!double(p) == 1.1);
    }

    FixedPoint!scaling opBinary(string op, T)(T rhs) if (isNumeric!T)
    {
        return FixedPoint!scaling.make(mixin("value" ~ op ~ "rhs * factor"));
    }

    FixedPoint!scaling opBinary(string op)(FixedPoint!scaling rhs)
            if (op == "+" || op == "-")
    {
        return FixedPoint!scaling.make(mixin("value" ~ op ~ "rhs.value"));
    }

/*
    FixedPoint!point opBinary(string op, point)(FixedPoint!point rhs) if (op == "+" || op == "-")
    {
        static if (scaling > point)
            return FixedPoint!point(mixin("(value * 10^^(scaling - point))" ~ op ~ "rhs.value"));
        else
            return FixedPoint!scaling(mixin("value" ~ op ~ "(rhs.value * 10^^(point - scaling))"));
    }

    FixedPoint opBinary(string op)(FixedPoint rhs) if (op == "*")
    {
        return FixedPoint(value * rhs.value, point + rhs.point);
    }
    */

    ///
    unittest
    {
        auto p1 = FixedPoint!4(1);
        auto p2 = FixedPoint!4(2);
        assert(p1 + 1 == 2);
        assert(p1 + p2 == 3);
        auto p3 = FixedPoint!2(2);
        //auto p4 = p2 + p3.to!Fixed4;
        //assert(p4 == 4);
        //assert(p4 == 4);
        //assert(p4 * p1 == 4);
    }

    size_t toHash() const
    {
        return value;
    }
}
