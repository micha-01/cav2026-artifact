class Fraction {
    var num: int
    var denom: int
    constructor(a0: int, b0: int) {
        var a: int := a0;
        var b: int := b0;

        if (a0 == 0 && b0 != 0) {
            b := 1;
        } else if (b0 == 0) {
            a := 1;
        } else {
            var g: int := gcd(a0, b0);
            if (b0 < 0) {
                g := -g;
            }
            a := a0 / g;
            b := b0 / g;
        }
        num := a;
        denom := b;
    }
   
    function equals(other: object): bool 
        reads this, other
        ensures this == other ==> equals(other)
        ensures equals(other) == (if this == other 
        then true 
        else (
            if (other is Fraction) then (
                num == (other as Fraction).num &&
                denom == (other as Fraction).denom
            ) else (
                if (other is Int) then (
                    denom == 1 && num == (other as Int).val
                ) else false
            )
        ))
    {
        if this == other 
        then 
            true 
        else (
            if (other is Fraction) then (
                num == (other as Fraction).num &&
                denom == (other as Fraction).denom
            ) else (
                if (other is Int) then (
                    denom == 1 && num == (other as Int).val
                ) else false
            )
        )
    }
}

class Int {
    var val: int
    constructor (i: int) {
        val := i;
    }

    function equals(other: object): bool 
        reads this, other
        ensures this == other ==> equals(other)
        ensures equals(other) == (
            if this == other 
        then true 
        else (
            if (other is Fraction) then (
                val == (other as Fraction).num &&
                1 == (other as Fraction).denom
            ) else (
                if (other is Int) then (
                    val == (other as Int).val
                ) else false
            )
        )
        )
    {
        if this == other 
        then true 
        else (
            if (other is Fraction) then (
                val == (other as Fraction).num &&
                1 == (other as Fraction).denom
            ) else (
                if (other is Int) then (
                    val == (other as Int).val
                ) else false
            )
        )
    }

}

function {:axiom} gcd(a: int, b: int): int
    requires a != 0 || b != 0
    ensures gcd(a, b) != 0
    ensures a % gcd(a, b) == 0 
    ensures b % gcd(a, b) == 0
    ensures forall d: int :: d > 0 && d <= abs(a) && d <= abs(b) && a % d == 0 && b % d == 0 ==> d <= gcd(a, b) 

function abs(i: int): int
{
    if (i < 0) then -1 else i
}