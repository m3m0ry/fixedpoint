module fixedpoint.fixed;

import std.conv : to, parse;
import std.algorithm : splitter;
import std.range : repeat, chain, empty;
import std.format : format, formattedWrite;
import std.string : split;
import std.math : sgn, abs, round;
import std.traits : isIntegral, isFloatingPoint, isNumeric, isNarrowString, hasMember;

//TODO opCmp & opEals between different Fixed types, modulo, power, ceil, floor, init test, documentation&examples

/// Fixed Class
struct Fixed(int scaling, V = long, Hook = KeepScalingHook) if (isIntegral!V)
{
    /// Value of the Fixed
    V value = V.init;
    /// Factor of the scaling
    enum factor = 10 ^^ scaling;
    /// Smalest Fixed
    static immutable Fixed min = make(V.min);
    /// Largest Fixed
    static immutable Fixed max = make(V.max);

    /// Create a new Fixed, given an integral
    this(const V i)
    {
        value = i * factor;
    }
    ///
    unittest
    {
        auto p1 = Fixed!4(1);
        assert(p1.value == 1 * 10 ^^ 4);

        auto p2 = Fixed!5(1);
        assert(p2.value == 1 * 10 ^^ 5);
    }

    /// Create a new Fixed give a floating point number
    this(T)(const T i) if (isFloatingPoint!T)
    {
        value = (i * factor).round.to!V;
    }
    ///
    unittest
    {
        auto p = Fixed!4(1.1);
        assert(p.value == 1.1 * 10 ^^ 4);
    }

    /// Create a new Fixed struct given a string. If round is true, then the number is rounded to the nearest signficiant digit.
    this(Range)(Range s, bool round = false) if (isNarrowString!Range)
    {
        if (!s.empty)
        {
            import std.range.primitives;
            auto spl = s.splitter(".");
            auto frontItem = spl.front;
            spl.popFront;
            bool neg = frontItem.length > 0 && frontItem.front == '-';
            typeof(frontItem) decimal;
            typeof(frontItem) truncatedDecimal;
            if (!spl.empty)
                decimal = spl.front;
            if (decimal.length > scaling)
                truncatedDecimal = decimal[0 .. scaling]; // truncate
            else
                truncatedDecimal = decimal;
            value = chain(frontItem, truncatedDecimal, '0'.repeat(scaling - truncatedDecimal.length)).to!V;
            if(round && decimal.length > scaling && decimal[scaling] >= '5')
            {
                if(neg)
                    --value;
                else
                    ++value;
            }
        }
    }
    ///
    unittest
    {
        auto p1 = Fixed!4("1.1");
        assert(p1.value == 11_000);

        auto p2 = Fixed!4("1.");
        assert(p2.value == 10_000);

        auto p3 = Fixed!4("0");
        assert(p3.value == 0);

        auto p4 = Fixed!4("");
        assert(p4.value == 0);

        auto p5 = Fixed!3("1.2345", true);
        assert(p5.value == 1235);
    }

    /// Direct construction of a Fixed struct
    static pure nothrow Fixed make(const V v)
    {
        Fixed fixed;
        fixed.value = v;
        return fixed;
    }
    ///
    unittest
    {
        auto p1 = Fixed!3.make(1);
        assert(p1.value == 1);

        auto p2 = Fixed!3(1);
        assert(p2.value == 1000);
    }

    Fixed opAssign(const Fixed p)
    {
        value = p.value;
        return this;
    }

    Fixed opAssign(T)(const T n) if (isNumeric!T)
    {
        value = to!V(n * factor);
        return this;
    }

    Fixed opAssign(string s)
    {
        value = Fixed(s).value;
        return this;
    }

    Fixed opOpAssign(string op, T)(const T n)
    {
        // just forward to opBinary.
        return this = opBinary!op(n);
    }

    string toString() const
    {
        string sign = value.sgn == -1 ? "-" : "";
        return format!"%s%d.%0*d"(sign, (value / factor).abs, scaling, (value % factor).abs);
    }

    void toString(Out)(auto ref Out outRange) const if (is(typeof(formattedWrite!"test"(outRange))))
    {
        string sign = value.sgn == -1 ? "-" : "";
        outRange.formattedWrite!"%s%d.%0*d"(sign, (value / factor).abs, scaling, (value % factor).abs);
    }

    /// Creating Fixed from a string, needed by vibed: http://vibed.org/api/vibe.data.serialization/isStringSerializable
    static Fixed fromString(string v)
    {
        return Fixed(v);
    }

    bool opEquals(const Fixed other) const
    {
        return other.value == value;
    }

