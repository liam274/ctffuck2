# Application CTFFuck2 Interface

## Table of Contents

- [Sanitize Query](#sanitize-query)

## Sanitize Query

This query will sanitize the entire stack

Repeat `3` stack_length+1 times. For example: `333333`

## Module format

Module caller shall set the CF on before calling, while the module itself shell set CF off when it's done.
Thus, modules' caller and themselves, shall use CF-based jumping conditions.

Module callers must ensure the stack is sanitized on calling, to ensure the module works just as expected.

## Memory Protocol

- [Super-Volatile Memory Point](#super-volatile-memory-point): 0
- [Volatile Memory Points](#volatile-memory-points): 1-5
- [Nonvolatile Memory Points](#nonvolatile-memory-points): 6-9

## Terminologies

### Super-Volatile Memory Point

This point's value shall never be considered, or used. Thus, any modules can dump random values into it, for keeping other parts of memory clean.

### Volatile Memory Points

These points' value will **NOT** be preserved, module callers should expect. Thus, no module has the responsibility to preserve values.

### Nonvolatile Memory points

These points' value **WILL** be preserved, module callers will expect. Thus, any module follows ACI must
ensure that on return, these values are as what they are at the beginning.
