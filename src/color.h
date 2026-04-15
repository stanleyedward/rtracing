#ifndef COLOR_H
#define COLOR_H

#include "interval.h"
#include "vec3.h" //removing brakes it xd but the turning off clang-formatting in common.h fixed it
#include <cmath>

using color = vec3;

inline float linear_to_gamma(float linear_component) {
  if (linear_component > 0) {
    return std::sqrt(linear_component);
  }
  return 0;
}

inline void write_color(std::ostream &out, const color &pixel_color) {
  // assumes the range [0, 1] for the color!
  float r = pixel_color.x();
  float g = pixel_color.y();
  float b = pixel_color.z();

  r = linear_to_gamma(r);
  g = linear_to_gamma(g);
  b = linear_to_gamma(b);

  // convert [0, 1] to [0, 255]
  static const interval intensity(0.000, 0.999);
  int rbyte = int(256 * intensity.clamp(r));
  int gbyte = int(256 * intensity.clamp(g));
  int bbyte = int(256 * intensity.clamp(b));

  // write the output pixel
  out << rbyte << ' ' << gbyte << ' ' << bbyte << '\n';
}

#endif