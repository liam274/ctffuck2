#pragma once
#include <vector>
#include <iostream>
#include <stdexcept>

namespace data_type
{
    template <typename T>
    class fix_queue
    {
    private:
        int max_size;
        size_t head_pointer = 0;
        std::vector<T> data;

    public:
        void set_size(const int max_size)
        {
            this->max_size = max_size;
            data.resize(max_size);
        }
        void push(const T &value)
        {
            if (++head_pointer == max_size)
            {
                head_pointer = 0;
            }
            data[head_pointer] = value;
        }
        const T &at(int ind) const
        {
            if (ind >= max_size)
            {
                std::cerr << "Error occurred when trying to access index " << ind << " out of range " << max_size << std::endl;
                throw std::runtime_error("Index out of range");
            }
            ind += head_pointer;
            if (ind >= max_size)
            {
                ind -= max_size;
            }
            return data[ind];
        }
        const T &true_at(int ind) const
        {
            if (ind >= max_size)
            {
                std::cerr << "Error occurred when trying to access index " << ind << " out of range " << max_size << std::endl;
                throw std::runtime_error("Index out of range");
            }
            return data[ind];
        }
    };
}