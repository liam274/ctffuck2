# CTFFUCK2

This is a very crazy language, a brain-teasing esoteric programming language interpreter written in Python. ctffuck2 is designed to challenge programmers with its unconventional syntax and stack-based architecture.

## Overview

ctffuck2 is a minimalistic yet powerful esolang that operates on:

- 10 memory cells (DATA_MEMORY) for integer storage
- Two status flags: Zero Flag (ZF) and Sign Flag (SF)
- Multiple operation stacks for managing instruction state
- Conditional jumps based on flag states
- The language uses a unique execution model where consecutive digits in the source file determine operations and their operands through subtraction logic.

## Features

10 Core Operations:

- `read` - Read from memory
- `add` - Increment memory values
- `set` - Reset memory cells to zero
- `push` - Push values onto operation stacks
- `print` - Output characters to console
- `swap` - Exchange values between memory cells
- `grow` - Modify the code itself
- `inp` - Read character input from console
- `jmpm` - Conditional jumps based on flag states
- `revf` - Toggle ZF or SF flags

### Flag System

Zero Flag (ZF): Set when data equals 0
Sign Flag (SF): Set when data is negative
Conditional jumps support 6 comparison modes (=, ≠, <, ≥, ≤, >)
Dual Output Streams: Supports both stdout and stderr

## Installation

### Requirements

- Python 3.8+
- getch library (`pip install getch`)

### Setup

```sh
git clone https://github.com/liam274/ctffuck2.git
cd ctffuck2
pip install -r requirements.txt
```

## Usage

Run a ctffuck2 program:

`python main.py --file program.ctf`
or
`python main.py -f program.ctf`

## Language Specification

### Memory Model

- DATA_MEMORY: Array of 10 integers (indices 0-9)
- All memory accesses are modulo 10
- Flags are automatically updated after operations

### Execution Flow

The interpreter reads the source file character by character:

1. Non-digit characters are ignored
2. Consecutive digits determine operations:
    - First digit selects the operation
    - Subsequent digits provide operands via subtraction logic

3. Operation stacks manage multi-step instructions

### Jump Modes (jmpm)

| Mode | Condition | Description         |
| ---- | --------- | ------------------- |
| 0    | ZF        | Jump if equal       |
| 1    | !ZF       | Jump if not equal   |
| 2    | SF        | Jump if smaller     |
| 3    | !SF       | Jump if bigger      |
| 4    | ZF ∨ SF   | Jump if ≤           |
| 5    | ZF ∨ !SF  | Jump if ≥           |
| 6    | True      | Jump no matter what |

## Development

## Adding New Operations

1. Define a new function in the global scope
2. Add it to ACTION_MEMORY list
3. Update STACK dictionary with a new key
4. Ensure proper integration with the execution loop

## Testing

Create test files in .ctf format and verify output:

`python main.py -f tests/test_basic.ctf`

## Contributing

Contributions are welcome! Please:

- Fork the repository
- Create a feature branch
- Submit a pull request with clear descriptions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Inspired by other esoteric languages like Brainfuck and Whitespace, ctffuck2 pushes the boundaries of minimalistic programming paradigms.

Note: This is an esoteric language primarily intended for educational purposes and CTF challenges. Production use is not recommended.
