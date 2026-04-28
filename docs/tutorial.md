This page explains the basic concepts behind Nagini's specification language. For some examples of programs with specifications, have a look at the [examples](https://github.com/marcoeilers/nagini/tree/master/tests/functional/verification/examples) included in the test suite.

Nagini defines its own specification language in the form of a contract library. The library can be imported as follows:
```python
from nagini_contracts.contracts import *
```

Calls to the functions in this library will have no effect at runtime and can be removed automatically, but will be interpreted as specifications by the Nagini verifier as specified below.

# General contracts

## Contract declarations

### Preconditions
```python
Requires(a)
```

Written at the beginning of a function, this denotes that the assertion ``a`` is the precondition of the current function. Multiple declarations of preconditions will be treated cumulatively, i.e.,
```python
Requires(a1)
Requires(a2)
```
is equivalent to writing 
```python
Requires(a1 and a2)
```

### Postconditions
Regular postconditions are written like preconditions, but using the ``Ensures`` function
```python
Ensures(a)
```
at the beginning of a function, **after** the precondition. Alternatively, the postcondition can be declared at the end of a function.

Exceptional postconditions can be declared after the ordinary ones using the ``Exsures`` function:
```python
Exsures(MyException, a1)
Exsures(MyException, a2)
Exsures(OtherException, a3)
```
means that the current function is allowed to raise exceptions of type ``MyException`` or ``OtherException`` to its caller (but no others), and that in the former case, the assertion ``a1 and a2`` holds, and in the latter case ``a3``.

### Loop invariants
Similar to pre- and postconditions, loop invariants can be declared at the start of a while or for loop using the ``Invariant`` function:
```python
Invariant(a)
```

## Assertions

Assertions can be either side-effect free expressions of type ``bool``, including calls to pure functions (see below), or calls to special contract functions. 

### Permission assertions
In general, the assertion ``Acc(e1, e2)`` expresses an access permission amount ``e2`` to the location ``e1``. If ``e2`` is left out, this denotes a full permission.

**Permissions to fields: ** The following two assertions express a full and a half permission to field ``f`` of object ``o``, respectively:
```python
Acc(o.f), Acc(o.f, 1/2)
```

**Permissions to predicates:** Similar to fields, one can express permissions to predicates (explained below). Optionally, the ``Acc`` can be left out in this case to denote a full permission. The following assertions denote a full, full and third permission to a predicate ``pred(x, y, z)``:
```python
Acc(pred(x, y, z)), pred(x, y, z), Acc(pred(x, y, z), 1/3)
```

**Permissions to built-in predicates:** Similarly to ordinary predicates, Nagini provides special built-in predicates ``list_pred``, ``dict_pred`` and ``set_pred`` that denote permissions to the contents of a list, dict or set, respectively. They can be expressed like permissions to ordinary predicates:
```python
Acc(list_pred(l)), list_pred(l), Acc(list_pred(l), 1/4)
```
Unlike ordinary predicates, these do not have to be folded or unfolded to be used.

**Permissions to mutable global variables:** ``Acc`` can also be used to specify permissions to global variables which are assigned to in more than one location (i.e., are not constants):
```python
Acc(g), Acc(g, 1/2)
```

### Permissions for field creation

While permission expressions with ``Acc`` express that a permission to a currently existing field is held, two different kinds of assertions refer to fields that may not exist:

