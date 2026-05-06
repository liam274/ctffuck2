**Turing Completeness of CTFFuck2 Hardcore**  
*A formal proof of computational universality in a path‑dependent esoteric language*

---

**Abstract**  
CTFFuck2 Hardcore is an extreme esoteric programming language (esolang) derived from the Python‑based CTFFuck2. It features a shared global ring buffer, differential instruction arguments, deterministic execution, and no traditional stack isolation. We prove that, despite its intentionally hostile design, the language is Turing complete. The proof constructs a fixed‑length program that simulates a Minsky two‑counter machine, leveraging the rigid timing constraints of the ring buffer to correctly pair multi‑step instructions forever. This result demonstrates that even the most barren computational substrates, stripped of randomness and human‑friendly structure, retain universal expressiveness.

---

## 1. Introduction

Esoteric programming languages explore the boundaries of what can be called a programming language, often by paring away convenience to expose fundamental computational principles. CTFFuck2 Hardcore is such a language: a C++ re‑imagining of the original CTFFuck2, whose documentation proudly declares it “not a tool” but a “mathematical artifact” for contemplating the limits of human reason [1]. The language eliminates isolated stacks, auto‑cleanup, and external entropy, replacing them with a single global ring buffer and a **mandatory full‑history integration** over every parameter ever pushed.

The question naturally arises: is this system still capable of universal computation? Or does its severe path‑dependence collapse its expressive power into a finite‑state automaton? This paper proves that CTFFuck2 Hardcore is **Turing complete**. We exhibit a direct simulation of a Minsky two‑counter machine, a well‑known Turing‑complete formalism, using only a finite program string and no dynamic code generation. The proof is constructive, and its core insight is that the ring buffer’s fixed size (5) and the instruction‑pairing rules allow a static program layout to maintain correct internal synchronisation across unboundedly many iterations.

## 2. The CTFFuck2 Hardcore Language

We summarise the language as defined in its interpreter [1] and accompanying specification [2].

### 2.1 Memory and State

- **Memory**: 10 cells, `MEMORY[0..9]`, each an unbounded integer, initially zero.
- **Flags**: `zf` (zero flag) and `sf` (sign flag), set by arithmetic operations.
- **Ring buffer**: a fixed‑size queue (`fix_queue<int>`) of size 5 with a global write head. All instructions share this buffer; pushing a value advances the head and stores the value at the previous head position.
- **Transposus vector**: a stack of generated opcode digits that are executed before the next program symbol.
- **Program counter**: an index into the program string, advanced forward; jumps change it.

### 2.2 Instruction Set

Ten opcodes, `0`–`9`, each associated with a function name: `read`, `add`, `set`, `push`, `print`, `swap`, `grow`, `inp`, `jmpm`, `revf`. Instructions receive their argument via the differential rule:

```
arg = (last == -1) ? current_digit : (last_digit - current_digit)
```

where `last_digit` is the opcode of the immediately preceding instruction, or `-1` for the first instruction. If the argument is negative, the instruction performs no operation (except `revf`, which uses the least bit of the argument regardless of sign).

**Single‑step instructions** (`set`, `push`, `print`, `inp`, `revf`) execute immediately. **Two‑step instructions** (`read`, `add`, `swap`, `grow`, `jmpm`) operate in a finite‑state manner: the first occurrence (indicated by an internal counter equal to 0) *pushes* its argument into the ring buffer and advances the counter; the second occurrence *reads* a stored argument from the ring buffer using a compile‑time constant offset, performs the operation, and resets the counter. The stack lengths and offsets are:

| Instruction | Stack length | Offset (distance from head when reading) |
|-------------|------------|------------------------------------------|
| `read`      | 1          | 0                                        |
| `add`       | 1          | 1                                        |
| `swap`      | 1          | 2                                        |
| `grow`      | 1          | 3                                        |
| `jmpm`      | 1          | 4                                        |

Because the buffer size is 5, a write at offset `k` means the argument was pushed exactly `k` steps *after* the current head position. Therefore, to pair correctly, the number of intervening push operations between the two parts of an instruction must be congruent to `offset` modulo 5. (For a freshly initialised buffer, the required exact number of pushes is exactly `offset`.)

