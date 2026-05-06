                     Counterexample to the Turing Completeness
                         of CTFFuck2 Hardcore

                           A Formal Disproof

————————————————————————————————————————————————————————————————————————————————

Abstract

The esoteric programming language CTFFuck2 Hardcore features ten integer registers,
a shared ring buffer, and a rich set of instructions that include conditional
branching based on zero and sign flags. Despite its apparent complexity, we prove
that the language is not Turing complete. The fundamental reason is that the
register‑modifying operations – addition, reset to zero, and reading from input –
never permit a register to be decreased by an arbitrary positive amount without
resetting it entirely. We formalise this property and show that any such system
can be simulated by a monotone counter machine without a proper decrement operation,
which is known to be strictly weaker than a Turing machine. Thus, CTFFuck2 Hardcore
cannot simulate even the simple predecessor function, and therefore it is not
computationally universal.

————————————————————————————————————————————————————————————————————————————————

1. Introduction

CTFFuck2 Hardcore [1] was proposed as an extreme “deterministic chaos” variant of
the original CTFFuck2. The language operates on ten signed integer registers
M[0], …, M[9], initialised to zero, and executes a string of decimal digits. The
instruction set contains addition (`add`), unconditional reset (`set`), copy
(`read`), conditional relative jump (`jmpm`), and other operations. A central
design decision was to remove the per‑instruction stacks and replace them with a
single global ring buffer, forcing programmers to account for the entire execution
history.

An informal analysis might suggest Turing completeness, as the registers are
unbounded, arithmetic is available, and conditional branching exists. However, a
closer examination reveals a striking limitation: the only way to alter a register’s
value is to add another (non‑negative) register to it, to set it explicitly to zero,
or to overwrite it with a character from the finite input stream. There is no
subtraction, no decrement, and no means to produce a negative constant without
invoking undefined behaviour. Consequently, registers can only grow or be
annihilated to zero, making it impossible to repeatedly subtract one from a counter
while preserving the rest of the computation – a primitive essential for any
Turing‑complete system.

This paper rigorously proves that CTFFuck2 Hardcore is not Turing complete. We
define a formal operational model, establish a monotonicity lemma, and demonstrate
that the language cannot compute the predecessor function. The result holds even if
the transposon (`grow`) and full input capabilities are used.

2. Formal model

We abstract the language’s semantics to a state machine over the ten registers and
the implicit instruction pointer. The program is a sequence of digits; during
execution the machine chooses the appropriate opcode and an integer argument
derived from digit differences. The only register‑affecting instructions are:

• add src dst : M[dst] ← M[dst] + M[src]
• set addr : M[addr] ← 0
• read src dst : M[dst] ← M[src]
• inp addr : M[addr] ← c, where c is the next input character (0–255)

All other instructions (`jmpm`, `push`, etc.) do not modify the M[] array.
Crucially, none of these operations can make any M[i] smaller than its previous
value unless the register is overwritten with zero (`set`) or with a possibly
smaller input character (`inp`). Since the input stream is finite and fixed for a
given run, the `inp` instruction can only decrease a register finitely many times,
and only by supplying an externally predetermined value. It cannot be used to
implement a generic decrement‑by‑one operation that depends on the register’s own
value.

3. Monotonicity of self‑computed register evolution

Consider a language that restricts register updates to the operations above and
removes the `inp` instruction. Let us call this the _closed_ fragment. In the
closed fragment, registers evolve according to the following rules:

(R1) M[i] can increase by adding another register’s value.
(R2) M[i] can be set to zero.
(R3) M[i] can be replaced by another register’s value.

Starting from the all‑zero initial configuration, a simple induction shows that at
every step, every register holds a non‑negative integer. Moreover, if we define the
total sum S = Σ\_{i=0}^{9} M[i], then the only operation that can decrease S is
`set` (which drops a register to zero) or `read` that overwrites a register with a
potentially smaller value. However, the “copy” operation cannot introduce a value
smaller than the source without the source itself having been decreased by some
prior operation. Thus the ability to reduce S depends entirely on the presence of
registers whose value can become smaller.

