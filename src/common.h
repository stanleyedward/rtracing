#ifndef COMMON_H
#define COMMON_H

#include <cmath>
#include <iostream>
#include <limits>
#include <memory>

using std::make_shared;
using std::shared_ptr;

const float infinity = std::numeric_limits<float>::infinity();
const float pi = 3.1415926535897932385f; // prob truncated to 7 digits coz float

inline float degree_to_radian(float degrees) { return degrees * pi / 180.0f; }

// clang-format off
#include "vec3.h"
#include "color.h"
#include "ray.h"
#include "interval.h"
// clang-format on

#endif