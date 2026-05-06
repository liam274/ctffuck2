#!/bin/bash

set -e  # 遇到错误立即退出

echo "========================================"
echo "Building CTFFuck2 (Linux/macOS)"
echo "========================================"


# 切换到脚本所在目录
cd "$(dirname "$0")"

# 删除并重建 build 目录
rm -rf build
mkdir build
cd build

# 运行 CMake 配置
cmake ..

# 构建（默认 Release）
cmake --build . --config Release

echo "Build successful! Executable: $(pwd)/ctffuck2-hardcore"
