#ifndef COLOR_H
#define COLOR_H

#include "interval.h"
#include "vec3.h" //removing brakes it xd but the turning off clang-formatting in common.h fixed it

using color = vec3;

inline void write_color(std::ostream &out, const color &pixel_color) {
  // assumes the range [0, 1] for the color!
  auto r = pixel_color.x();
  auto g = pixel_color.y();
  auto b = pixel_color.z();

  // convert [0, 1] to [0, 255]
  static const interval intensity(0.000, 0.999);
  int rbyte = int(256 * intensity.clamp(r));
  int gbyte = int(256 * intensity.clamp(g));
  int bbyte = int(256 * intensity.clamp(b));

  // write the output pixel
  out << rbyte << ' ' << gbyte << ' ' << bbyte << '\n';
}

#endif