#include <filesystem>
#include <fstream>
#include <sstream>
#include "lib/argument-parse.h"
#include "lib/interpreter.h"

namespace fs = std::filesystem;

int main(int argc, char *argv[])
{
    argv_verify verify("CTFFuck2", true, "is an esolang interpreter");
    verify.append("-f", "--file", "The program file", "stdin", {"-r"});
    verify.append("-d", "--debug", "Trigger debug mode", "false");
    verify.append("-r", "--run", "Run an execution to the given code", "", {"-f"});
    verify.append("-i", "--input", "The input string for the program", "");
    std::unordered_map<std::string, std::string> args = verify.verify(argv, argc);
    bool debug = false;
    if (args.at("--debug") != "false")
    {
        debug = true;
    }
    if (verify.has("-r"))
    {
        run(args.at("-r"), debug);
    }
    else
    {
        const std::string FILE_PATH = args.at("-f");
        std::stringstream buffer;
        if (FILE_PATH == "stdin")
        {
            std::string content((std::istreambuf_iterator<char>(std::cin)),
                                std::istreambuf_iterator<char>());
            run(content, debug, args.at("-i"));
        }
        else
        {
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
            std::string content((std::istreambuf_iterator<char>(file)),
                                std::istreambuf_iterator<char>());
            run(content, debug, args.at("-i"));
        }
    }
}