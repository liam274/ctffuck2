#include "algorithm.h"
constexpr int quick_mod(int data, int max)
{
    if (data < max)
    {
        return data;
    }
    if (data == max)
    {
        return 0;
    }
    if (data >= max * 8)
    {
        return data % max;
    }
    else
    {
        while (data >= max)
        {
            data -= max;
        }
        return data;
    }
    return data;
}