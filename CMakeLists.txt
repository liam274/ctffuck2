cmake_minimum_required(VERSION 3.10)
project(ctffuck2)

if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(ctffuck2-hardcore 
    main.cpp 
    lib/algorithm.cpp 
    lib/argument-parse.cpp 
    lib/data-type.cpp 
    lib/interpreter.cpp
)

# ---------- Optimization Settings ----------
# Enable link-time optimisation (works with GCC, Clang, MSVC)
set_target_properties(ctffuck2-hardcore PROPERTIES
    INTERPROCEDURAL_OPTIMIZATION TRUE
)

# Add aggressive optimisation flags for the Release build (Unix-like)
if(NOT MSVC)
    target_compile_options(ctffuck2-hardcore PRIVATE
        $<$<CONFIG:Release>:-O3 -march=native -DNDEBUG>
    )
endif()
# For MSVC, /O2 is already default in Release, and /GL is set by LTO.
# You could add /arch:AVX2 if you want, but that’s optional.
