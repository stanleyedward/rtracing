#ifndef COLOR_H
#define COLOR_H

#include "vec3.cuh" //removing brakes it xd but the turning off clang-formatting in common.h fixed it
#include <cmath>

using color = vec3;

__host__ __device__ inline float linear_to_gamma(float linear_component) {
  if (linear_component > 0) {
    if (linear_component != linear_component)
      linear_component = 0.0f; // check for NaN
    return sqrtf(linear_component);
  }
  return 0.0f;
}

__device__ inline color linear_to_gamma(color lin_color) {
  return color(linear_to_gamma(lin_color.r()), linear_to_gamma(lin_color.g()),
               linear_to_gamma(lin_color.b()));
}

__host__ inline void write_color(std::ostream &out, float r, float g, float b) {
  // convert [0, 1] to [0, 255]
  // static const interval intensity(0.000, 0.999);
  int rbyte = int(256 * r);
  int gbyte = int(256 * g);
  int bbyte = int(256 * b);

  // write the output pixel
  out << rbyte << ' ' << gbyte << ' ' << bbyte << '\n';
}

#endif