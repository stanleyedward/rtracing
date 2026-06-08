#ifndef INTERVAL_H
#define INTERVAL_H

#include <limits>
inline const float infinity = std::numeric_limits<float>::infinity();

class interval {
public:
  float min, max;

  interval() : min(+infinity), max(-infinity) {}
  interval(float rayT_min, float rayT_max) : min(rayT_min), max(rayT_max) {}
  interval(const interval &a, const interval &b) {
    min = a.min <= b.min ? a.min : b.min;
    max = a.max >= b.max ? a.max : b.max;
  }

  float size() const { return max - min; }

  bool contains(float t) const { return (min <= t && t <= max); }

  bool surrounds(float t) const { return (min < t && t < max); }

  interval expand(float epsilon) const {
    float padding = epsilon / 2;
    return interval(min - padding, max + padding);
  }

  float clamp(float x) const {
    if (x < min)
      return min;
    if (x > max)
      return max;
    return x;
  }

  static const interval empty, universe;
};

inline const interval interval::empty = interval(+infinity, -infinity);
inline const interval interval::universe = interval(-infinity, +infinity);
inline interval operator+(const interval &interv, float displacement) {
  return interval(interv.min + displacement, interv.max + displacement);
}
inline interval operator+(float displacement, const interval &interv) {
  return interv + displacement;
}
#endif