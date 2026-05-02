#ifndef COMMON_H
#define COMMON_H

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <memory>
#include <random>

using std::make_shared;
using std::shared_ptr;

// inline const float infinity = std::numeric_limits<float>::infinity();
// //removed because of LSP :/
inline const float pi =
    3.1415926535897932385f; // prob truncated to 7 digits coz float

inline float degree_to_radian(float degrees) { return degrees * pi / 180.0f; }

inline float random_float() {
  // gives between [0, 1) better way
  static std::uniform_real_distribution<float> distribution(0.0, 1.0);
  static std::mt19937 generator;
  return distribution(generator);
}

inline float random_float(float min, float max) {
  return min + (max - min) * random_float();
}

// clang-format off
#include "vec3.h"
#include "ray.h"
#include "color.h"
#include "interval.h"
// clang-format on

#endif