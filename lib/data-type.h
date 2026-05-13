#pragma once
#include <array>
#include <cstdio>
#include <stdexcept>

namespace data_type
{
    template <typename T, std::size_t _max_size>
    class fix_queue
    {
    private:
        static constexpr std::size_t max_size = _max_size;
        size_t head_pointer = 0;
        std::array<T, _max_size> data{};

    public:
        void push(const T &value)
        {
            if (++head_pointer == max_size)
            {
                head_pointer = 0;
            }
            data[head_pointer] = value;
        }
        const T &at(std::size_t ind) const
        {
            if (ind >= max_size)
            {
                fprintf(stderr, "Error occurred when trying to access index %d out of range %d\n", static_cast<int>(ind), static_cast<int>(max_size));
                throw std::runtime_error("Index out of range");
            }
            ind += head_pointer;
            if (ind >= max_size)
            {
                ind -= max_size;
            }
            return data[ind];
        }
        const T &true_at(std::size_t ind) const
        {
            if (ind >= max_size)
            {
                fprintf(stderr, "Error occurred when trying to access index %d out of range %d\n", static_cast<int>(ind), static_cast<int>(max_size));
                throw std::runtime_error("Index out of range");
            }
            return data[ind];
        }
        std::size_t heap() const
        {
            return head_pointer;
        }
    };
}