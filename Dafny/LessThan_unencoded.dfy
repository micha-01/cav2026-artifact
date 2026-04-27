class E {
  var i: int
  constructor (i0: int) 
    ensures i == i0
  {
    i := i0;
  }

  function lt(o: object): bool 
    reads this, o
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
}

class F {
  var i: int
  constructor (i0: int) {
    i := i0;
  }

  function lt(o: object): bool 
    reads this, o
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
}