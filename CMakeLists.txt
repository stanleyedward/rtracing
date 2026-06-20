cmake_minimum_required(VERSION 3.18)
project(cuda_raytracer LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_ARCHITECTURES 86)  # change to match your GPU

add_executable(raytracer srcuda/main.cu)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)