# CTFFuck2 - Hardcore

If you're a baby, check [this](../README.md) out!
If you're not, welcome to the abyss.

---

## What is this?

This is **CTFFuck2 Hardcore** — the C++ re-imagining of the original Python esolang.
It's not a port. It's a surgical reconstruction of the language's soul, built to weaponize
_deterministic chaos_ against anyone foolish enough to try writing a working program.

The original CTFFuck2 already turned programming into a sparse constraint-solving nightmare.
Hardcore pushes that nightmare into a new dimension: **global state coupling via a shared
ring buffer and path-dependent operand resolution.**

There is no randomness. No encryption. Just a handful of rules and a **mandatory
full-history integration** over every parameter ever pushed.

---

## Key differences from the Python version

| Python (baby)                                                           | C++ Hardcore                                                                           |
| ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Each instruction has its own stack (dict of lists)                      | All instructions share a single `fix_queue` ring buffer                                |
| `push` injects a value into the _next non-push instruction’s own stack_ | `push` writes _directly into the shared buffer_; no isolation                          |
| Stacks are cleared after consumption                                    | Old parameters **never die** — they linger until overwritten                           |
| `CALLING` mechanism auto-clears stale stacks                            | No auto-clear. Every push moves the global write head permanently                      |
| `grow` uses Python `random` — external entropy                          | `grow` is fully deterministic, driven by memory state                                  |
| Parameter offset is a local stack depth                                 | Parameter offset is a **compile-time constant** relative to the ever-moving write head |

In short: the Python version lets you pretend instructions are independent.
The Hardcore version forces you to confront the truth — **every operand of every instruction
is a function of the entire execution history.**

---

## The Core Mechanic: Global Shared Ring Buffer

All instructions’ temporary arguments live in a single `fix_queue` with a global `head_pointer`.
Every time any instruction calls `stack.push(value)`, the head advances by **1** and the value is
written at the previous head position. When an instruction later needs its saved argument, it
reads via `stack.at(offset)` — where `offset` is a **compile-time constant** indicating how many
steps back in the buffer the value should be.

Because the head keeps moving, the same `offset` might point to completely different memory
depending on _when_ the read occurs. This means:

- You cannot statically determine what operand an instruction will receive.
- You must **integrate** every push that happened between the write and the read.
- Even instructions that “finished” their pairing leave residues that can be accidentally
  consumed by a mistimed `at()`.

This is **path integration** in its rawest form.

---

## Instruction Behavior (Hardcore Edition)

| Opcode | Name    | Stack length | Notes                                                                |
| ------ | ------- | ------------ | -------------------------------------------------------------------- |
| 0      | `read`  | 1            | First call pushes address, second call reads memory.                 |
| 1      | `add`   | 1            | First call pushes address, second call adds to memory.               |
| 2      | `set`   | 0            | Zeros a memory cell.                                                 |
| 3      | `push`  | 0            | Pushes a value **directly into the shared buffer** (no indirection). |
| 4      | `print` | 0            | Prints the character at the given memory address.                    |
| 5      | `swap`  | 1            | Two-step pairing to swap memory contents.                            |
| 6      | `grow`  | 1            | **Transposon.** Generates new instructions and injects them.         |
| 7      | `inp`   | 0            | Reads one character from stdin into a memory cell.                   |
| 8      | `jmpm`  | 1            | Conditional jump based on flags.                                     |
| 9      | `revf`  | 0            | Flips zero flag or sign flag.                                        |

The stack length indicates how many values the instruction will push into the global buffer
during a single complete operation. Those values will be read back later using `at(offset)` where
the offset equals the instruction’s starting offset plus its stack depth minus 1… unless
the head has been moved by other instructions.

---

## The `push` instruction: instant injection

`push` no longer has its own stack. It writes directly to the global buffer at the current head
and advances the head. The next instruction that reads from the buffer _will_ consume that value
if its `at(offset)` happens to land on it — but only if the offset and head align correctly.
This makes `push` an art form of aligning the head position so the injected value reaches
the right consumer.

---

## The `grow` instruction: transposon

`grow` still takes three parameters (spindle, method, argument) and can produce new digits
that are pushed into a _vector_ (`transposus`) which then get executed as if they were part of
the original program. Methods 0–4 compute a new digit from the current memory state; method 5
swaps function pointers in the opcode table.

The Python version’s random noise is **completely removed.** Every `grow` outcome is now a
deterministic consequence of the current state and the instruction’s arguments. This makes
the language **fully deterministic** — yet whose behavior remains fundamentally unpredictable
without executing it.

---

## Building and Running

You need a C++17 compiler (for `std::filesystem` and lambdas) and a Unix-like environment
(the terminal raw mode uses `termios.h`).

```bash
./ctffuck2-hardcore -f program.ctf # if you have the executable
```

### Flags:

- `-f`, `--file` : Path to the program file (a string of digits, other characters ignored).
- `--debug` : (Currently a no-op; debugging is done by staring into the void.)

---

## The Philosophy of Hardcore

The original CTFFuck2 asked: _“Can a few simple rules generate a problem space so huge
that no human can solve it?”_

Hardcore answers: _“Yes — and we can make it even purer.”_

By removing isolated stacks, random noise, and auto-cleanup, Hardcore strips away every
crutch. What remains is a system where:

- The meaning of a digit depends on the **entire history** of the program.
- Writing a new program is equivalent to solving a **global, path-dependent constraint
  satisfaction problem** with millions of equations.
- Even the author cannot hand-craft a nontrivial program; the language has become a
  mathematical artifact, not a tool.

Hardcore is not for writing programs. It is for **contemplating the limits of human reason.**

---

## Credits

The original CTFFuck2 and this Hardcore variant were created for
whom equations are the only
language worth speaking.

Go stare into the abyss. The abyss will not stare back — it will just make you solve
for its head pointer.

[Back to baby version](../README.md)