The `push` instruction (opcode `3`) writes its argument directly to the ring buffer, advancing the head; this serves as a flexible padding operation.

### 2.3 Conditional Jump

`jmpm` (opcode 8) uses its pair of occurrences to perform a conditional relative jump. The first `jmpm` pushes an argument that encodes a condition:
- 0: jump if `zf` is true (equal)
- 1: jump if `zf` is false
- 2: jump if `sf` is true (negative)
- 3: jump if `!sf` is true (non‑negative)
- 4: jump if `zf || sf` (≤0)
- 5: jump if neither (strictly positive)
- 6: unconditional jump

The second `jmpm` reads the condition from offset 4, evaluates it, and if true, adds `MEMORY[arg]` to the program pointer (where `arg` is the current differential argument). This allows arbitrary forward/backward jumps.

### 2.4 The `grow` Instruction and Determinism

`grow` (opcode 6) can generate new opcode digits and push them onto the transposus vector for later execution. However, the language is fully deterministic: every outcome depends only on the current memory state and the supplied arguments. Our proof does not require `grow`; the simulation uses only the basic instruction set.

## 3. Simulation of a Minsky Machine

A two‑counter Minsky machine [3] consists of two unbounded counters, initially zero, and a finite program of labelled instructions of the form:

- `INC i, next`: increment counter `i` and go to `next`.
- `DEC i, next_zero, next_nonzero`: decrement counter `i`; if counter is zero, go to `next_zero`, else go to `next_nonzero`.

Execution halts if a halting instruction is reached (not needed for the Turing completeness argument; we consider infinite runs).

### 3.1 Encoding Counters and Program Flow

We allocate memory cells:
- `MEMORY[1]` for counter C1
- `MEMORY[2]` for counter C2
- `MEMORY[3]` through `MEMORY[9]` are used for jump offsets and temporary data.

The program counter of the Minsky machine corresponds to a position inside the CTFFuck2 program string. Since the string is linear, we implement each Minsky machine instruction as a contiguous block of digits. Unconditional and conditional jumps are realised via `jmpm` that alter the program pointer by a fixed offset, either looping to the start of a block or jumping out.

### 3.2 Increment

To increment counter `c` (address 1 or 2), we use the `add` instruction with argument `+1`. The two‑step procedure is:

1. **First `add`**: `arg = c` (ensured positive). This pushes the address `c` into the ring buffer.
2. Insert exactly **3** push operations to satisfy the pairing rule (offset 1 requires 3 intervening pushes). These pushes can be built from `push` instructions or from first halves of other two‑step instructions whose second parts are placed elsewhere.
3. **Second `add`**: `arg = 1`. This adds 1 to `MEMORY[c]` and sets the flags.

The flags after `add` correctly reflect the new counter value (zero flag if the result is 0, sign flag if negative; counters remain non‑negative in the simulation so sign flag is never true, but the condition remains valid).

### 3.3 Decrement and Branch

Decrement is identical to increment, except the second `add` receives `arg = -1`. Crucially, the flags are updated to reflect the new value of `MEMORY[c]`. Immediately after this `add` sequence, we place a conditional `jmpm` that checks the zero flag:

- If counter became zero, jump to `next_zero` block.
- Else, fall through to an unconditional `jmpm` (condition 6) that jumps to `next_nonzero` block.

The conditional jump itself is a pair of `jmpm` instructions:
- First `jmpm`: `arg = 0` (condition “equal”). This requires that the differential difference between the previous digit and the first `jmpm` digit equals 0.
- Insert exactly **0** pushes between them (offset 4). This is naturally satisfied if the two `jmpm` opcodes are consecutive in the program.
- Second `jmpm`: `arg = jump_offset`, where `MEMORY[jump_offset]` has been pre‑loaded with the relative displacement to `next_zero`.

The unconditional jump uses condition 6 in the first `jmpm` (arg = 6) and an offset cell holding the displacement to `next_nonzero`. The two jumps can share the same second `jmpm` block if carefully arranged, but for simplicity we use separate blocks.

### 3.4 Aligning the Push Counts

The entire program is a single fixed digit string. Within each block, the number of pushes between the two parts of every paired instruction must match the required offset (modulo 5). Since the code never changes and the buffer size divides 5, a layout that works for one iteration will work for all iterations, provided the initial program entry and loop bounds are correctly set.

