#!/usr/bin/python
import argparse
import os
import sys
from getch import getch  # type: ignore
from typing import Callable, TextIO
from pprint import pprint

parser = argparse.ArgumentParser(description="ctffuck2 is a very brainy language")
parser.add_argument("--file", "-f", help="program file", type=str)
parser.add_argument("--debug", action="store_true", help="Enable debug mode")
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


def halt(arg: int):
    """stop the program"""
    sys.exit(arg)


def inp(arg: int):
    """get a char from console"""
    if arg < 0:
        return
    DATA_MEMORY[arg] = ord(getch())  # type: ignore


def jmpm(arg: int):
    """jmp to an offset in file, according to the mode given"""
    global pointer
    if len(STACK["jmpm"]):
        if pointer + arg < 0:
            return
        l: int = STACK["jmpm"][-1]
        if l == 0:
            if FLAGS["ZF"]:  # equal
                pointer = flag_setter(pointer + arg)
        elif l == 1:
            if not FLAGS["ZF"]:  # not equal
                pointer = flag_setter(pointer + arg)
        elif l == 2:
            if FLAGS["SF"]:  # smaller
                pointer = flag_setter(pointer + arg)
        elif l == 3:
            if not FLAGS["SF"]:  # bigger
                pointer = flag_setter(pointer + arg)
        elif l == 4:
            if FLAGS["ZF"] or FLAGS["SF"]:  # <=
                pointer = flag_setter(pointer + arg)
        elif l == 5:
            if FLAGS["ZF"] or not FLAGS["SF"]:  # >=
                pointer = flag_setter(pointer + arg)
        STACK["jmpm"].clear()
    else:
        if arg < 0:
            return
        STACK["jmpm"].append(arg)


def revf(arg: int):
    """reverse a flag"""
    if arg < 0:
        return
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
    length: int = len(data) - 1
    char: str
    last: int = -1
    while pointer < length:
        pointer += 1
        char = data[pointer]
        if char > "9" or char < "0":
            continue
        name: str = ACTION_MEMORY[int(char)].__name__
        if last == -1:
            ACTION_MEMORY[int(char)](int(char))
        else:
            ACTION_MEMORY[int(char)](last - int(char))
        last = int(char)
        if not CALLING or name != CALLING[0]:
            CALLING.append(name)
            if len(CALLING) > 2:
                STACK[CALLING[0]].clear()
                CALLING.pop()
        if len(STACK["push"]) and name != "push":
            STACK[name.lstrip("_")].append(STACK["push"].pop())
        if args.debug:
            print("-" * 50)
            print("STACK\n")
            pprint(STACK)
            print("-" * 50)
            print(f"action name: {name}")
            print("-" * 50)
            print(" |", " | ".join(str(i) for i in DATA_MEMORY), "|")
            print("-" * 50)
            print("CALLING: ", CALLING)


main()
