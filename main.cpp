#include <iostream>
#include <vector>
#include <string>
#include <unordered_map>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <array>
#include <functional>
#include <random>
#include <algorithm>
#include <deque>
#include "lib/argument-parse.h"
#include "lib/data-type.h"

namespace fs = std::filesystem;

constexpr short MEMORY_SIZE = 10;
int MEMORY[MEMORY_SIZE] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

void read(int arg)
{
    //
}
void add(int arg)
{
    //
}
void set(int arg)
{
    //
}
void push(int arg)
{
    //
}
void print(int arg)
{
    //
}
void swap(int arg)
{
    //
}
void grow(int arg)
{
    //
}
void inp(int arg)
{
    //
}
void jmpm(int arg)
{
    //
}
void revf(int arg)
{
    //
}
std::array<std::function<void(int)>, 10> funcs = {read, add, set, push, print, swap, grow, inp, jmpm, revf};
constexpr short read_stack_length = 1, add_stack_length = 1,
                set_stack_length = 0, push_stack_length = 1,
                print_stack_length = 1, swap_stack_length = 1,
                grow_stack_length = 2, inp_stack_length = 0,
                jmpm_stack_length = 1, revf_stack_length = 0;
constexpr short read_offset = 0, add_offset = read_stack_length,
                set_offset = add_offset + add_stack_length,
                push_offset = set_offset + set_stack_length,
                print_offset = push_offset + push_stack_length,
                swap_offset = print_offset + print_stack_length,
                grow_offset = swap_offset + swap_stack_length,
                inp_offset = swap_offset + swap_stack_length,
                jmpm_offset = inp_offset + inp_stack_length,
                revf_offset = jmpm_offset + jmpm_stack_length;
data_type::fix_queue<int> stack(revf_offset + revf_stack_length);
int main(int argc, char *argv[])
{
    argv_verify verify("CTFFuck2");
    verify.append("-f", "--file", "The program file");
    verify.append("--debug", "--debug", "Trigger debug mode", "false");
    std::unordered_map<std::string, std::string> args = verify.verify(argv, argc);
    bool debug = false;
    if (args.at("--debug") != "false")
    {
        debug = true;
    }
    const std::string FILE_PATH = args.at("-f");
    if (!(fs::exists(FILE_PATH) && fs::is_regular_file(FILE_PATH)))
    {
        std::cerr << "Error occurred when trying to access script file \"" << FILE_PATH << "\", path points to non-regular file." << std::endl;
        return -1;
    }
    std::ifstream file(FILE_PATH);
    if (!file.is_open())
    {
        std::cerr << "Error occurred when trying to open script file \"" << FILE_PATH << "\"." << std::endl;
        return -1;
    }
    std::stringstream buffer;
    buffer << file.rdbuf();
    char chr;
    short last = -1;
    while (buffer >> chr)
    {
        if (chr >= '0' + MEMORY_SIZE or chr < '0')
        {
            continue;
        }
        int chr_int = chr - '0';
        if (last > -1)
        {
            funcs.at(chr_int)(last - chr_int);
        }
        else
        {
            funcs.at(chr_int)(chr_int);
        }
    }
    // piece of code to shuffle func mapping table. Will be used later
    std::random_device rd;
    std::mt19937 g(rd());
    std::shuffle(funcs.begin(), funcs.end(), g);
}