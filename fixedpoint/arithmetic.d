module fixedpoint.arithmetic;
import std.conv : to;
import fixedpoint.fixed : Fixed;

/// Before the operation the arguments are casted to the specified type
T addTo(T, int a, V, int b, U)(Fixed!(a, V) lhs, Fixed!(b, U) rhs)
{
    static if (a >= b)
    {
        return (lhs.value.to!T + rhs.value.to!T * 10 ^^ (a - b)) / lhs.factor;
    }
    else
    {
        return (lhs.value.to!T * 10 ^^ (b - a) + rhs.value.to!T) / rhs.factor;
    }
}

T subTo(T, int a, V, int b, U)(Fixed!(a, V) lhs, Fixed!(b, U) rhs)
{
    static if (a >= b)
    {
        return (lhs.value.to!T - rhs.value.to!T * 10 ^^ (a - b)) / lhs.factor;
    }
    else
    {
        return (lhs.value.to!T * 10 ^^ (b - a) - rhs.value.to!T) / rhs.factor;
    }
}

T mulTo(T, int a, V, int b, U)(Fixed!(a, V) lhs, Fixed!(b, U) rhs)
{
    return (lhs.value.to!T * rhs.value.to!T) / (lhs.factor * rhs.factor);
}

T divTo(T, int a, V, int b, U)(Fixed!(a, V) lhs, Fixed!(b, U) rhs)
{
    static if (a >= b)
    {
        return (lhs.value.to!T / rhs.value.to!T) / 10 ^^ (a - b);
    }
    else
    {
        return (lhs.value.to!T / rhs.value.to!T) * 10 ^^ (b - a);
    }
}

unittest
{
    import std.stdio : writeln;
    import fixedpoint.fixed : Fixed;
    import std.math : isClose;

    auto op1 = Fixed!2("1.11");
    auto op2 = Fixed!2("1.11");
    auto op3 = Fixed!3("1.111");
    assert(isClose(addTo!double(op1, op2), 2.22));
    assert(isClose(subTo!double(op1, op2), 0.0));
    assert(isClose(mulTo!double(op1, op2), 1.2321));
    assert(isClose(divTo!double(op1, op2), 1.0));
    assert(isClose(op1.addTo!double(op2), 2.22));
    assert(isClose(op1.subTo!double(op2), 0.0));
    assert(isClose(op1.mulTo!double(op2), 1.2321));
    assert(isClose(op1.divTo!double(op2), 1.0));
    assert(isClose(addTo!double(op1, op3), 2.221));
    assert(isClose(subTo!double(op1, op3), -0.001));
    assert(isClose(mulTo!double(op1, op3), 1.23321));
    assert(isClose(divTo!double(op1, op3), 0.99909990999));
    assert(isClose(addTo!double(op3, op1), 2.221));
    assert(isClose(subTo!double(op3, op1), 0.001));
    assert(isClose(mulTo!double(op3, op1), 1.23321));
    assert(isClose(divTo!double(op3, op1), 1.0009009009));
}
