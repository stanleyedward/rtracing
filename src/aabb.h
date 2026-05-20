#ifndef AABB_H
#define AABB_H

#include "interval.h"
#include "vec3.h"
#include "ray.h"

class aabb {
public:
  interval x, y, z;

  aabb() {}
  aabb(const interval &x, const interval &y, const interval &z)
      : x(x), y(y), z(z) {}
  aabb(const point3 &p, const point3 &q) {
    x = p[0] <= q[0] ? interval(p[0], q[0]) : interval(q[0], p[0]);
    y = p[1] <= q[1] ? interval(p[1], q[1]) : interval(q[1], p[1]);
    z = p[2] <= q[2] ? interval(p[2], q[2]) : interval(q[2], p[2]);
  }
  aabb(const aabb &box1, const aabb &box2) {
    x = interval(box1.x, box2.x);
    y = interval(box1.y, box2.y);
    z = interval(box1.z, box2.z);
  }

  const interval &axis_interval(int n) const {
    if (n == 2)
      return z;
    else if (n == 1)
      return y;
    else
      return x;
  }

  bool hit(const ray &r, interval ray_t) const {
    const point3 &ray_origin = r.origin();
    const point3 &ray_direction = r.direction();

    for (int axis = 0; axis < 3; axis++) {
      const interval &ax_interval = axis_interval(axis);

      float adinv = 1 / ray_direction[axis];

      float t0 = (ax_interval.min - ray_origin[axis]) * adinv;
      float t1 = (ax_interval.max - ray_origin[axis]) * adinv;

      // this is wayyyy slowers
      // ray_t.min = std::fmax(ray_t.min, std::fmin(t0, t1));
      // ray_t.max = std::fmin(ray_t.max, std::fmax(t0, t1));

      if (t0 < t1) {
        if (t0 > ray_t.min)
          ray_t.min = t0;
        if (t1 < ray_t.max)
          ray_t.max = t1;
      } else {
        if (t1 > ray_t.min)
          ray_t.min = t1;
        if (t0 < ray_t.max)
          ray_t.max = t0;
      }

      if (ray_t.max < ray_t.min) {
        return false;
      }
    }
    return true;
  }
};

#endif