```python
MayCreate(o, 'f')
```
Represents the permission to create a currently not existing field named 'f' on object ``o``. This permission cannot be used for reading the field (as it does not exist). Assigning to ``o.f`` will consume this permission and create a permission ``Acc(o.f`` instead. 

Class constructors (i.e., ``__init__`` methods) implicitly get ``MayCreate`` permissions for all fields assigned to within the class.

```python
MaySet(o, 'f')
```
Can be thought of as ``Acc(o.f) or MayCreate(o, 'f')`` (which cannot be expressed directly, since permissions must not be used in disjunctions). Allows assigning to the specified field, after which it will definitely exist. Functions that require this permission in their precondition can be called by callers that have either a normal permission or a permission to create the specified field.

### Other assertion functions

``Implies(e1, a2)`` denotes that assertion ``a2`` holds if boolean expression ``e1`` is true.

``Forall(iterable, lambda x: a)`` denotes that assertion ``e`` is true for every element ``x`` in the iterable ``e``. In particular, ``a`` can contain permission assertions, meaning that those permissions are held for every element in the iterable. 

An advanced version ``Forall(iterable, lambda x: (a, list_of_triggers))`` allows to specify when the forall quantifier should be instantiated by the underlying SMT solver. ``list_of_triggers`` is a list of lists of trigger expressions; as an example, with ``[[l[x]], [f(x), g(x)]]`` the quantifier will be instantiated if the SMT solver either sees the pattern ``l[x]`` or both ``f(x)`` and ``g(x)``.

### Contract expressions

The following functions represent expressions that can be used within assertions:

``Result()`` can be used in postconditions to represent the result returned by a function. Must not be used anywhere else, nor in postconditions of functions of type ``None``.

``Old(e)`` can be used in postconditions and invariants and represents the value of expression ``e`` evaluated in the pre-state (i.e., at the beginning of the function). 

``Previous(x)`` can be used in invariants of for loops and represents a list containing the elements that were already iterated over in previous iterations. The argument has to be the target of the for loop. Example:

```python
res = []
for e in l:
    Invariant(list_pred(res))
    Invariant(len(res) == len(Previous(e)))
    res.append(e)
```

``ToSeq(e)`` can be used to convert one of the built-in containers to a pure Sequence (see below).

``Unfolding(a, e)``, where ``a`` must refer to a predicate (e.g. ``Acc(pred(x), 1/2)`` or ``pred(x)``), evaluates the expression ``e`` in a context where the predicate ``a`` refers to is temporarily unfolded.

### Checking assertions

Nagini checks that assertions expressed using Python's standard ``assert`` statement will always succeed. Additionally, Nagini offers its own function ``Assert(a)`` which can be used to check spatial assertions, whereas ``assert`` may only be used with ordinary boolean expressions. In particular, ``Assert(Acc(x.f))`` succeeds iff the current context holds a permission to ``x.f`` (but does not change the state; the permission is not given away), whereas ``assert Acc(x.f)`` will be reported as malformed.

Nagini also has a function ``Assume(e)`` which can be thought of as killing all traces for which ``e`` is not true. Like ``assert`` and unlike ``Assert``, ``Assume`` cannot be used with spatial assertions.

## Pure functions and predicates

By using specific decorators, normal functions can be declared to be either _pure_ (side-effect free) functions, which can be used in contracts, or _predicates_, which can be used to abstract over assertions.

### Pure functions
A function can be declared to be pure by using the ``@Pure`` decorator. Pure functions must not have side-effects, meaning that they can call other pure functions but not impure ones, use recursion but not loops, and cannot allocate new heap objects. 
```python
@Pure
def func1(x: MyClass, y: MyClass) -> int:
    Requires(a1)
    return e

@Pure
def func2(x: MyClass, y: MyClass) -> int:
    Requires(a1)
    Ensures(a2)
    if e1:
        return e2
    return e3 
```
The body of a pure function has to be expressible as a single expression. It can either be a single return statement, or a simple block containing only variable assignments, return statements, and conditionals.

Pure functions can have preconditions including access permissions if they depend on the heap but usually do not need postconditions: Unlike impure functions, pure functions are not treated modularly; code calling pure functions can see their definitions. Additionally, pure functions cannot consume permissions, and therefore their postconditions do not have to (and must not) state which permissions they give back to their callers.

### Predicates

Predicates abstract over assertions. A function can be declared to be a predicate definition by using the ``@Predicate`` decorator; its type must be ``bool``. The body of a predicate has to be a single return statement returning the contents of the predicate.

```python
@Predicate
def pred(x: MyClass, i: int) -> bool:
    return a
```

Predicates can be passed around in pre- and postconditions like permissions to fields. A function can have a fractional permission to a predicate. Predicates can be exchanged for their bodies using ``Fold`` and ``Unfold`` statements:

```python
@Predicate
def pred(x: MyClass, i: int) -> bool:
    return Acc(x.f) and x.f == i

x = MyClass()
x.f = 3
Fold(pred(x, 3))  # Give away permission to x.f, get predicate pred(x, 3)
Unfold(pred(x, 3))  # Give away predicate pred(x, x), get permission to x.f and knowledge that x.f == 3
x.f += 1
Fold(Acc(pred(x, 4), 1/2))   # Give away half permission to x.f, get predicate pred(x,4)
Unfold(Acc(pred(x, 4), 1/2))  # Get back half permission to x.f
```

When declared within classes, predicates are interpreted as **predicate families**, meaning that a predicate that overrides a predicate from a superclass is interpreted as the conjunction of the contents of the superclass predicate and its own explicitly declared contents.

## Datatypes

Nagini's contract library defines the types ``Sequence`` and ``PSet`` that represent pure (stateless) sequences and sets, respectively. They can be created with constructor calls ``Sequence(e1, e2, e3)`` and ``PSet(e1, e2, e3)`` to create a sequence or set containing the elements ``e1``, ``e2`` and ``e3``. 

Sequences offer the operations 
* ``__add__`` - sequence concatenation
* ``__getitem__``  - index lookup
* ``__len__`` - sequence length
* ``__contains__`` - membership test
* ``take``  - returns a sequence containing the first ``n`` elements of the current sequence
* ``drop``  - returns a sequence containing all but the first ``n`` elements

PSet offers
* ``+`` - union
* ``-`` - setminus
* ``__contains__`` - membership test
* ``__len__`` - cardinality

# Finite blocking contracts

Nagini enables verification of finite blocking properties in concurrent programs, e.g., deadlock freedom, termination, all locks will eventually be released, all threads which are attempted to join eventually terminate. The used methodology is adapted from [Boström and Müller](http://pm.inf.ethz.ch/publications/getpdf.php?bibname=Own&id=BostromMueller15.pdf).

## Threads

Nagini offers some special contract functions and extended APIs for verifying concurrent programs. Classes and functions related to thread verification can be imported as follows:
```python
from nagini_contracts.thread import *
```

This module defines its own ``Thread`` class with an API similar to that of Python's built-in ``Thread`` class. Code that is to be verified must use Nagini's thread class. 

**Thread creation:** The thread constructor is identical to Python's built-in one. A thread created as follows
```python
t = Thread(target=o.foo,
           args=(e1, e2, e3))
```
will, when started, execute the ``foo`` method of object ``o`` with the arguments ``e1``, ``e2`` and ``e3``.

After creating a thread object, one can assert that
* ``getArg(t, 1)``, which returns the value of the second argument passed to the thread, is equal to ``e2``.
* ``getMethod(t)`` is equal to ``o.foo``
* The thread can be started, which can be expressed as ``MayStart(t)``.

**Thread start:** A thread can be started by calling the ``start`` method on the thread object. This method must be provided with a list of function references; the actual method that was passed to the thread during creation must be one of the functions in the list.

```python
t.start(o.foo)  # t is known to point to method o.foo (see above)

if b:
    t2 = Thread(target=o.bar, args=(e1,))
else:
    t2 = Thread(target=o.baz, args=(e2,))
t2.start(o.bar, o.baz)  # getMethod(t2) can be either o.bar or o.baz
```

Starting a thread will 
* consume the permission ``MayStart(t)`` to start it
* check the precondition of ``getMethod(t)`` and consume the permissions in it
* generate the knowledge that ``Joinable(t)`` is true if the target function promises to terminate (see below), which is required to join the thread
* create a permission to ``ThreadPost(t)`` which represents a permission to assume the target function's postcondition when joining the thread.

If the postcondition of the thread's target function contains ``Old()`` expressions (see above), those will be evaluated when starting the thread, and their values will be stored in the thread object. Assertions about this can be expressed using the ``getOld`` contract function. As an example, after a starting a thread whose target is the following function:
```python
def add_and_zero_out(c1: Cell, c2: Cell) -> int:
    Requires(Acc(c1.value) and Acc(c2.value))
    Ensures(Acc(c1.value) and Acc(c2.value))
    Ensures(Result() == Old(c1.value) + Old(c2.value))
    res = c1.value + c2.value
    c1.value, c2.value = 0, 0
    return res

c = Cell()
c2 = Cell()
c.value = 4
c2.value = 7
t = Thread(target=add_and_zero_out, args=(c, c2))
t.start(add_and_zero_out)
```
one could assert that ``getOld(t, arg(0).value) == 4`` and ``getOld(t, arg(1).value) == 7``. In other words, the second argument to ``getOld`` should be an expression as it occurs in an old-expression in the target function's postcondition, where references to function parameter with index _i_ are replaced with ``arg(i)``.

**Thread join:** Joining a thread has a similar syntax as starting it:
```python
t.join(o.bar, o.baz)  # actual target function must be in the list
```

Joining a thread requires the knowledge that the thread can be joined (expressed as ``Joinable(t)``). If some permission amount to ``ThreadPost(t)`` is held when joining a thread, that permission will be consumed, and the thread's target function's postcondition will be assumed. If only a partial permission to ``ThreadPost(t)`` was held, the permissions in the postcondition will only partially be received.

## Locks
Contract functions related to locks can be imported as follows:
```python
from nagini_contracts.lock import *
```
Similarly to threads, Nagini requires that lock operations are performed using the ``Lock`` class defined in this module instead of Python's built-in one. Locks are associated with an invariant, which guards permissions for the state that is protected by the lock, and a level, which is used for preventing deadlocks: Locks may be acquired only in the order specified by their levels.

A lock's invariant can be specified by subclassing Nagini's ``Lock`` class and overriding the ``invariant`` predicate in this class. Inside this predicate, the invariant is to be specified in terms of the ``get_locked`` method, which returns a reference to the object whose fields are guarded by the lock.

Example:
```python
class DoubleCell:
    def __init__(self) -> None:
        self.val1 = 0
        self.val2 = 0
        Ensures(Acc(self.val1) and Acc(self.val2) and self.val1 == 0)

class DCLock(Lock[DoubleCell]):
    @Predicate
    def invariant(self) -> bool:
        # Lock protects the val1 field of a DoubleCell object 
        # and maintains a nonnegative value in this field
        return Acc(self.get_locked().val1) and self.get_locked().val1 >= 0
```

Locks can be created using a constructor call of the following form: 
```python
dc = DoubleCell()
l = DCLock(dc, above, below)
```
The first argument to the constructor is the locked object; ``l.get_locked()`` returns this object. The following two are optional; if they are given, they need to be references to other locks. If this is done, the level of the newly created lock will be constrained to be above than that of the ``above`` lock and below that of the ``below`` lock. 

When creating a lock, the invariant will be checked, and the permissions included in the invariant will be given away (they now belong to the lock). 

**Acquiring a lock:**
A lock can be acquired by calling ``l.acquire()``. This will:
* Check that the level of ``l`` is higher than that of any currently held lock
* Give the acquiring thread a permission to the ``invariant`` predicate of the lock, which can be unfolded to get the permissions included in the invariant and assume any other assertions included in it.
* Give the acquiring thread an obligation (see below) to release the lock.

**Releasing a lock:**
When calling ``l.release()``,
* the ``invariant`` predicate is given away again
* the obligation to release the lock is fulfilled.

## Obligation contracts

As mentioned before, finite blocking is achieved by reasoning about _obligations_ that must be eventually be fulfilled, particularly, obligations to terminate, and obligations to release a lock that is currently held. This is combined with reasoning about _levels_ of threads and locks. The required contract functions can be imported as follows:
```python
from nagini_contracts.obligations import *
```

Nagini currently supports two kinds of obligations (in addition to IO tokens, see below):

``MustTerminate(e)``, where ``e`` must be an integer expression, declares an obligation to terminate. When used in a precondition (``Requires(MustTerminate(n))``), a function promises to its caller to terminate within _n_ steps; it can only call other functions that terminate in less than _n_ steps, and all its loops must promise to terminate as well. When used in a loop invariant (``Invariant(MustTerminate(n))``), the loop promises to terminate in _n_ iterations; the value of the expression _n_ must decrease with every iteration while staying non-negative.

``MustTerminate(l, e)``, where ``l`` is a reference to a lock and ``n`` is a measure, declares an obligation to release the currently held lock ``l``. While holding such an obligation, only terminating operations may be performed unless they promise to fulfill the obligation; in particular, other functions may only be called if they terminate or if they take the obligation to release the lock in their precondition with a lower measure. 

Importantly, obligations cannot be leaked: If a function has obligations left at the end of its body, these must be passed to its caller so that they are eventually fulfilled.

The aforementioned levels of locks can be specified using the function ``Level``. Assertions about levels must not specify levels exactly, but only in relation to other locks, e.g. ``Level(l1) < Level(l2)``. In addition, ``WaitLevel()`` describes the highest level of any obligation held by the current thread. In order to acquire a lock ``l``, for example, it is required to know that ``WaitLevel() < Level(l)``.

# Input/Output contracts

Nagini allows reasoning about input/output behavior. In particular, it allows 
1. Declaring basic IO operations
2. Defining composite IO operations
3. Write contracts about allowed IO behavior using these operations.

Contracts about IO behavior have the form of petri nets. Performing an IO operation takes the program from one place in a petri net to a different one. Only IO operations that are specified in a petri net are allowed.

The methodology for verifying IO is based on [Penninckx et al.](https://lirias.kuleuven.be/bitstream/123456789/478356/3/esop2015-ioverif.pdf) but extended to verify liveness as well ([Astrauskas](https://www.ethz.ch/content/dam/ethz/special-interest/infk/chair-program-method/pm/documents/Education/Theses/Vytautas_Astrauskas_MA_report.pdf)).

All contract functions referenced in this part can be imported as follows:
```python
from nagini_contracts.io_contracts import *
```

## Declaring basic IO operations

A basic (atomic) IO operation can be declared as follows:

```python
@IOOperation
def write_int_io(
        t_pre: Place,
        value: int,
        t_post: Place = Result(),
        ) -> bool:
    Terminates(True)
```
This declares that there is an IO operation ``write_int_io`` which has one input place (every IO operation does), one input parameter, no return value (return values are marked by `` = Result()``), and one output place (like every IO operation). The IO operation is non-blocking, i.e., it always terminates. 

As another example, the following IO operation has no input parameters, returns an integer value, and may not terminate: 
```python
@IOOperation
def read_int_io(
        t_pre: Place,
        number: int = Result(),
        t_post: Place = Result(),
        ) -> bool:
    Terminates(False)
```

## Writing contracts about IO behavior

Contracts about IO behavior have the following components:
* The assertion ``token(p)`` specifies that the execution is currently in place ``p`` within an imaginary petri net.
* An assertion ``write_int_io(p1, 5, p2)`` (or similar for any other IO operation) specifies that if the execution is in place ``p1``, it may perform the IO operation ``write_int_io`` with the argument ``5``, and after doing so it will be in place ``p2``. 

Using these components, library functions that perform basic IO operations can be given specifications that state they perform them:
```python
def write_int(t1: Place, value: int) -> Place:
    IOExists1(Place)(
        lambda t2: (
        Requires(
            token(t1, 1) and
            write_int_io(t1, value, t2)
        ),
        Ensures(
            token(t2) and
            t2 == Result()
        ),
        )
    )
```
IOExists existentially quantifies over the specified number of variables. This contract declares that to invoke ``write_int``, the execution must currently be in place ``t1`` and must have a permission to perform the IO operation ``write_int_io`` with the given argument value from that place, and that there is some existentially quantified place ``t2`` in which the execution will end up after performing this IO operation, and ``write_int`` returns this place. 

The reason for existential quantification is more obvious when talking about an IO operation with a return value:
```python
def read_int(t1: Place) -> Tuple[Place, int]:
    IOExists2(Place, int)(
        lambda t2, value: (
        Requires(
            token(t1, 1) and
            read_int_io(t1, value, t2)
        ),
        Ensures(
            token(t2) and
            t2 == Result()[0] and
            value == Result()[1]
        ),
        )
    )
```
Here, the return value of ``read_int_io`` is existentially quantified, since the value it returns is determined by the environment and now known. The contract of ``read_int`` states that it returns the place in which the execution now is, and the value returned by the ``read_int_io`` operation.

When verifying functions that perform IO operations, contracts are expressed in the same way. This is what a Hello World function looks like in our framework:

```python
def hello(t1: Place) -> Place:
    IOExists1(Place)(
        lambda t2: (
        Requires(
            token(t1, 2) and
            write_string_io(t1, "Hello World!", t2)
        ),
        Ensures(
            token(t2) and
            t2 == Result()
        )
        )
    )

    t2 = write_string(t1, "Hello World!")

    return t2
```

Importantly, ``token``s are obligations in the sense specified before: When holding a token, a function must eventually perform an IO operation that consumes the token (i.e., moves the execution along in the petri net). For this reason, tokens can optionally be expressed with a measure as a second argument (``token(p1, 4)``) like other obligations.

As a result, IO contracts constrain the IO behavior of a program in two ways: Programs may _only_ perform IO operations for which they have permissions, and they _must_ eventually perform some IO operation in order to make progress in the petri net.

## Declaring composite IO operations

Composite IO operations are IO operations made up of basic ones; they serve to summarize common IO patterns, and can express repetition via recursion. As an example, the following composite IO operation first performs and accept, then a read_all, then an output and then a close operation before calling itself recursively (i.e., starting again from the beginning):

```python
@IOOperation
def listener_loop_io(
        t_pre: Place,
        server_socket: Socket) -> bool:
    Terminates(False)
    return IOExists6(Place, Place, Place, Place, Socket, str)(
        lambda t2, t3, t4, t5, client_socket, data: (
            accept_io(t_pre, server_socket, client_socket, t2) and
            read_all_io(t2, client_socket, 1, data, t3) and
            output_io(t3, client_socket, data, t4) and
            close_io(t4, client_socket, t5) and
            listener_loop_io(t5, server_socket)
        )
    )
```
Composite IO operations can only be declared to be terminating if all their parts terminate; if they do so, they must also declare a ``TerminationMeasure(n)`` with a measure _n_ is higher than that of any of their parts.

## Built-in IO operations

Nagini pre-defines three important IO operations, which can be imported as follows:
```python
from nagini_contracts.io_builtins import *
```

* The IO operation ``no_op_io``, implemented by the function ``NoOp``, does exactly what its name implies, nothing. 
* The IO operation ``split_io``, implemented by ``Split``, takes a single token and returns two output tokens. This can be used to specify two sequences of IO operations which are to be executed in parallel, or in an arbitrary order.
* The IO operation ``join_io``, implemented by ``Join``, does the opposite and takes two input tokens and returns only one. This is useful for specifying that two independent sequences of IO operations must both be finished before performing the following IO.

# Secure Information Flow

Nagini can verify different forms of information flow security by using an encoding based on modular product programs. 
This option has to be enabled explicitly by using the command line option ``--sif`` or ``--sif=true`` (for ordinary non-interference), ``--sif=poss`` (for possibilistic non-interference), or ``--sif=prob`` (for probabilistic non-interference). The latter two options can be used to verify concurrent programs, whereas ordinary non-interference can only be proved for sequential programs.

Note that using any of these options comes with a performance penalty, so they should be used only when a proof of information flow security is actually desired.

Contracts for information flow security consist of one main assertion, ``Low(e)``. The former states that the sensitivity of expression ``e`` is low, i.e., the value of ``e`` is not secret. Here is an example:

```python
def leak(x: int, secret: bool) -> int:
    Requires(Low(x))
    Ensures(Low(Result()))
    if secret:
        return 15
    return x
```
The contract of this function states that it may only be called with non-secret values for ``x`` (but, implicitly, since it has no such constraint, ``secret`` may contain secret data), and that under this assumption, the result it returns will be non-secret. The function actually does not fulfill this contract, since, if ``x`` is not equal to 15, the result leaks whether ``secret`` is true (when the result is 15) or false (when the result is not 15).

Low-assertions can be used in all kinds of specifications (in pre- and postconditions as shown above, in loop invariants, in predicates including lock invariants, and in quantifiers, e.g. to state that every element of a list is low) except in pure functions. 

The assertion ``LowVal(e)`` has a similar function as ``Low(e)``, but states that, if ``e`` is a built-in type like ``int`` or ``bool``, its _value_ is low, whereas the concrete reference might not be. As an example, a variable of type ``int`` could, depending on a secret, refer to either ``True`` (since booleans are integers in Python 3) or to the integer object 1; in this case, its reference is not low, since depending on the secret it points to an integer object or a boolean object, but its integer value, which is 1 in both cases, is low (and therefore the result of any subsequent computations it might be used in is as well). 

The assertion ``LowEvent()`` states that the control flow at the current position is low, i.e., whether and how often the program flow gets to the current position in the program does not depend on secret data. Any function that produces observable effects, e.g. a ``print`` function, should demand in its precondition that its execution is a low event. This prevents situations like
```python
if secret:
    print(0)
```
that leak whether the secret is true or not through the fact that 0 is either printed or not. This program will be rejected if ``print`` has ``Requires(LowEvent())`` in its precondition, since the control flow at the point where the call is made is influenced by the secret. (In addition, one would of course usually demand ``Requires(Low(x))`` for the function's parameter ``x``).

These were the main specification constructs for ordinary non-interference. For different kinds of non-interference, there are additional proof obligations:
* To prove termination-sensitive non-interference, one can use assertions of the form ``TerminatesSif(e1, e2)`` in preconditions and loop invariants, which state that the current function or loop terminates if and only if ``e1`` is true. Nagini will prove that 1) the loop indeed terminates if ``e1`` is initially true (by using ``e2`` as a ranking function), 2) that the loop indeed does not terminate if ``e1`` is initially false, 3) that the control flow at the point where the loop is reached is low, and 4) that ``e1`` is low. Together, these proof obligations ensure that whether the function or loop leads the program to diverge or not does not depend on secret data.
* For possibilistic non-interference, acquiring and releasing locks must be a low event. Additionally, loops must not introduce secret-dependent non-termination, meaning that the termination of a loop must not depend on a secret. This must be proved either by using ``TerminatesSif(e1, e2)`` as the _last_ part of the loop invariant, which generates the proof obligations explained above, or (if there is no such ``TerminatesSif`` invariant) by showing that the loop condition is always low.
* For probabilistic non-interference, all control flow must be low, so Nagini will prove that e.g. all branch conditions, the receiver types of all dynamically-bound calls, and the types of all raised exceptions are low. As a consequence, ``LowEvent()`` is trivially true everywhere in this mode.

More information about these specification constructs and the encoding used to prove them can be found in [our TOPLAS 2020 paper on the topic](http://pm.inf.ethz.ch/publications/getpdf.php?bibname=Own&id=EilersMuellerHitz19.pdf).
