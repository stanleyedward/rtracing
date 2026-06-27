#ifndef INTERVAL_H
#define INTERVAL_H

#include "vec3.cuh"
#include <cfloat>

inline constexpr float infinity = FLT_MAX;
class interval {
public:
  float min, max;

  __device__ interval() : min(+infinity), max(-infinity) {}
  __device__ interval(float rayT_min, float rayT_max)
      : min(rayT_min), max(rayT_max) {}
  __device__ interval(const interval &a, const interval &b) {
    min = a.min <= b.min ? a.min : b.min;
    max = a.max >= b.max ? a.max : b.max;
  }

  __device__ float size() const { return max - min; }

  __device__ bool contains(float t) const { return (min <= t && t <= max); }

  __device__ bool surrounds(float t) const { return (min < t && t < max); }

  __device__ interval expand(float epsilon) const {
    float padding = epsilon / 2;
    return interval(min - padding, max + padding);
  }

  __host__ __device__ float clamp(float x) const {
    if (x < min)
      return min;
    if (x > max)
      return max;
    return x;
  }

  __host__ __device__ vec3 clamp(vec3 v) const {
    return vec3(clamp(v.x()), clamp(v.y()), clamp(v.z()));
  }

  __device__ static interval empty() { return interval(+infinity, -infinity); }
  __device__ static interval universe() {
    return interval(-infinity, +infinity);
  }
};

__device__ inline interval operator+(const interval &interv,
                                     float displacement) {
  return interval(interv.min + displacement, interv.max + displacement);
}
__device__ inline interval operator+(float displacement,
                                     const interval &interv) {
  return interv + displacement;
}
#endif