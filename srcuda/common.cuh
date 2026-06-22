#ifndef COMMON_H
#define COMMON_H

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <memory>
#include <random>
#include <curand_kernel.h>

#define CH 3
#define TILE_SIZE 16
#define CEIL_DIV(N, M)((N + M - 1) / M)

inline constexpr float pi =
    3.1415926535897932385f; // prob truncated to 7 digits coz float

__device__ inline float degree_to_radian(float degrees) { return degrees * pi / 180.0f; }

__global__ void rand_render_states(unsigned int image_width, unsigned int image_height, curandState *rand_state, unsigned int seed){
  unsigned int row = blockIdx.y * blockDim.y + threadIdx.y;
  unsigned int col = blockIdx.x * blockDim.x + threadIdx.x;
  if (col >= image_width || row >= image_height) return;
  unsigned int pixel_idx = row*image_width + col;
  //same seed different sequence
  // curand_init(seed, pixel_idx, 0, &rand_state[pixel_idx]);
  //different seed, same sequence gave 2x perf
  curand_init(pixel_idx + seed, 0, 0, &rand_state[pixel_idx]);
}

__global__ void rand_init_states(curandState *state, unsigned int seed){
  if(threadIdx.x == 0 && blockIdx.x == 0){ 
    curand_init(seed, 0, 0, state); 
  }
}

__device__ inline float random_float(curandState *state) {
  //curand gives (0, 1] doing 1- to mkae it [0, 1)
  return 1.0f - curand_uniform(state);
}

__device__ inline float random_float(float min, float max, curandState *state) {
  return min + (max - min) * random_float(state);
}

__device__ inline int random_int(int min, int max, curandState* state) {
  return int(random_float(min, max + 1, state));
}

// clang-format off
#include "vec3.cuh"
#include "ray.cuh"
#include "color.cuh"
#include "interval.cuh"
// clang-format on

#endif