module fixedpoint.algorithm;
import std.conv : to;

/// Before the operation the arguments are casted to the specified type
T castedOp(string op, T, S1, S2)(const S1 rhs, const S2 lhs)
{
    return mixin("rhs.to!T" ~ op ~ "lhs.to!T");
}

T addTo(T, S1, S2)(const S1 rhs, const S2 lhs)
{
    return castedOp!("+", T)(rhs, lhs);
}

T subTo(T, S1, S2)(const S1 rhs, const S2 lhs)
{
    return castedOp!("-", T)(rhs, lhs);
}

T mulTo(T, S1, S2)(const S1 rhs, const S2 lhs)
{
    return castedOp!("*", T)(rhs, lhs);
}

T divTo(T, S1, S2)(const S1 rhs, const S2 lhs)
{
    return castedOp!("/", T)(rhs, lhs);
}


unittest
{
    import fixedpoint.fixed : Fixed;
    import std.math : isClose;
    auto op1 = Fixed!2("1.11");
    auto op2 = Fixed!2("1.11");
    assert(isClose(castedOp!("/", double)(op1, op2), 1.0));
    assert(isClose(divTo!double(op1, op2), 1.0));
    assert(isClose(addTo!double(op1, op2), 2.22));
    assert(isClose(subTo!double(op1, op2), 0.0));
    assert(isClose(mulTo!double(op1, op2), 1.2321));
    assert(isClose(op1.divTo!double(op2), 1.0));
    assert(isClose(op1.addTo!double(op2), 2.22));
    assert(isClose(op1.subTo!double(op2), 0.0));
    assert(isClose(op1.mulTo!double(op2), 1.2321));
}