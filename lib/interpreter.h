#pragma once
#include <iostream>
#include <vector>
#include <string>
#include <unordered_map>
#include <array>
#include <functional>
#include <algorithm>
#include <deque>
#include <cassert>
#include <cstring>
#include "data-type.h"
#include "algorithm.h"

using op_func = void (*)(Ctx *, int);

constexpr short MEMORY_SIZE = 10;
constexpr short read_stack_length = 1, add_stack_length = 1,
                set_stack_length = 0, push_stack_length = 0,
                print_stack_length = 0, swap_stack_length = 1,
                grow_stack_length = 1, inp_stack_length = 0,
                jmpm_stack_length = 1, revf_stack_length = 0;
constexpr short read_offset = 0, add_offset = read_stack_length,
                set_offset = add_offset + add_stack_length,
                push_offset = set_offset + set_stack_length,
                print_offset = push_offset + push_stack_length,
                swap_offset = print_offset + print_stack_length,
                grow_offset = swap_offset + swap_stack_length,
                inp_offset = grow_offset + grow_stack_length,
                jmpm_offset = inp_offset + inp_stack_length,
                revf_offset = jmpm_offset + jmpm_stack_length;

constexpr char separator[52] = {'-', '-', '-', '-', '-', '-', '-', '-', '-',
                                '-', '-', '-', '-', '-', '-', '-', '-', '-',
                                '-', '-', '-', '-', '-', '-', '-', '-', '-',
                                '-', '-', '-', '-', '-', '-', '-', '-', '-',
                                '-', '-', '-', '-', '-', '-', '-', '-',
                                '-', '-', '-', '-', '-', '-', '\n', '\0'};

constexpr short total_length = revf_offset + revf_stack_length;

constexpr int PERSISTENT_MEMORY[MEMORY_SIZE] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
void read(Ctx *ctx, int arg);
void add(Ctx *ctx, int arg);
void set(Ctx *ctx, int arg);
void push(Ctx *ctx, int arg);
void print(Ctx *ctx, int arg);
void swap(Ctx *ctx, int arg);
void grow(Ctx *ctx, int arg);
void inp(Ctx *ctx, int arg);
void jmpm(Ctx *ctx, int arg);
void revf(Ctx *ctx, int arg);
struct Ctx
{
    int MEMORY[MEMORY_SIZE];
    bool zf = false, // zero flag
        sf = false,  // signed flag
        cf = false;  // control flag
    short read_ind = 0, add_ind = 0, swap_ind = 0,
          grow_ind = 0, jmpm_ind = 0;
    data_type::fix_queue<int> stack;
    std::vector<int> transposus;
    int pointer = 0;
    int length;
    std::string input;
    std::string func_name[MEMORY_SIZE] = {"read", "add", "set", "push", "print", "swap",
                                          "grow", "inp", "jmpm", "revf"};
    op_func funcs[MEMORY_SIZE] = {&read, &add, &set, &push, &print, &swap, &grow, &inp, &jmpm, &revf};
    int flag_setter(int data)
    {
        zf = (data == 0);
        sf = (data < 0);
        return data;
    };
};
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
    ctx->MEMORY[arg] = ctx->flag_setter(0);
};
void push(Ctx *ctx, int arg)
{
    arg = abs(arg);
    ctx->stack.push(arg);
};
void print(Ctx *ctx, int arg)
{
    arg = abs(arg);
    std::cout << (char)(ctx->MEMORY[arg]);
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
            res = ctx->flag_setter(res % (spindle or 1));
            break;
        case 4:
            res = spindle;
            break;
        case 5:
            op_func temp = ctx->funcs[arg];
            ctx->funcs[arg] = ctx->funcs[res];
            ctx->funcs[res] = temp;
            std::swap(ctx->func_name[arg], ctx->func_name[res]);
            break;
        }
        ctx->transposus.push_back(res);
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
    arg = abs(arg);
    if (!ctx->input.empty())
    {
        ctx->MEMORY[arg] = ctx->input.back();
        ctx->input.pop_back();
    }
    else
    {
        ctx->MEMORY[arg] = std::cin.get();
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
        if (result && ctx->pointer + ctx->MEMORY[arg] > 0)
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
    if (arg == 0)
    {
        ctx->zf = !ctx->zf;
    }
    else if (arg == 1)
    {
        ctx->sf = !ctx->sf;
    }
    else if (arg == 2)
    {
        ctx->cf = !ctx->cf;
    }
};
inline int (&run(const std::string &data, const bool debug, std::string input = "", int smallest_size = 1024)) [MEMORY_SIZE]
{
    Ctx ctx;
    ctx.length = data.size();
    ctx.transposus.reserve(1024);
    std::memcpy(ctx.MEMORY, PERSISTENT_MEMORY, sizeof(PERSISTENT_MEMORY));
    ctx.input = std::move(input);
    char chr;
    short last = -1;
    TermiosRaw raw;
    while (ctx.pointer < ctx.length || !ctx.transposus.empty())
    {
        int chr_int;
        if (ctx.transposus.empty())
        {
            chr = data[ctx.pointer++];
            if (chr >= '0' + MEMORY_SIZE or chr < '0')
            {
                continue;
            }
            chr_int = chr - '0';
        }
        else
        {
            chr_int = ctx.transposus.back();
            ctx.transposus.pop_back();
        }
        assert((chr_int < 0 || chr > 9) && "Error occurred when executing given code, found chr_int too big");
        if (debug)
        {
            std::cout << separator;
            std::cout << "MEMORY\n| ";
            for (const int &cell : ctx.MEMORY)
            {
                std::cout << cell << " | ";
            }
            std::cout << '\n';
            std::cout << separator;
            std::cout << "FUNC_MEMORY\n| ";
            int t = 0;
            for (const std::string &name : ctx.func_name)
            {
                if (t == chr_int)
                {
                    std::cout << "> ";
                }
                std::cout << name << " | ";
                t++;
            }
            std::cout << '\n';
            std::cout << separator;
            std::cout << "last: " << last << "; arg: "
                      << (last > -1 ? last - chr_int : chr_int) << '\n';
            std::cout << separator;
            std::cout << '\n';
            std::cout << std::flush;
        }
        if (last > -1)
        {
            ctx.funcs[chr_int](&ctx, last - chr_int);
        }
        else
        {
            ctx.funcs[chr_int](&ctx, chr_int);
        }
        last = chr_int;
    }
    return ctx.MEMORY;
};