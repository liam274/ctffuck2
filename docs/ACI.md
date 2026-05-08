# Application CTFFuck2 Interface - ACI

## Table of Contents

- [Terms of Art](#terms-of-art)
- [Specific Query](#specific-query)
- [Module Standard Format](#module-standard-format)
- [Memory Protocol](#memory-protocol)
- [Terminologies](#terminologies)

## Terms of Art

| name        | definition                                                                                                                                                                                                                                                                                                         |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `stack`     | In CTFFuck2 series, commands which receive multiple arguments will push its argument received(If the number is not enough, yet). Note that all the commands share a same cyclical buffer, in Hardcore. And thus, `stack.at(0)` points to the newest value, while `stack.at(-1)` points to the oldest value pushed. |
| `memory`    | In CTFFuck2 series, commands share a `int[10]` array, as memory                                                                                                                                                                                                                                                    |
| stack cycle | A stack cycle, means the head pointer runs around the stack one time                                                                                                                                                                                                                                               |

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

## Module Standard Format

Module caller shall set the [CF](#cf---control-flag) on before calling, while the module itself shell set [CF](#cf---control-flag) off when it's done.
Thus, modules' caller and themselves, shall use CF-based jumping conditions.

```ctffuck2
79; This shall reverse the value of CF.
```

Module callers must ensure the stack is sanitized on calling, to ensure the module works just as expected.

## Memory Protocol

- [Super-Volatile Memory Point](#super-volatile-memory-point): 0
- [Volatile Memory Points](#volatile-memory-points): 1-5
- [Nonvolatile Memory Points](#nonvolatile-memory-points): 6-9

## Terminologies

### Super-Volatile Memory Point

Any modules do whatever they'd like to to that point.
Thus, this point's value shall never be considered, or used.

### Volatile Memory Points

These points' value will **NOT** be preserved, module callers should expect. Thus, no module has the responsibility to preserve values.

### Nonvolatile Memory points

These points' value **WILL** be preserved, module callers will expect. Thus, any module follows ACI must
ensure that on return, these values are as what they are at the beginning.

## CF - Control Flag

Control flag is a flag, which can be set by `revf(2)`. It doesn't have an official usage,
so you may use it in whatever way you'd like to. But in this ACI, we **STRONGLY** suggested
you to use it for controlling execution flow. _Please note that when the program begins, CF=false_