    bool opEquals(point)(const Fixed!point other) const
    {
        return other.value * other.factor == value * factor;
    }

    bool opEquals(T)(const T other) const if (isIntegral!T)
    {
        return value == other * factor;
    }

    int opCmp(const Fixed other) const
    {
        if (value < other.value)
            return -1;
        else if (value > other.value)
            return 1;
        else
            return 0;
    }

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
        auto p = Fixed!4(3);
        assert(p == Fixed!4(3));
        //assert(p == 3.0);
        assert(p == 3);
        assert(p == Fixed!4(3));
        auto p2 = Fixed!4(2);
        assert(p > p2);
        assert(p2 < p);
    }

    Fixed opUnary(string s)() if (s == "--" || s == "++")
    {
        mixin("value" ~ s[0] ~ "= factor;");
        return this;
    }

    Fixed opUnary(string s)() const if (s == "-" || s == "+")
    {
        auto f = Fixed();
        f.value = mixin(s ~ "value");
        return f;
    }

    unittest
    {
        auto p = Fixed!1(1.1);
        assert(to!string(p) == "1.1");
        p++;
        ++p;
        assert(p.value == 31);
        assert((-p).value == -31);
    }

    T opCast(T : Fixed!(point, U), int point, U)() const
    {
        static if (point > scaling)
            return T.make(value.to!U * (10 ^^ (point - scaling)));
        else static if (point < scaling)
            return T.make(value.to!U / (10 ^^ (scaling - point)));
        else
            return this;
    }

    T opCast(T : bool)() const
    {
        return value != 0;
    }

    T opCast(T)() const if (isNumeric!T)
    {
        return (value.to!T / factor).to!T;
    }

    unittest
    {
        auto p = Fixed!4(1.1);
        assert(cast(int) p == 1);
        assert(p.to!int == 1);
        assert(p.to!double == 1.1);
        assert(p.to!(Fixed!5).value == 110_000);
    }

    ///
    auto opBinary(string op, Rhs)(const Rhs rhs) const 
            if (isIntegral!Rhs || isFloatingPoint!Rhs || is(Rhs == bool))
    {
        static if (hasMember!(Hook, "hookOpBinaryNumeric"))
            return hook.hookOpBinaryNumeric!op(this, rhs);
        else static if (is(Rhs == bool))
            return mixin("this" ~ op ~ "ubyte(rhs)");
        else static if (isFloatingPoint!Rhs)
            return mixin("this.to!Rhs" ~ op ~ "rhs");
        else static if (isIntegral!Rhs)
        {
            static if (op == "+" || op == "-")
                return Fixed.make(mixin("value" ~ op ~ "(rhs * factor)"));
            else static if (op == "*" || op == "/")
                return Fixed.make(mixin("value" ~ op ~ "rhs"));
            else
                static assert(0, "Operation " ~ op ~ " is not (yet) implemented");
        }
    }

    ///
    auto opBinary(string op, int S, W, H)(Fixed!(S, W, H) rhs) const
    {
        static if (is(Hook == H) && hasMember!(H, "hookOpBinaryFixed"))
            return Hook.hookOpBinaryFixed!(op, scaling, V, Hook, S, W, H)(this, rhs);
        else static if (hasMember!(Hook, "hookOpBinaryFixed")
                && !hasMember!(H, "hookOpBinaryFixed"))
            return Hook.hookOpBinaryFixed!op(this, rhs);
        else static if (!hasMember!(Hook, "hookOpBinaryFixed")
                && hasMember!(H, "hookOpBinaryFixed"))
            return H.hookOpBinaryFixed!op(this, rhs);
        else
            static assert(0, "Conflict between Hooks");
    }

    ///
    auto opBinaryRight(string op, Lhs)(const Lhs lhs) const 
            if (isIntegral!Lhs || isFloatingPoint!Lhs || is(Lhs == bool))
    {
        static if (hasMember!(Hook, "hookOpBinaryRightNumeric"))
            return hook.hookOpBinaryRightNumeric!op(lhs, this);
        else static if (is(Lhs == bool))
            return mixin("ubyte(rhs)" ~ op ~ "this");
        else static if (isFloatingPoint!Lhs)
            return mixin("lhs" ~ op ~ "this.to!Lhs");
        else static if (isIntegral!Lhs)
        {
            static if (op == "+" || op == "-")
                return Fixed.make(mixin("(lhs * factor)" ~ op ~ "value"));
            else static if (op == "*")
                return Fixed.make(mixin("lhs" ~ op ~ "value"));
            else static if (op == "/")
                return Fixed.make(mixin("(lhs * factor * factor)" ~ op ~ "value"));
            else
                static assert(0, "Operation " ~ op ~ " is not (yet) implemented");
        }
    }

    ///
    unittest
    {
        auto p1 = Fixed!4(1);
        auto p2 = Fixed!4(2);
        assert(p1 + 1 == 2);
        assert(p1 + p2 == 3);
        assert(p1 * 2 == 2);
        assert(cast(double)(p1 / 2) == 0.5);
        auto p3 = Fixed!2(2);
        auto p4 = p2 + p3.to!(Fixed!4);
        assert(p4 == 4);
    }

    size_t toHash() const
    {
        return value.hashOf;
    }
}