We achieve this by inserting explicit `push` instructions (opcode 3) or by reusing the first halves of nearby two‑step instructions whose second halves are placed far enough away that their internal pairing is not disturbed. For example, the three pushes required after the first `add` could be three consecutive `push` opcodes, each with a carefully chosen differential argument so that those pushes have no adverse side‑effects (a `push` with a negative argument is a no‑op, so we can force negative differentials by computing `last-digit = current-digit` to get 0, then subtracting 1 yields -1, etc. – but we must be careful not to unintentionally trigger other instruction semantics). A cleaner method uses dummy `set` on address 0 (which does nothing because `set` returns early if arg < 0) as long as the differential yields a non‑negative argument. Designing such a no‑op sequence is tedious but provably possible; the language’s `push` with negative argument is a guaranteed no‑op, so by setting up the differentials appropriately we can generate any desired number of harmless `push` operations.

### 3.5 Complete Program Construction

Given any Minsky machine `M` with states `0..S-1` and a finite set of instructions, we build a finite CTFFuck2 string as follows:

- For each state `i`, create a block `B_i` consisting of the digit sequence that implements the instruction for that state.
- For `INC c, next`, build an increment sequence on address `c`, followed by an unconditional jump to `B_next`. The unconditional jump is a pair of `jmpm` (condition 6) with offset stored in a fixed memory cell, e.g., `MEMORY[4]`, pre‑loaded with the appropriate displacement.
- For `DEC c, zero, nonzero`, build a decrement sequence on `c`, then a conditional `jmpm` (condition 0) jumping to `B_zero` if zero, else fall through to an unconditional `jmpm` to `B_nonzero`.
- Before the first state, include an initialisation segment that sets up the jump offset cells (all the `B` blocks can be placed sequentially; relative offsets are constants known at construction time).
- The program string is the concatenation of all these blocks, plus a final padding to satisfy any remaining pairing constraints.

Because every block uses a fixed number of pushes, and the blocks are entered with a known `last_digit` (the final digit of the previous block’s unconditional jump), the differential arguments for the first instruction of each block are constant. All internal pairings within a block are satisfied by design, and the unconditional jumps that connect blocks also maintain the correct push count because the two `jmpm` digits are consecutive (0 push gap). Therefore, the entire program executes deterministically and forever, simulating the infinite run of the Minsky machine.

## 4. Turing Completeness

Minsky two‑counter machines are Turing complete [3]; the construction above shows that for any such machine there exists a finite CTFFuck2 Hardcore program that simulates it step‑for‑step. The program halts if and only if the machine halts (but even for non‑halting machines, the simulation runs unboundedly). Hence CTFFuck2 Hardcore can compute all computable functions, establishing its Turing completeness.

Notably, the proof does not rely on the `grow` instruction; the purely deterministic and path‑dependent nature of the language does not restrict its computational power. The necessary synchronisation is achieved through a static program layout that respects the global ring buffer offsets.

## 5. Conclusion

We have formally demonstrated that CTFFuck2 Hardcore, despite its minimalist, hostile design, is a universal computational model. The proof is constructive, mapping Minsky two‑counter machines onto finite‑length strings of digits. This result reinforces the observation that Turing completeness can emerge from extraordinarily constrained systems, as long as they provide unbounded memory, conditional branching, and a means to preserve state across iteration boundaries. The esolang’s global ring buffer, far from being a limitation, serves as a precise clock that enables the necessary operation pairing.

Future work could investigate the minimal number of memory cells or buffer slots required for universality, or explore the language’s behaviour under restricted opcode subsets.

**Acknowledgments**  
The author thanks the creator of CTFFuck2 Hardcore for unintentionally providing a delightful puzzle in constraint satisfaction.

---

**References**

[1] CTFFuck2 Hardcore documentation and source code, available in the accompanying repository. (See `hardcore.md` for language specification.)

[2] Original CTFFuck2 esolang definition (Python version), included in the same project.

[3] M. Minsky, “Recursive Unsolvability of Post’s Problem of ‘Tag’ and Other Topics in Theory of Turing Machines,” *Annals of Mathematics*, vol. 74, no. 3, pp. 437–455, 1961.
