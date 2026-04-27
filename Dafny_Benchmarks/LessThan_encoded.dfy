class E {
  var i: int
  constructor (i0: int) 
    ensures i == i0
  {
    i := i0;
  }

    opaque function lt(o: object): bool 
        reads this, o
        ensures lt(o) ==> (o is E || o is F) // constr set
        ensures o == this ==> !lt(o)
    {
        if (o is E) 
        then 
            (i < (o as E).i) 
        else (
            if (o is F) then 
                (i < (o as F).i) else 
            false
        )
    }

    method prove_trans(other: object, o3: object) {
        reveal lt, F.lt;
        assume lt(o3);

        if (other is E) {
            assert (other as E).lt(this) ==> (other as E).lt(o3);
        } else if (other is F) {
            assert (other as F).lt(this) ==> (other as F).lt(o3);
        }
    }

    method prove_asymm(other: object) {
        reveal lt, F.lt;
        assume lt(other);

        if (other is E) {
            assert !(other as E).lt(this);
        } else if (other is F) {
            assert !(other as F).lt(this);
        }
    }
}

class F {
  var i: int
    constructor (i0: int) {
        i := i0;
    }

    opaque function lt(o: object): bool 
        reads this, o
        ensures lt(o) ==> (o is E || o is F) // constr set
        ensures o == this ==> !lt(o)
    {
        if (o is E) 
        then 
            (i < (o as E).i) 
        else (
            if (o is F) then 
                (i < (o as F).i) 
            else false
        )
    } 

    method prove_trans(other: object, o3: object) {
        reveal lt, E.lt;
        assume lt(o3);

        if (other is E) {
            assert (other as E).lt(this) ==> (other as E).lt(o3);
        } else if (other is F) {
            assert (other as F).lt(this) ==> (other as F).lt(o3);
        }
    }

    method prove_asymm(other: object) {
        reveal lt, E.lt;
        assume lt(other);

        if (other is E) {
            assert !(other as E).lt(this);
        } else if (other is F) {
            assert !(other as F).lt(this);
        }
    }
}