# Application CTFFuck2 Interface - ACI

## Introduction

To whom are reading this:

If you use this ACI to program, you are a coward who doesn't willing to face _CTFFuck2_'s strength.
This document is for formatting _CTFFuck2_ codes, so as to make using it to program a lot easier.

So if you're for challenge, [get back](/README.md), please.

If you're for showing-off, scroll down.

## Table of Contents

- [Terms of Art](#terms-of-art)
- [Specific Query](#specific-query)
- [Standard](#standard)
- [Memory Protocol](#memory-protocol)
- [Terminologies](#terminologies)

---

## Terms of Art

| name        | definition                                                                                                                                                                                                                                                                                                         |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `stack`     | In CTFFuck2 series, commands which receive multiple arguments will push its argument received(If the number is not enough, yet). Note that all the commands share a same cyclical buffer, in Hardcore. And thus, `stack.at(0)` points to the newest value, while `stack.at(-1)` points to the oldest value pushed. |
| `memory`    | In CTFFuck2 series, commands share a `int[10]` array, as memory                                                                                                                                                                                                                                                    |
| stack cycle | A stack cycle, means the head pointer runs around the stack one time                                                                                                                                                                                                                                               |

---

## Specific Query

### Index

| query                       | function              |
| --------------------------- | --------------------- |
| [Sanitize](#sanitize-query) | Sanitize the stack    |
| [Set](#set-query)           | Set stack to all ones |

### Sanitize Query

This query will sanitize the entire stack.

Repeat `3` stack_length+1 times. For example: `333333`

### Set Query

Repeat `34` stack_length times, and add `3`. For example: `34343434343`

---

## Standard

1. Module caller shall set the [CF](#cf---control-flag) on before calling, while the module itself shell set [CF](#cf---control-flag) off when it's done.
   Thus, modules' caller and themselves, shall use CF-based jumping conditions.

    ```ctffuck2
    79; This shall reverse the value of CF.
    ```

2. Module callers must ensure the stack is sanitized on calling, to ensure the module works just as expected.

3. Module must ensure [ZF](#zf---zero-flag)=0,[SF](#sf---sign-flag)=0,[CF](#cf---control-flag)=0,
   [\_IF](#_if---input-flag)=1,[OF](#of---output-flag)=1 when returning, and module should expect that, too.

### Align

Commands must align to the stack length(as standard, it's 5), to ensure the command is accessing the correct command.
May you use `3`s to do so, but that's very ugly.

---

## Memory Protocol

- [Super-Volatile Memory Point](#super-volatile-memory-point): 0
- [Volatile Memory Points](#volatile-memory-points): 1-5
- [Nonvolatile Memory Points](#nonvolatile-memory-points): 6-9

---

## Terminologies

### Super-Volatile Memory Point

Any modules do whatever they'd like to to that point.
Thus, this point's value shall never be considered, or used.

### Volatile Memory Points

These points' value will **NOT** be preserved, module callers should expect. Thus, no module has the responsibility to preserve values.

### Nonvolatile Memory points

These points' value **WILL** be preserved, module callers will expect. Thus, any module follows ACI must
ensure that on return, these values are as what they are at the beginning.

## Flags

### ZF - Zero Flag

This flag will be set when the value calculated is zero.

### SF - Sign Flag

This flag will be set when the value's highest bit is set.

### CF - Customized Flag

Customized flag is a flag, which can be set by `revf(2)`. It doesn't have an official usage,
so you may use it in whatever way you'd like to. But in this ACI, we **STRONGLY** suggested
you to use it for controlling execution flow. _Please note that when the program begins, CF=false_

### \_IF - Input Flag

Input flag is a flag, which can be set by `revf(3)`. This flag will disable the input command
(though you may still call it.)

### OF - Output Flag

Output flag is a flag, which can be set by `revf(4)`. THis flag will disable the output command
(though you may still call it.)
