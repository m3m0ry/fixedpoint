import std.conv : to;
import fixedpoint.fixed : Fixed;

alias MyFixed = Fixed!4;

void main()
{
    auto f1 = MyFixed("21.5");
    assert(f1.toString == "21.5000");
    assert(f1.to!int == 21);
    assert(f1.to!double == 21.5);
    assert(f1 + 1 == MyFixed("22.5"));
    assert(f1 + 1 == MyFixed("22.5"));
    auto f2 = MyFixed("20.5");
    assert(f1 > f2);
    assert(f1+f2 == MyFixed("42"));
}