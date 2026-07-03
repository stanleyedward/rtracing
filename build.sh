#!/usr/bin/env bash
set -e

# format only your own CUDA sources (skip the vendored stb headers in external/)
clang-format -i src/*.cu src/*.cuh

rm -rf build

# configure (gcc as the nvcc host compiler — safe choice for CUDA 13.3)
cmake -B build/Release \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_CXX_COMPILER=g++ \
  -DCMAKE_CUDA_FLAGS="-O3"
# keep the symlink pointing at THIS build dir so clangd reads the right database
ln -sf build/Release/compile_commands.json compile_commands.json
# build
cmake --build build/Release -- VERBOSE=1
# ./build/Release/raytracer > image.ppm

# cmake -B build/Debug -DCMAKE_BUILD_TYPE=Debug \
#   -DCMAKE_CUDA_FLAGS="-G -g" \
#   -DCMAKE_CXX_COMPILER=g++
# ln -sf build/debug/compile_commands.json compile_commands.json
# cmake --build build/Debug
# ./build/Debug/raytracer > image.ppm