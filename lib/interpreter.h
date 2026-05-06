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
inline int (&run(const std::string &data, const bool debug, std::string input = "")) [MEMORY_SIZE]
{
    static int MEMORY[MEMORY_SIZE] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    bool zf = false, sf = false;

    auto flag_setter = [&](int data) -> int
    {
        zf = (data == 0);
        sf = (data < 0);
        return data;
    };
    short read_ind = 0, add_ind = 0, swap_ind = 0,
          grow_ind = 0, jmpm_ind = 0;
    data_type::fix_queue<int> stack(revf_offset + revf_stack_length);
    int pointer = 0,
        length = data.size();
    std::vector<int> transposus;
    std::array<std::function<void(int)>, 10>
        funcs;
    std::string func_name[MEMORY_SIZE] = {"read", "add", "set", "push", "print", "swap",
                                          "grow", "inp", "jmpm", "revf"};
    auto read = [&](int arg) -> void
    {
        if (arg < 0)
        {
            return;
        }
        if (read_ind)
        {
            MEMORY[stack.at(read_offset)] = flag_setter(MEMORY[arg]);
            read_ind = 0;
        }
        else
        {
            stack.push(arg);
            read_ind++;
        }
    };
    auto add = [&](int arg) -> void
    {
        if (add_ind)
        {
            MEMORY[stack.at(add_offset)] = flag_setter(arg + MEMORY[stack.at(add_offset)]);
            add_ind = 0;
        }
        else
        {
            if (arg > 0)
            {
                stack.push(arg);
                add_ind++;
            }
        }
    };
    auto set = [&](int arg) -> void
    {
        if (arg < 0)
        {
            return;
        }
        MEMORY[arg] = flag_setter(0);
    };
    auto push = [&](int arg) -> void
    {
        if (arg < 0)
        {
            return;
        }
        stack.push(arg);
    };
    auto print = [&](int arg) -> void
    {
        if (arg < 0)
        {
            return;
        }
        std::cout << (char)(MEMORY[arg]);
    };
    auto swap = [&](int arg) -> void
    {
        if (arg < 0)
        {
            return;
        }
        if (swap_ind)
        {
            const int temp = MEMORY[arg];
            MEMORY[arg] = MEMORY[stack.at(swap_offset)];
            MEMORY[stack.at(swap_offset)] = temp;
            swap_ind = 0;
        }
        else
        {
            stack.push(arg);
            swap_ind++;
        }
    };
    auto grow = [&](int arg) -> void
    {
        if (arg < 0)
        {
            return;
        }
        if (grow_ind)
        {
            int res = stack.at(grow_offset),
                spindle = MEMORY[arg];
            switch (arg)
            {
            case 0:
                res = flag_setter(res + spindle) % 10;
                break;
            case 1:
                res = abs(flag_setter(res - spindle)) % 10;
                break;
            case 2:
                res = flag_setter(res * spindle) % 10;
                break;
            case 3:
                res = flag_setter(res % (spindle or 1));
                break;
            case 4:
                res = spindle;
                break;
            case 5:
                std::swap(funcs[arg], funcs[res]);
                std::swap(func_name[arg], func_name[res]);
                break;
            }
            transposus.push_back(res);
            grow_ind = 0;
        }
        else
        {
            grow_ind++;
            stack.push(arg);
        }
    };
    auto inp = [&](int arg) -> void
    {
        if (arg > 0)
        {
            if (!input.empty())
            {
                MEMORY[arg] = input.back();
                input.pop_back();
            }
            else
            {
                MEMORY[arg] = std::cin.get();
            }
        }
    };
    auto jmpm = [&](int arg) -> void
    {
        if (arg < 0)
        {
            return;
        }
        if (jmpm_ind)
        {
            bool result = false;
            switch (stack.at(jmpm_offset))
            {
            case 0: // equal
                result = zf;
                break;
            case 1: // not equal
                result = !zf;
                break;
            case 2: // smaller
                result = sf;
                break;
            case 3: // bigger-or-equal
                result = !sf;
                break;
            case 4: // smaller-or-equal
                result = sf || zf;
                break;
            case 5:
                result = !(sf || zf);
                break;
            case 6:
                result = true;
                break;
            };
            if (result)
            {
                if (pointer + MEMORY[arg] < 0)
                {
                    return;
                }
                pointer += MEMORY[arg];
            }
            jmpm_ind = 0;
        }
        else
        {
            stack.push(arg);
            jmpm_ind++;
        }
    };
    auto revf = [&](int arg) -> void
    {
        if (arg & 1)
        {
            zf = !zf;
        }
        else
        {
            sf = !sf;
        }
    };
    funcs = {read, add, set, push, print, swap, grow, inp, jmpm, revf};
    char chr;
    short last = -1;
    TermiosRaw raw;
    while (pointer < length || transposus.size() > 0)
    {
        int chr_int;
        if (transposus.size())
        {
            chr_int = transposus.back();
            transposus.pop_back();
        }
        else
        {
            chr = data[pointer++];
            if (chr >= '0' + MEMORY_SIZE or chr < '0')
            {
                continue;
            }
            chr_int = chr - '0';
        }
        assert((chr_int < 0 || chr > 9) && "Error occurred when executing given code, found chr_int too big");
        if (debug)
        {
            std::cout << separator;
            std::cout << "MEMORY\n| ";
            for (const int &cell : MEMORY)
            {
                std::cout << cell << " | ";
            }
            std::cout << '\n';
            std::cout << separator;
            std::cout << "FUNC_MEMORY\n| ";
            int t = 0;
            for (const std::string &name : func_name)
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
            funcs.at(chr_int)(last - chr_int);
        }
        else
        {
            funcs.at(chr_int)(chr_int);
        }
        last = chr_int;
    }
    return MEMORY;
};