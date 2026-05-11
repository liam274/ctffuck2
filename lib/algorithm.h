#pragma once
#include <termios.h>
#include <unistd.h>

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