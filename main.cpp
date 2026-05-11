#include <filesystem>
#include <fstream>
#include <sstream>
#include "lib/argument-parse.h"
#include "lib/interpreter.h"

namespace fs = std::filesystem;

int main(int argc, char *argv[])
{
    argv_verify verify("CTFFuck2");
    verify.append("-f", "--file", "The program file", "stdin", {"-r"});
    verify.append("--debug", "--debug", "Trigger debug mode", "false");
    verify.append("-r", "--run", "Run an execution to the given code", "", {"-f"});
    std::unordered_map<std::string, std::string> args = verify.verify(argv, argc);
    bool debug = false;
    if (args.at("--debug") != "false")
    {
        debug = true;
    }
    if (verify.has("-r"))
    {
        std::stringstream temp(args.at("-r"));
        run(temp, debug);
    }
    else
    {
        const std::string FILE_PATH = args.at("-f");
        std::stringstream buffer;
        if (FILE_PATH == "stdin")
        {
            buffer << std::cin.rdbuf();
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
            buffer << file.rdbuf();
        }
        run(buffer, debug);
    }
}