module fixedpoint.fixed;

import std.stdio;
import std.conv : to;
import std.range : repeat;
import std.format : format;
import std.string : split;
import std.math : sgn, abs, round;
import std.traits;

/// Fixed Class
struct Fixed(int scaling)
{
    /// Value of the Fixed
    long value = 0;
    /// Factor of the scaling
    enum factor = 10 ^^ scaling;

    //TODO floating, div, mult, modulo, power? ceil, floor, init, documentation&examples

    /// Smalest Fixed
    static immutable Fixed min = make(long.min);
    /// Largest Fixed
    static immutable Fixed max = make(long.max);

    /// Create a new Fixed, given a integral
    this(T)(T i) if (isIntegral!T)
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
    this(T)(T i) if (isFloatingPoint!T)
    {
      value = (i * factor).round.to!long;
    }
    ///
    unittest
    {
        auto p = Fixed!4(1.1);
        assert(p.value == 1.1 * 10 ^^ 4);
    }

    /// Create a new Fixed struct given a string
    this(string s)
    {
        if (s != "")
        {
            auto spl = s.split(".");
            value = format!"%s%(%s%)"(spl[0], 0.repeat(scaling)).to!long;
            if (spl.length > 1 && spl[1] != "")
            {
                if (spl[1].length > scaling)
                    value += value.sgn * (spl[1].to!long / 10 ^^ (spl[1].length - scaling));
                else
                    value += value.sgn * (spl[1].to!long * 10 ^^ (scaling - spl[1].length));
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
    }

    /// Direct construction of a Fixed struct
    static pure nothrow Fixed make(long v)
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


    void opAssign(Fixed p)
    {
        value = p.value;
    }
    void opAssign(T)(T n) if (isNumeric!T)
    {
        value = to!long(n * factor);
    }
    void opAssign(string s)
    {
        auto tmp = Fixed(s);
        value = tmp.value;
    }

    void opOpAssign(string op)(Fixed o)
    {
        value = mixin("value" ~ op ~ "o.value");
    }

    void opOpAssign(string op, T)(T n) if (isIntegral!T)
    {
        value = mixin("value" ~ op ~ "(n * factor)");
    }

    void opOpAssign(string op, T)(T n) if (isFloatingPoint!T)
    {
        value = mixin("value" ~ op ~ "(n * factor).round.to!long");
    }

    string toString() const
    {
        string sign = value.sgn == -1 ? "-" : "";
        return format!"%s%d.%0*d"( sign, (value / factor).abs, scaling, (value % factor).abs);
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

    bool opEquals(T)(T other) const if (isIntegral!T)
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

    //int opCmp(point)(const Fixed point other) const
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

    Fixed opUnary(string s)() if (s == "-" || s == "+")
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

    T opCast(T: Fixed!point, int point)() const
    {
        static if (point > scaling)
            return T.make(value * (10 ^^ (point - scaling)));
        else static if (point < scaling)
            return T.make(value / (10 ^^ (scaling - point)));
        else
            return this;
    }

    T opCast(T: bool)() const
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
        import std.stdio;
        assert(p.to!(Fixed!5).value == 110_000);
    }

    Fixed opBinary(string op, T)(T rhs) if (isIntegral!T)
    {
        return Fixed.make(mixin("value" ~ op ~ "(rhs * factor)"));
    }
    
    Fixed opBinary(string op, T)(T rhs) if (isFloatingPoint!T)
    {
        return Fixed.make(mixin("value" ~ op ~ "(rhs * factor).round.to!long"));
    }

    Fixed opBinaryRight(string op, T)(T lhs) if (isIntegral!T)
    {
        return Fixed.make(mixin("(lhs * factor)" ~ op ~ "value"));
    }

    Fixed opBinaryRight(string op, T)(T lhs) if (isFloatingPoint!T)
    {
        return Fixed.make(mixin("(lhs * factor).round.to!long" ~ op ~ "value"));
    }

    Fixed opBinary(string op)(Fixed rhs)
            if (op == "+" || op == "-")
    {
        return Fixed.make(mixin("value" ~ op ~ "rhs.value"));
    }

    /*
    Fixed opBinary(string op, point)(Fixed!oint rhs) if (op == "+" || op == "-")
    {
        static if (scaling > point)
            return Fixed(mixin("(value * 10^^(scaling - point))" ~ op ~ "rhs.value"));
        else
            return FixedDecimalscaling(mixin("value" ~ op ~ "(rhs.value * 10^^(point - scaling))"));
    }

    FixedDecimalopBinary(string op)(Fixed hs) if (op == "*")
    {
        return FixedDecimalvalue * rhs.value, point + rhs.point);
    }
    */

    ///
    unittest
    {
        auto p1 = Fixed!4(1);
        auto p2 = Fixed!4(2);
        assert(p1 + 1 == 2);
        assert(p1 + p2 == 3);
        auto p3 = Fixed!2(2);
        auto p4 = p2 + p3.to!(Fixed!4);
        assert(p4 == 4);
    }

    size_t toHash() const
    {
        return value;
    }
}


unittest
{
    import std.stdio : writeln;
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
    assertThrown(Fixed!10("12345678901234567"));
    writeln(Fixed!10("12345678901234567").toString);
    assert(fix2(24.6).value == 2460);
    assert(fix2(-27.2).value == -2720);
    assert(fix2(16.1f).value == 1610);
    assert(fix2(-87.3f).value == -8730);

    int i1 = 23;
    v2 = i1;
    assert(v2.value == 2300);

    i1 = -15;
    v1 = i1;
    assert(v1.value == -150);

    long l1 = 435;
    v2 = l1;
    assert(v2.value == 43500);

    l1 = -222;
    v3 = l1;
    assert(v3.value == -222000);

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
    assert(cv3.value == 22000);

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

    op1 = 5.23;
    op2 = 7.1;

    assert((op1 + op2).value == 1233);
    assert((op1 - op2).value == -187);
    //assert((op1 * op2) == 37.13);
    //assert((op1 / op2) == 0.73);

    assert((op1 + 10).value == 1523);
    assert((op1 - 10).value == -477);
    //assert(op1 * 10 == 52.3);
    //assert(op1 / 10 == 0.52);
    //assert(op1 % 10 == 5.23);

    assert((10 + op1).value == 1523);
    assert((10 - op1).value == 477);
    //assert(10 * op1 == 52.3);
    //assert(10 / op1 == 1.91);
    //assert(10 % op1 == 4.77);

    assert((op1 + 9.8).value == 1503);
    assert((op1 - 9.8).value == -457);
    //assert(op1 * 9.8 == 51.25);
    //assert(op1 / 9.8 == 0.53);

    assert((9.8 + op1).value == 1503);
    assert((9.8 - op1).value == 457);
    //assert(9.8 * op1 == 51.25);

    //assert(9.8 / op1 == 1.87);

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

    //amount *= 1.5;
    //assert(amount.value == 5175);

    //amount /= 12;
    //assert(amount.value == 431);

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

    //another = amount * 2;
    //assert(another.value == 10000);
    //amount *= 3;
    //assert(amount.value == 15000);

    amount = "30";
    assert(amount.value == 3000);

    //amount = 295;
    //amount /= 11;
    //assert(amount.value == 2681);
    //assert(amount == 26.81);

    amount = 295;
    another = 11;
    //assert((amount / another).value == 2681);
    //assert((amount / another).toString() == "26.81");

    another = amount + 1.3;
    assert(another.value == 29630);

    amount = 30;
    another = 50.2 - amount;
    assert(another.value == 2020);
    another -= 50;

    assert(another.value == -2980);

    //another = amount / 1.6;
    //assert(another.value == 1875);

    //another = amount * 1.56;
    //assert(another.value == 4680);

    fix1 a = 3.2;
    fix2 b = 1.15;

    assert(a.value == 32);
    assert(b.value == 115);

    //assert(fix2(334) / 15 == 22.26);
    //assert(fix2(334) % 10 == 4);

    //assert(334 / fix2(15.3) == 21.83);
    //assert(334 % fix2(15.3) == 12.7);

    // mult function

    //fix2 _v1 = 1.27;
    //fix2 _v2 = 3.45;
    //auto _v = _v1.mult(_v2);
    //assert(_v.sc == 4);
    //assert(_v.value == 43815);
}
