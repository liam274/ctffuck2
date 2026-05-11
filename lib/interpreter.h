#pragma once
#include <iostream>
#include <vector>
#include <string>
#include <array>
#include <algorithm>
#include <sstream>
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
void read(Ctx *ctx, short arg);
void add(Ctx *ctx, short arg);
void set(Ctx *ctx, short arg);
void push(Ctx *ctx, short arg);
void print(Ctx *ctx, short arg);
void swap(Ctx *ctx, short arg);
void grow(Ctx *ctx, short arg);
void inp(Ctx *ctx, short arg);
void jmpm(Ctx *ctx, short arg);
void revf(Ctx *ctx, short arg);

struct Ctx
{
    std::array<int, MEMORY_SIZE> MEMORY;
    bool zf = false, // zero flag
        sf = false,  // signed flag
        cf = false,  // control flag
        _if = true,  // input flag
        of = true;   // output flag
    short read_ind = 0, add_ind = 0, swap_ind = 0,
          grow_ind = 0, jmpm_ind = 0;
    data_type::fix_queue<int, total_length> stack;
    int transposus;
    bool transposus_ok = false;
    const unsigned char *pointer;
    const unsigned char *begin;
    std::string input;
    std::string func_name[MEMORY_SIZE] = {"read", "add", "set", "push", "print", "swap",
                                          "grow", "inp", "jmpm", "revf"};
    int flag_setter(int data)
    {
        zf = (data == 0);
        sf = (data < 0);
        return data;
    };
    std::array<short, MEMORY_SIZE> op_mapping = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
};

inline void print_debug(Ctx *ctx, short chr_int, short last)
{
    std::cout << separator;
    std::cout << "STACK\n| ";
    int p = ctx->stack.heap();
    for (int i = 0; i < total_length; i++)
    {
        if (i == p)
        {
            std::cout << "*";
        }
        std::cout << ctx->stack.true_at(i) << " | ";
    }
    std::cout << '\n';
    std::cout << separator;
    std::cout << "MEMORY\n| ";
    for (const int &cell : ctx->MEMORY)
    {
        std::cout << cell << " | ";
    }
    std::cout << '\n';
    std::cout << separator;
    std::cout << "FUNC_MEMORY\n| ";
    int t = 0;
    for (const std::string &name : ctx->func_name)
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

inline std::array<int, MEMORY_SIZE> run(std::stringstream &_data, const bool debug, std::string input = "")
{
    std::vector<unsigned char> data;
    data.reserve(_data.str().size());
    char chr;
    while (_data >> chr)
    {
        if (std::isdigit(chr))
        {
            data.push_back(static_cast<unsigned char>(chr - '0'));
        }
    }
    if (data.empty())
    {
        return PERSISTENT_MEMORY;
    }
    Ctx ctx;
    ctx.MEMORY = PERSISTENT_MEMORY;
    ctx.input = std::move(input);
    ctx.begin = data.data();
    ctx.pointer = data.data();
    TermiosRaw raw;
    short chr_int = *ctx.pointer;
    short last = chr_int * 2;
    const unsigned char *const end = data.data() + data.size();
    while (ctx.pointer++ < end || ctx.transposus_ok)
    {
        if (debug)
        {
            print_debug(&ctx, chr_int, last);
        }
        switch (ctx.op_mapping[chr_int])
        {
        case 0:
            read(&ctx, last - chr_int);
            break;
        case 1:
            add(&ctx, last - chr_int);
            break;
        case 2:
            set(&ctx, last - chr_int);
            break;
        case 3:
            push(&ctx, last - chr_int);
            break;
        case 4:
            print(&ctx, last - chr_int);
            break;
        case 5:
            swap(&ctx, last - chr_int);
            break;
        case 6:
            grow(&ctx, last - chr_int);
            break;
        case 7:
            inp(&ctx, last - chr_int);
            break;
        case 8:
            jmpm(&ctx, last - chr_int);
            break;
        case 9:
            revf(&ctx, last - chr_int);
            break;
        }
        last = chr_int;
        if (!ctx.transposus_ok)
        {
            chr_int = *ctx.pointer;
        }
        else
        {
            chr_int = ctx.transposus;
            ctx.transposus_ok = false;
        }
    }
    if (debug)
    {
        print_debug(&ctx, chr_int, last);
    }
    return ctx.MEMORY;
}