///
struct KeepScalingHook
{
    ///
    static auto hookOpBinaryFixed(string op, int scaling, V, Hook, int S, W, H)(
            const Fixed!(scaling, V, Hook) lhs, const Fixed!(S, W, H) rhs)
            if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        static if (is(typeof(lhs) == typeof(rhs)))
        {
            static if (op == "+" || op == "-")
                return typeof(lhs).make(mixin("lhs.value" ~ op ~ "rhs.value"));
            else static if (op == "*")
                return typeof(lhs).make(((lhs.value * rhs.value) / lhs.factor).round.to!V);
            else static if (op == "/")
                return typeof(lhs).make(((lhs.value * lhs.factor) / rhs.value).round.to!V);
        }
        else
        {
            static if (scaling > S)
                alias nextScaling = scaling;
            else
                alias nextScaling = S;
            static if (V.sizeof > W.sizeof)
                alias nextV = V;
            else
                alias nextV = W;
            alias common = Fixed!(nextScaling, nextV, Hook);
            return mixin("lhs.to!common" ~ op ~ "rhs.to!common");
        }
    }
}

///
struct MoveScalingHook
{
    ///
    static auto hookOpBinaryFixed(string op, int scaling, V, Hook, int S, W, H)(
            const Fixed!(scaling, V, Hook) lhs, const Fixed!(S, W, H) rhs)
            if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        static if (is(typeof(lhs) == typeof(rhs)))
        {
            static if (op == "+" || op == "-")
                return typeof(lhs).make(mixin("lhs.value" ~ op ~ "rhs.value"));
            else static if (op == "*")
                return Fixed!(2 * scaling, V, Hook).make((lhs.value * rhs.value).round.to!V);
            else static if (op == "/")
                return Fixed!(0, V, Hook).make((lhs.value / rhs.value).round.to!V);
        }
        else
        {
            static if (V.sizeof > W.sizeof)
                alias nextV = V;
            else
                alias nextV = W;

            static if (op == "+" || op == "-")
            {
                static if (scaling > S)
                    alias nextScaling = scaling;
                else
                    alias nextScaling = S;
                alias common = Fixed!(nextScaling, nextV, Hook);
                return mixin("lhs.to!common" ~ op ~ "rhs.to!common");
            }
            else static if (op == "*")
            {
                return Fixed!(scaling + S, nextV, Hook).make(value * rhs.value);
                return Fixed!(scaling - S, nextV, Hook).make(value / rhs.value);

            }
        }
    }
}

