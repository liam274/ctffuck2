cmake_minimum_required(VERSION 1.0)
project(ctffuck2)

if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(ctffuck2-hardcore main.cpp lib/algorithm.cpp lib/argument-parse.cpp lib/data-type.cpp)

target_include_directories(dist)