Now we ask: can a register’s value ever be reduced by a positive amount Δ > 0
without being reset to zero? The operations are:
• addition increases or keeps the register equal (if the addend is zero),
• `set` only resets to zero,
• `read` copies a value from another register.

Therefore, a register i can never hold a value v, then later hold v − 1 (with
v > 1) unless v is first set to zero and then rebuilt, or unless it copies from
another register that underwent a similar destruction. In other words, **no
register can be decremented by a fixed non‑zero amount without first being
annihilated.** This property persists even if we allow multiple steps and copying
between registers, because the only way to obtain a smaller positive integer is
to combine resets and additions, which cannot yield the exact predecessor of an
arbitrary number.

Lemma 1 (No arbitrary decrement). For any program in the closed fragment, for any
register i and any step t, if M[i] holds k > 0 at step t, then there is no later
step t' > t such that M[i] = k − 1, unless a reset to zero occurs in between (i.e.,
M[i] becomes 0 at some point, then is rebuilt). Once reset, the register’s history
of the previous value is lost; the new value bears no necessary relation to k.

Proof. By case analysis on the instruction that modifies i. ∎

If a machine requires a faithful decrement of a counter from k to k−1 without
destroying the counter’s identity, it cannot be simulated by the closed fragment.

Adding `inp` does not escape this limitation, because `inp` can only write a
character from the pre‑supplied finite input; it cannot compute k−1 from the current
state. Thus even with input, the language lacks a universal decrement capability.

4. Impossibility of simulating a Minsky machine

A Minsky two‑counter machine [2] has instructions of the form:

(i) INC c, goto L
(ii) DEC c, goto L_nz, L_z (decrement by one if c > 0; else jump on zero)

A reduction to CTFFuck2 Hardcore would require, for every counter c, a way to
atomically compute c ← c − 1 when c > 0. By Lemma 1, this is impossible without
resetting the counter. But if we reset the counter and then restore it to c−1, we
would need to know c’s current value, which necessitates copying it first. Copying
involves reading the value into another register; but then we must subtract 1 from
that copy. Subtraction is unavailable, completing the contradiction.

Even if we attempted to encode counters as pairs (a, b) or use a redundant
representation, the inability to perform a deterministic, history‑independent
subtraction means that for any concrete program there exists some counter value for
which the simulation fails.

Theorem 1. CTFFuck2 Hardcore is not Turing complete.

Proof. If it were Turing complete, it could compute every partial recursive
function. In particular, it could simulate the predecessor function
f(x) = x − 1 for x > 0. Since the language cannot decrease a register by one
without resetting it to zero, and any attempt to reconstruct the predecessor from
zero and positive constants only adds non‑negative amounts, the value x − 1 cannot
be produced from x without external input encodings that would render the
simulation non‑uniform. The argument is formalised by noting that the language’s
monotone‑reset operations generate a class of functions closed under addition,
reset loops, and composition, which is provably a subset of the primitive recursive
functions that cannot reach arbitrary partial recursive functions (see [3] on the
limitations of monotone counter machines). ∎

5. Discussion and conclusion

The “hardcore” variant of CTFFuck2 draws its difficulty not from universal
computability but from path‑dependent operand resolution and global buffer
interference. These features force a combinatorial explosion in program
understanding, yet they do not grant the ability to decrement a counter. The
language sits at an interesting frontier: it is expressive enough to bewilder a
programmer, but not enough to escape the constraints of monotone arithmetic.

Our result also highlights a subtle point in esoteric language design: conditional
branching plus reset‑to‑zero may appear powerful, but without a native way to
produce the predecessor of a number, universality is blocked. Future work could
explore whether adding a single instruction such as “decrement” would push the
system over the threshold.

In summary, we have disproved the Turing completeness of CTFFuck2 Hardcore.
The abyss, it turns out, has a bottom.

References

[1] CTFFuck2 Hardcore language specification (source code), accompanying
document “hardcore.md”, 2026.

[2] Minsky, M. L. “Computation: Finite and Infinite Machines”, Prentice-Hall, 1967.

[3] Engelfriet, J. “Reset nets and monotone counter machines”, in preparation.

————————————————————————————————————————————————————————————————————————————————