unittest
{
    import std.stdio : writeln;
    import std.math : isClose;
    import std.exception : assertThrown;

    alias fix1 = Fixed!1;
    alias fix2 = Fixed!2;
    alias fix3 = Fixed!3;

    // Fundamentals

    assert(fix1.factor == 10);
    assert(fix2.factor == 100);
    assert(fix3.factor == 1000);
    assert(fix1.min.value == long.min);
    assert(fix1.max.value == long.max);
    assert(fix2.min.value == long.min);
    assert(fix2.max.value == long.max);
    assert(fix3.min.value == long.min);
    assert(fix3.max.value == long.max);

    // Default

    fix2 amount;
    assert(amount.value == 0);
    assert(amount.toString() == "0.00");

    // Creation

    fix1 v1 = 14;
    assert(v1.value == 140);
    fix2 v2 = -23.45;
    assert(v2.value == -2345);
    fix3 v3 = "134";
    assert(v3.value == 134_000);
    fix3 v4 = "134.5";
    assert(v4.value == 134_500);

    auto v5 = fix1("22");
    assert(v5.value == 220);

    assert(fix1(62).value == 620);
    assert(fix2(-30).value == -3000);
    assert(fix3("120").value == 120_000);
    assert(fix3("120".dup).value == 120_000);
    assert(fix3("120.123").value == 120_123);
    assert(fix3("120.1234").value == 120_123);
    assert(fix3("120.1", true).value == 120_100);
    assert(fix3("120.12", true).value == 120_120);
    assert(fix3("120.123", true).value == 120_123);
    assert(fix3("120.1234", true).value == 120_123);
    assert(fix3("120.1235", true).value == 120_124);
    assert(fix3("120.12349", true).value == 120_123);
    assert(fix3("120.12359", true).value == 120_124);
    assert(fix3("120.12340", true).value == 120_123);
    assert(fix3("120.12350", true).value == 120_124);
    assertThrown(Fixed!10("12345678901234567"));
    assert(fix2(24.6).value == 2460);
    assert(fix2(-27.2).value == -2720);
    assert(fix2(16.1f).value == 1610);
    assert(fix2(-87.3f).value == -8730);

    // test negative rounding
    assert(fix2("-1.005", true).value == -101);

    int i1 = 23;
    v2 = i1;
    assert(v2.value == 2300);

    i1 = -15;
    v1 = i1;
    assert(v1.value == -150);

    long l1 = 435;
    v2 = l1;
    assert(v2.value == 43_500);

    l1 = -222;
    v3 = l1;
    assert(v3.value == -222_000);

    // Assignment

    amount = 20;
    assert(amount.value == 2000);
    amount = -30L;
    assert(amount.value == -3000);
    amount = 13.6f;
    assert(amount.value == 1360);
    amount = 7.3;
    assert(amount.value == 730);
    amount = "-30.7";
    assert(amount.value == -3070);

    // Comparison operators

    amount = 30;

    assert(amount == 30);
    assert(amount != 22);
    assert(amount <= 30);
    assert(amount >= 30);
    assert(amount > 29);
    assert(!(amount > 31));
    assert(amount < 31);
    assert(!(amount < 29));

    amount = 22.34;

    assert(amount.value == 2234);
    assert(amount != 1560);
    assert(amount <= 22.34);
    assert(amount >= 22.34);
    assert(amount > 22.33);
    assert(!(amount > 22.35));
    assert(amount < 22.35);
    assert(!(amount < 22.33));

    fix2 another = 22.34;
    assert(amount == another);
    assert(amount <= another);
    assert(amount >= another);

    another = 22.35;
    assert(amount != another);
    assert(amount < another);
    assert(amount <= another);
    assert(!(amount > another));
    assert(!(amount >= another));
    assert(another > amount);
    assert(another >= amount);
    assert(!(another < amount));
    assert(!(another <= amount));

    // Cast and conversion

    amount = 22;
    long lVal = cast(long) amount;
    assert(lVal == 22);
    double dVal = cast(double) amount;
    assert(dVal == 22.0);
    assert(dVal == amount.to!double);
    assert(dVal * dVal == amount.to!double * amount.to!double);
    assert(amount.toString() == "22.00");
    assert(fix2(0.15).toString() == "0.15");
    assert(fix2(-0.02).toString() == "-0.02");
    assert(fix2(-43.6).toString() == "-43.60");
    assert(fix2.min.toString() == "-92233720368547758.08");
    assert(fix2.max.toString() == "92233720368547758.07");
    bool bVal = cast(bool) amount;
    assert(bVal == true);
    assert(amount);
    assert(!fix2(0));

    auto cv1 = amount.to!(Fixed!1);
    assert(cv1.factor == 10);
    assert(cv1.value == 220);
    auto cv3 = amount.to!(Fixed!3);
    assert(cv3.factor == 1000);
    assert(cv3.value == 22_000);

    fix3 amt3 = 3.752;
    auto amt2 = amt3.to!(Fixed!2);
    assert(amt2.factor == 100);
    assert(amt2.value == 375);
    auto amt1 = amt3.to!(Fixed!1);
    assert(amt1.factor == 10);
    assert(amt1.value == 37);
    auto amt0 = amt3.to!(Fixed!0);
    assert(amt0.factor == 1);
    assert(amt0.value == 3);

    // Arithmmetic operators

    fix2 op1, op2;
    fix3 op3;

    op1 = 5.23;
    op2 = 7.1;
    op3 = 1.337;

    assert((op1 + op2).value == 1233);
    assert((op1 - op2).value == -187);
    assert((op1 * op2).value == 3713);
    assert((op1 / op2).value == 73);
    assert((op3 + op2).value == 8437);
    assert((op3 - op2).value == -5763);
    assert((op3 * op2).value == 9492);
    assert((op3 / op2).value == 188);
    assert((op2 + op3).value == 8437);
    assert((op2 + op3).value == (op3 + op2).value);
    assert((op2 - op3).value == 5763);
    assert((op2 - op3).value == -(op3 - op2).value);
    assert((op2 * op3).value == 9492);
    assert((op2 * op3).value == (op3 * op2).value);
    assert((op2 / op3).value == 5310);

    assert((op1 + 10).value == 1523);
    assert((op1 - 10).value == -477);
    assert((op1 * 10).value == 5230);
    assert((op1 / 10).value == 52);
    //assert(op1 % 10 == 5.23);

    assert((10 + op1).value == 1523);
    assert((10 - op1).value == 477);
    assert((10 * op1).value == 5230);
    assert((10 / op1).value == 191);
    //assert(10 % op1 == 4.77);

    assert(isClose(op1 + 9.8, 15.03));
    assert(isClose(op1 - 9.8, -4.57));
    assert(isClose(op1 * 9.8, 51.254));
    assert(isClose(op1 / 9.8, 0.53367346939));

    assert(isClose(9.8 + op1, 15.03));
    assert(isClose(9.8 - op1, 4.57));
    assert(isClose(9.8 * op1, 51.254));
    assert(isClose(9.8 / op1, 1.87380497132));

    assert(op1 != op2);
    assert(op1 == fix2(5.23));
    assert(op2 == fix2("7.1"));
    assert(op2 != fix2("7.09"));
    assert(op2 != fix2("7.11"));

    // Increment, decrement

    amount = 20;
    assert(++amount == 21);
    assert(amount == 21);
    assert(--amount == 20);
    assert(amount == 20);
    assert(-amount == -20);
    assert(amount == 20);

    amount = amount + 14;
    assert(amount.value == 3400);

    amount = 6 + amount;
    assert(amount.value == 4000);

    // Assignment operators.

    amount = 40;

    amount += 5;
    assert(amount.value == 4500);

    amount -= 6.5;
    assert(amount.value == 3850);

    another = -4;

    amount += another;
    assert(amount.value == 3450);

    amount *= 1.5;
    assert(amount.value == 5175);

    amount /= 12;
    assert(amount.value == 431);

    assert(Fixed!2.fromString("2.5") == Fixed!2("2.5"));

    // The following template is copied from vibe.d sources
    // Copyright (c) 2012-2018 RejectedSoftware e.K.
    // which is permited by vibe.d licence (MIT public license, 
    // see http://vibed.org/about#license)
    // in order to test the fromString method in the exact way that vibe.d does

    template isStringSerializable(T)
    {
        enum bool isStringSerializable = is(typeof(T.init.toString()) : string)
            && is(typeof(T.fromString("")) : T);
    }

    alias number = Fixed!2;
    static assert(isStringSerializable!number);

    // More tests.

    amount = 0.05;
    assert(amount.value == 5);
    assert(amount.toString() == "0.05");
    assert(cast(long) amount == 0);
    assert(cast(double) amount == 0.05);

    amount = 1.05;
    assert(amount.value == 105);
    assert(amount.toString() == "1.05");
    assert(cast(long) amount == 1);
    assert(cast(double) amount == 1.05);

    assert((++amount).value == 205);
    assert(amount.value == 205);
    assert((-amount).value == -205);
    assert((--amount).value == 105);
    assert(amount.value == 105);

    amount = 50;
    assert(amount.value == 5000);

    another = amount * 2;
    assert(another.value == 10_000);
    amount *= 3;
    assert(amount.value == 15_000);

    amount = "30";
    assert(amount.value == 3000);

    amount = 295;
    amount /= 11;
    assert(amount.value == 2681);
    assert(amount.to!double == 26.81);

    amount = 295;
    another = 11;
    assert((amount / another).value == 2681);
    assert((amount / another).toString() == "26.81");

    another = amount + 1.3;
    assert(another.value == 29_630);

    amount = 30;
    another = 50.2 - amount;
    assert(another.value == 2020);
    another -= 50;

    assert(another.value == -2980);

    another = amount / 1.6;
    assert(another.value == 1875);

    another = amount * 1.56;
    assert(another.value == 4680);

    fix1 a = 3.2;
    fix2 b = 1.15;

    assert(a.value == 32);
    assert(b.value == 115);

    assert((fix2(334) / 15).value == 2226);
    //assert(fix2(334) % 10 == 4);

    assert((334 / fix2(15.3)).value == 2183);
    //assert(334 % fix2(15.3) == 12.7);
}

// test safe toString
@safe unittest
{
    Fixed!2 val = Fixed!2(100.5);
    string result;
    void addToResult(const(char)[] v)
    {
        result ~= v;
    }
    val.toString(&addToResult);
    assert(result == "100.50");
}
