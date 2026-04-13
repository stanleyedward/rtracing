#ifndef INTERVAL_H
#define INTERVAL_H

#include <limits>
inline const float infinity = std::numeric_limits<float>::infinity();

class interval {
public:
  float min, max;

  interval() : min(+infinity), max(-infinity) {}
  interval(float rayT_min, float rayT_max) : min(rayT_min), max(rayT_max) {}

  float size() const { return max - min; }

  bool contains(float t) const { return (min <= t && t <= max); }

  bool surrounds(float t) const { return (min < t && t < max); }

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

#endif