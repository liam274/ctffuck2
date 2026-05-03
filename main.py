#!/usr/bin/python
import argparse
import os
import sys
import io
import random
from getch import getche  # type: ignore
from typing import Callable, TextIO, Generator
from pprint import pprint
from contextlib import redirect_stdout, redirect_stderr
from typing import Any


def run(
    data: str,
    _input: str = "",
    debug: bool = False,
    FS: list[TextIO] = [sys.stdout, sys.stderr],
    seed: int | None = None,
) -> Generator[tuple[dict[str, list[int]], list[int], list[str]], Any, Any]:
    """Run this to execute ctffuck v2.0"""
    random.seed(seed)
    input: list[str] = list(_input)
    STACK: dict[str, list[int]] = {
        "read": [],
        "add": [],
        "push": [],
        "print": [],
        "swap": [],
        "grow": [],
        "inp": [],
        "set": [],
        "jmpm": [],
        "revf": [],
    }
    pointer: int = -1
    transposus: list[int] = []

    def flag_setter(data: int) -> int:
        nonlocal zf, sf
        zf = data == 0
        sf = data < 0
        return data

    def read(arg: int):
        """read a memory"""
        if arg < 0:
            return
        if len(STACK["read"]):
            DATA_MEMORY[STACK["read"][-1] % 10] = flag_setter(DATA_MEMORY[arg % 10])
            STACK["read"].clear()
        else:
            STACK["read"].append(arg)

    def add(arg: int):
        """increase a box"""
        if len(STACK["add"]):
            DATA_MEMORY[STACK["add"][-1] % 10] = flag_setter(
                DATA_MEMORY[STACK["add"][-1] % 10] + arg
            )
            STACK["add"].clear()
        else:
            if arg < 0:
                return
            STACK["add"].append(arg)

    def _set(arg: int):
        """set a box to zero"""
        if arg < 0:
            return
        DATA_MEMORY[arg % 10] = flag_setter(0)

    def push(arg: int):
        """push a int to the next called"""
        if arg < 0:
            return
        STACK["push"] = [arg]

    def _print(arg: int):
        """print the char out to the console, at destination given"""
        if arg < 0:
            return
        if len(STACK["print"]):
            FS[arg].write(chr(DATA_MEMORY[STACK["print"][-1] % 10]))
            STACK["print"].clear()
        else:
            STACK["print"].append(arg)

    def swap(arg: int):
        """swap two box's func"""
        if arg < 0:
            return
        if len(STACK["swap"]):
            DATA_MEMORY[STACK["swap"][-1] % 10], DATA_MEMORY[arg % 10] = DATA_MEMORY[
                arg % 10
            ], flag_setter(DATA_MEMORY[STACK["swap"][-1] % 10])
            STACK["swap"].clear()
        else:
            STACK["swap"].append(arg)

    def grow(arg: int):
        """edit the code"""
        nonlocal action_names, ACTION_MEMORY
        if len(STACK["grow"]) > 1:
            method: int = STACK["grow"][-1]
            spindle: int = STACK["grow"][-2]
            arg += random.randint(-3, 3)
            if method == 1:
                transposus.append((spindle + arg) % 10)
            elif method == 2:
                transposus.append(abs(spindle - arg) % 10)
            elif method == 3:
                transposus.append(spindle % (arg or 1))
            elif method == 4:
                transposus.append((spindle * arg) % 10)
            elif method == 5:
                ACTION_MEMORY[spindle], ACTION_MEMORY[arg] = (
                    ACTION_MEMORY[spindle],
                    ACTION_MEMORY[arg],
                )
                action_names[spindle], action_names[arg] = (
                    action_names[arg],
                    action_names[spindle],
                )
            elif method == 8:
                random.shuffle(ACTION_MEMORY)
                action_names = [f.__name__.lstrip("_") for f in ACTION_MEMORY]
            STACK["grow"].clear()
        else:
            STACK["grow"].append(arg)

    def inp(arg: int):
        """get a char from console"""
        if arg < 0:
            return
        if input:
            DATA_MEMORY[arg] = ord(input.pop())
        else:
            DATA_MEMORY[arg] = ord(getche())  # type: ignore

    def jmpm(arg: int):
        """jmp to an offset in file, according to the mode given"""
        nonlocal pointer
        if len(STACK["jmpm"]):
            if pointer + arg < 0:
                return
            l: int = STACK["jmpm"][-1]
            if l > len(JUMP_COND):
                return
            if JUMP_COND[l]():
                pointer = flag_setter(pointer + arg)
            STACK["jmpm"].clear()
        else:
            if arg < 0:
                return
            STACK["jmpm"].append(arg)

    def revf(arg: int):
        """reverse a flag"""
        nonlocal zf, sf
        if arg < 0:
            return
        if arg == 0:
            zf = not zf
        elif arg == 1:
            sf = not sf

    ACTION_MEMORY: list[Callable[[int], None]] = [
        read,
        add,
        _set,
        push,
        _print,
        swap,
        grow,
        inp,
        jmpm,
        revf,
    ]
    DATA_MEMORY: list[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    zf: bool = False
    sf: bool = False
    JUMP_COND: list[Callable[[], bool]] = [
        lambda: zf,
        lambda: not zf,
        lambda: sf,
        lambda: not sf,
        lambda: zf or sf,
        lambda: zf or not sf,
        lambda: True,
    ]
    CALLING: list[str] = []
    length: int = len(data) - 1
    char: str
    last: int = -1
    action_names: list[str] = [f.__name__.lstrip("_") for f in ACTION_MEMORY]
    try:
        while pointer < length or transposus:
            if transposus:
                char_int: int = transposus.pop()
            else:
                pointer += 1
                char = data[pointer]
                if char > "9" or char < "0":
                    continue
                char_int: int = ord(char) - 48
            name: str = action_names[char_int]
            if last == -1:
                ACTION_MEMORY[char_int](char_int)
            else:
                ACTION_MEMORY[char_int](last - char_int)
            last = char_int
            if not CALLING or name != CALLING[0]:
                CALLING.append(name)
                if len(CALLING) > 2:
                    STACK[CALLING[0]].clear()
                    CALLING.pop()
            if len(STACK["push"]) and name != "push":
                STACK[name].append(STACK["push"].pop())
            yield STACK, DATA_MEMORY, CALLING
            if debug:
                print("-" * 50)
                print("STACK\n")
                pprint(STACK)
                print("-" * 50)
                print(f"action name: {name}")
                print("-" * 50)
                print(" |", " | ".join(str(i) for i in DATA_MEMORY), "|")
                print("-" * 50)
                print("CALLING: ", CALLING)
    except KeyboardInterrupt:
        print("Interrupted by user...")


def main():
    """main proc"""
    parser = argparse.ArgumentParser(description="ctffuck2 is a very brainy language")
    parser.add_argument("--file", "-f", help="program file", type=str)
    parser.add_argument("--debug", action="store_true", help="Enable debug mode")
    args = parser.parse_args()
    if not os.path.exists(args.file):
        print(
            f'Error occurred when trying to open file "{args.file}", which does not exists.'
        )
        sys.exit(1)
    data: str
    with open(args.file, "r") as file:
        data = file.read().strip()
    fun_ctffuck2(data, debug=args.debug)


def fun_ctffuck2(
    data: str,
    _input: str = "",
    debug: bool = False,
    FS: list[TextIO] = [sys.stdout, sys.stderr],
    is_file: bool = False,
    capture_output: bool = True,
    as_generator: bool = False,
):
    """Though fun is a typo, but it's really fun!"""
    if is_file:
        with open(data, "r") as file:
            data = file.read().strip()
    if capture_output:
        stdout: TextIO = io.StringIO()
        stderr: TextIO = io.StringIO()
        with redirect_stderr(stderr), redirect_stdout(stdout):
            return (
                run(data, _input, debug, FS)
                if as_generator
                else list(i[1] for i in run(data, _input, debug, FS))
            ), stdout.getvalue()
    return (
        run(data, _input, debug, FS)
        if as_generator
        else list(i[1] for i in run(data, _input, debug, FS))
    ), ""


if __name__ == "__main__":
    main()
