#!/usr/bin/python
import argparse
import os
import sys
from typing import Callable

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

CALLING: set[str] = set()


def read(arg: int):
    """read a memory"""


def add(arg: int):
    """increase a box"""


def _set(arg: int):
    """set a box to zero"""


def push(arg: int):
    """push a int to the next called"""


def _print(arg: int):
    """print the char out to the console, at destination given"""


def swap(arg: int):
    """swap two box's func"""


def halt(arg: int):
    """stop the program"""


def inp(arg: int):
    """get a char from console"""


def jmpm(arg: int):
    """jmp to an offset in file, according to the mode given"""


def revf(arg: int):
    """reverse a flag"""


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
