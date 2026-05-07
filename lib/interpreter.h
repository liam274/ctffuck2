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

constexpr std::array<int, MEMORY_SIZE> PERSISTENT_MEMORY = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

struct Ctx;
using op_func = void (*)(Ctx *, int);
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
    std::array<int, MEMORY_SIZE> MEMORY;
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

inline std::array<int, MEMORY_SIZE> &run(const std::string &data, const bool debug, std::string input = "", int smallest_size = 1024)
{
    Ctx ctx;
    ctx.length = data.size();
    ctx.transposus.reserve(1024);
    ctx.MEMORY = PERSISTENT_MEMORY;
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