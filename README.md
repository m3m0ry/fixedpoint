# FixedPoint
**FixedPoint** provides a simple decimal fixed point type for the D language.

## Usage

```d
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
```

## Future Work
I plan to expand **FixedPoint** with an 'arithmetic' module, for easier handling of fixed-point arithmetic.
Especially for arithmetic, where the scale of the fixed point might change, in order to keep the information.

## Related Work
There are similar packages which provide some kind of fixed-point types and arithmetic.
However they don't seem to be maintained, or are too big for my purposes.
There is [fixed](https://github.com/jaypha/fixed), which is very similar and inspired this project.
[stdxdecimal](https://github.com/JackStouffer/stdxdecimal) seems to have same goals as well.
For arbitrary precision, you might want to try [bigfixed](https://github.com/kotet/bigfixed).
[decimal](https://github.com/rumbu13/decimal) is the IEEE-754-2008 compliant decimal data type.

## Licence
**FixedPoint** is released with the Boost license (like most D projects). See [here](http://www.boost.org/LICENSE_1_0.txt) for more details.