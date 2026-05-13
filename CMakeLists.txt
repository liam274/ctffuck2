cmake_minimum_required(VERSION 3.10)
project(ctffuck2)

if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

add_executable(ctffuck2 
    main.cpp 
    lib/argument-parse.cpp 
    lib/data-type.cpp 
    lib/interpreter.cpp
)


target_compile_options(ctffuck2 PRIVATE
    $<$<CONFIG:Release>:
        -O3
        -march=native
        -DNDEBUG

        -ffunction-sections
        -fdata-sections

        -fno-rtti

        -fno-unwind-tables
        -fno-asynchronous-unwind-tables
    >
)


target_link_options(ctffuck2 PRIVATE
    $<$<CONFIG:Release>:

        -Wl,--gc-sections

        -s

        -Wl,--strip-all


        -Wl,--no-eh-frame-hdr
    >
)


set_target_properties(ctffuck2 PROPERTIES
    INTERPROCEDURAL_OPTIMIZATION TRUE
)
