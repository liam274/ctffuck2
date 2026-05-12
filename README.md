# CTFFuck2

Welcome to the abyss.

## Table of Contents

- [What is this?](#what-is-this)
- [The Core Mechanic: Global Shared Ring Buffer](#the-core-mechanic-global-shared-ring-buffer)
- [Instruction Behavior](#instruction-behavior)
- [The `push` instruction: instant injection](#the-push-instruction-instant-injection)
- [The `grow` instruction: transposon](#the-grow-instruction-transposon)
- [Building and Running](#building-and-running)
- [The Philosophy of Hardcore](#the-philosophy-of-hardcore)
- [Credits](#credits)

## Table of Technical Contents

- [Application CTFFuck2 Interface(Kind of ABI)](docs/ACI.md)

---

## What is this?

This is **CTFFuck2**. It's a surgical reconstruction of
the language's soul, built to weaponize
_deterministic chaos_ against anyone foolish enough to try writing a working program.

The original CTFFuck2 already turned programming into a sparse constraint-solving nightmare.
Hardcore pushes that nightmare into a new dimension: **global state coupling via a shared
ring buffer and path-dependent operand resolution.**

There is no randomness. No encryption. Just a handful of rules and a **mandatory
full-history integration** over every parameter ever pushed.

---

## The Core Mechanic: Global Shared Ring Buffer

All instructions' temporary arguments live in a single `fix_queue` with a global `head_pointer`.
Every time any instruction calls `stack.push(value)`, the head advances by **1** and the value is
written at the previous head position. When an instruction later needs its saved argument, it
reads via `stack.at(offset)` — where `offset` is a **compile-time constant** indicating how many
steps back in the buffer the value should be.

Because the head keeps moving, the same `offset` might point to completely different memory
depending on _when_ the read occurs. This means:

- You cannot statically determine what operand an instruction will receive.
- You must **integrate** every push that happened between the write and the read.
- Even instructions that "finished" their pairing leave residues that can be accidentally
  consumed by a mistimed `at()`.

---

## Instruction Behavior

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
| 9      | `revf`  | 0            | Flips zero flag, sign flag or control flag.                          |

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

### Build from source code

If you want to build from source code, you need a C++17 compiler (for `std::filesystem` and lambdas) and a Unix-like environment
(the terminal raw mode uses `termios.h`).

### Run the binary

If you just want to execute from the binary

```bash
./ctffuck2 -f program.ctf # execute from file
```

or

```bash
./ctffuck2 -r "8754" # execute immediately
```

### Flags:

- `-f`, `--file` : Path to the program file (a string of digits, other characters ignored).
- `-d`， `--debug` : (Currently a no-op; debugging is done by staring into the void.)
- `-i`, `--input` : The input for the program

---

## Credits

The CTFFuck2 was created for
whom equations are the only
language worth speaking.

Go stare into the abyss. The abyss will not stare back
— it will just make you solve
for its head pointer.
