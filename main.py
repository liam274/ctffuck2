#!/usr/bin/python
import argparse
import os
import sys
from getch import getch  # type: ignore
from typing import Callable, TextIO

parser = argparse.ArgumentParser(description="ctffuck2 is a very brainy language")
parser.add_argument("--file", "-f", help="program file", type=str)
args = parser.parse_args()
if not os.path.exists(args.file):
    print(
        f'Error occurred when trying to open file "{args.file}", which does not exists.'
    )
    sys.exit(1)

STACK: dict[str, list[int]] = {
    "read": [],
    "add": [],
    "push": [],
    "print": [],
    "swap": [],
    "halt": [],
    "inp": [],
    "set": [],
    "jmpm": [],
    "revf": [],
}


def flag_setter(data: int) -> int:
    FLAGS["ZF"] = data == 0
    FLAGS["SF"] = data < 0
    return data


def read(arg: int):
    """read a memory"""
    if len(STACK["read"]):
        DATA_MEMORY[STACK["read"][-1]] = flag_setter(DATA_MEMORY[arg])
        STACK["read"].clear()
    else:
        STACK["read"].append(arg)


def add(arg: int):
    """increase a box"""
    if len(STACK["add"]):
        DATA_MEMORY[STACK["add"][-1]] = flag_setter(
            DATA_MEMORY[STACK["add"][-1]] + DATA_MEMORY[arg]
        )
        STACK["add"].clear()
    else:
        STACK["add"].append(arg)


def _set(arg: int):
    """set a box to zero"""
    DATA_MEMORY[arg] = flag_setter(0)


def push(arg: int):
    """push a int to the next called"""
    STACK["push"] = [arg]


def _print(arg: int):
    """print the char out to the console, at destination given"""
    if len(STACK["print"]):
        FS[arg].write(chr(DATA_MEMORY[STACK["print"][-1]]))
        STACK["print"].clear()
    else:
        STACK["print"].append(arg)


def swap(arg: int):
    """swap two box's func"""
    if len(STACK["swap"]):
        DATA_MEMORY[STACK["swap"][-1]], DATA_MEMORY[arg] = DATA_MEMORY[
            arg
        ], flag_setter(DATA_MEMORY[STACK["swap"][-1]])
        STACK["swap"].clear()
    else:
        STACK["swap"].append(arg)


def halt(arg: int):
    """stop the program"""
    sys.exit(arg)


def inp(arg: int):
    """get a char from console"""
    DATA_MEMORY[arg] = getch()


def jmpm(arg: int):
    """jmp to an offset in file, according to the mode given"""
    global pointer
    if len(STACK["jmpm"]):
        l: int = STACK["jmpm"][-1]
        if l == 0:
            if FLAGS["ZF"]:  # equal
                pointer += arg
        elif l == 1:
            if not FLAGS["ZF"]:  # not equal
                pointer += arg
        elif l == 2:
            if FLAGS["SF"]:  # smaller
                pointer += arg
        elif l == 3:
            if not FLAGS["SF"]:  # bigger
                pointer += arg
        elif l == 4:
            if FLAGS["ZF"] or FLAGS["SF"]:  # <=
                pointer += arg
        elif l == 5:
            if FLAGS["ZF"] or not FLAGS["SF"]:  # >=
                pointer += arg
        STACK["jmpm"].clear()
    else:
        STACK["jmpm"].append(arg)


def revf(arg: int):
    """reverse a flag"""
    if arg == 0:
        FLAGS["ZF"] = not FLAGS["ZF"]
    elif arg == 1:
        FLAGS["SF"] = not FLAGS["SF"]


ACTION_MEMORY: list[Callable[[int], None]] = [
    read,
    add,
    _set,
    push,
    _print,
    swap,
    halt,
    inp,
    jmpm,
    revf,
]
DATA_MEMORY: list[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
FLAGS: dict[str, bool] = {"ZF": False, "SF": False}
FS: list[TextIO] = [sys.stdout, sys.stderr]
pointer: int = -1
CALLING: list[str] = []


def main():
    global pointer
    data: str
    with open(args.file, "r") as file:
        data = file.read().strip()
    length: int = len(data)
    char: str
    last: int = -1
    while pointer < length:
        pointer += 1
        char = data[pointer]
        if char > "9" or char < "0":
            pass
        if last == -1:
            ACTION_MEMORY[int(char)](int(char))
        else:
            ACTION_MEMORY[int(char)](last - int(char))
        last = int(char)
        CALLING.append(ACTION_MEMORY[last].__name__)
        if len(CALLING) > 2:
            STACK[CALLING[-1]].clear()
            CALLING.pop()
