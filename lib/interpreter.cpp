#include "interpreter.h"

void read(Ctx *ctx, int arg)
{
    if (ctx->read_ind)
    {
        ctx->MEMORY[ctx->stack.at(read_offset)] = ctx->flag_setter(ctx->MEMORY[arg]);
        ctx->read_ind = 0;
    }
    else
    {
        ctx->stack.push(arg);
        ctx->read_ind++;
    }
};
void add(Ctx *ctx, int arg)
{
    if (ctx->add_ind)
    {
        ctx->MEMORY[ctx->stack.at(add_offset)] = ctx->flag_setter(arg + ctx->MEMORY[ctx->stack.at(add_offset)]);
        ctx->add_ind = 0;
    }
    else
    {
        ctx->stack.push(abs(arg));
        ctx->add_ind++;
    }
};
void set(Ctx *ctx, int arg)
{
    arg = abs(arg);
    ctx->MEMORY[arg] = 0;
    ctx->sf = false;
    ctx->zf = true;
};
void push(Ctx *ctx, int arg)
{
    arg = abs(arg);
    ctx->stack.push(arg);
};
void print(Ctx *ctx, int arg)
{
    if (!ctx->of)
    {
        return;
    }
    arg = abs(arg);
    if (ctx->MEMORY[arg]) // never print null
    {
        putchar(ctx->MEMORY[arg]);
    }
};
void swap(Ctx *ctx, int arg)
{
    arg = abs(arg);
    if (ctx->swap_ind)
    {
        const int temp = ctx->MEMORY[arg];
        ctx->MEMORY[arg] = ctx->MEMORY[ctx->stack.at(swap_offset)];
        ctx->MEMORY[ctx->stack.at(swap_offset)] = temp;
        ctx->swap_ind = 0;
    }
    else
    {
        ctx->stack.push(arg);
        ctx->swap_ind++;
    }
};
void grow(Ctx *ctx, int arg)
{
    arg = abs(arg);
    if (ctx->grow_ind)
    {
        int res = ctx->stack.at(grow_offset),
            spindle = ctx->MEMORY[arg];
        switch (arg)
        {
        case 0:
            res = ctx->flag_setter(res + spindle) % 10;
            break;
        case 1:
            res = abs(ctx->flag_setter(res - spindle)) % 10;
            break;
        case 2:
            res = ctx->flag_setter(res * spindle) % 10;
            break;
        case 3:
            res = ctx->flag_setter(res % (spindle ? spindle : 1));
            break;
        case 4:
            res = spindle % 10;
            break;
        case 5:
            res = abs(res % 10);
            op_func temp = ctx->funcs[arg];
            ctx->funcs[arg] = ctx->funcs[res];
            ctx->funcs[res] = temp;
            std::swap(ctx->func_name[arg], ctx->func_name[res]);
            break;
        }
        ctx->transposus = res;
        ctx->transposus_ok = true;
        ctx->grow_ind = 0;
    }
    else
    {
        ctx->grow_ind++;
        ctx->stack.push(arg);
    }
};
void inp(Ctx *ctx, int arg)
{
    if (!ctx->_if)
    {
        return;
    }
    arg = abs(arg);
    if (!ctx->input.empty())
    {
        ctx->MEMORY[arg] = ctx->input.back();
        ctx->input.pop_back();
    }
    else
    {
        int temp = getchar();
        if (temp == EOF)
        {
            ctx->MEMORY[arg] = -1;
        }
        else
        {
            ctx->MEMORY[arg] = temp;
            putchar(temp);
        }
    }
};
void jmpm(Ctx *ctx, int arg)
{
    arg = abs(arg);
    if (ctx->jmpm_ind)
    {
        bool result = false;
        switch (ctx->stack.at(jmpm_offset))
        {
        case 0: // equal
            result = ctx->zf;
            break;
        case 1: // not equal
            result = !ctx->zf;
            break;
        case 2: // smaller
            result = ctx->sf;
            break;
        case 3: // bigger-or-equal
            result = !ctx->sf;
            break;
        case 4: // smaller-or-equal
            result = ctx->sf || ctx->zf;
            break;
        case 5:
            result = !(ctx->sf || ctx->zf);
            break;
        case 6:
            result = true;
            break;
        case 7:
            result = ctx->cf;
            break;
        };
        if (result && ctx->pointer + ctx->MEMORY[arg] >= 0)
        {
            ctx->pointer += ctx->MEMORY[arg];
        }
        ctx->jmpm_ind = 0;
    }
    else
    {
        ctx->stack.push(arg);
        ctx->jmpm_ind++;
    }
};
void revf(Ctx *ctx, int arg)
{
    arg = -arg;
    switch (arg)
    {
    case 0:
        ctx->zf = !ctx->zf;
        break;
    case 1:
        ctx->sf = !ctx->sf;
        break;
    case 2:
        ctx->cf = !ctx->cf;
        break;
    case 3:
        ctx->_if = !ctx->_if;
        break;
    case 4:
        ctx->of = !ctx->of;
        break;
    };
};