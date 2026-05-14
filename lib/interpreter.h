#pragma once
#include <iostream>
#include <vector>
#include <string>
#include <array>
#include <algorithm>
#include <sstream>
#include <termios.h>
#include <unistd.h>
#include "data-type.h"

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
using op_func = void (*)(Ctx *, int);
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
    const char *pointer;
    const char *begin;
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

inline void print_debug(Ctx *ctx, int chr_int, int last)
{
    std::cout << separator << "STACK\n| ";
    int p = ctx->stack.heap();
    for (int i = 0; i < total_length; i++)
    {
        if (i == p)
        {
            std::cout << "*";
        }
        std::cout << ctx->stack.true_at(i) << " | ";
    }
    std::cout << '\n'
              << separator << "MEMORY\n |";
    for (const int &cell : ctx->MEMORY)
    {
        std::cout << cell << " | ";
    }
    std::cout << '\n'
              << separator << "FUNC_MEMORY\n| ";
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
    std::cout << '\n'
              << separator << "last: " << last << "; arg: " << (last > -1 ? last - chr_int : chr_int) << '\n';
    std::cout << separator << '\n';
}

class TermiosRaw
{
private:
    struct termios orig_;
    int fd_;

public:
    explicit TermiosRaw(int fd = STDIN_FILENO) : fd_(fd)
    {
        tcgetattr(fd_, &orig_);
        struct termios raw = orig_;
        raw.c_lflag &= ~(ICANON | ECHO);
        raw.c_cc[VMIN] = 1;
        raw.c_cc[VTIME] = 0;
        tcsetattr(fd_, TCSANOW, &raw);
    }

    ~TermiosRaw()
    {
        tcsetattr(fd_, TCSANOW, &orig_);
    }
    TermiosRaw(const TermiosRaw &) = delete;
    TermiosRaw &operator=(const TermiosRaw &) = delete;
};

inline std::array<int, MEMORY_SIZE> run(const std::string &data, const bool debug,
                                        const std::string &input = "", const std::string &heading = "")
{
    if (data.size() == 0)
    {
        return PERSISTENT_MEMORY;
    }
    const std::size_t entry_point = heading.empty() ? 0 : data.find(heading);
    if (entry_point == std::string::npos)
    {
        return PERSISTENT_MEMORY;
    }
    Ctx ctx;
    ctx.MEMORY = PERSISTENT_MEMORY;
    ctx.input = std::move(input);
    ctx.pointer = data.data() + entry_point;
    ctx.begin = data.data() + entry_point;
    TermiosRaw raw;
    int chr_int;
    int last = -1;
    const char *const end = data.data() + data.size();
    while (ctx.pointer < end || ctx.transposus_ok)
    {
        if (!ctx.transposus_ok)
        {
            chr_int = *ctx.pointer++ - '0';
            if (chr_int >= MEMORY_SIZE || chr_int < 0)
            {
                continue;
            }
        }
        else
        {
            chr_int = ctx.transposus;
            ctx.transposus_ok = false;
        }
        if (last < 0)
        {
            last = chr_int + chr_int;
        }
        ctx.funcs[chr_int](&ctx, last - chr_int);
        if (debug)
        {
            print_debug(&ctx, chr_int, last);
        }
        last = chr_int;
    }
    return ctx.MEMORY;
}