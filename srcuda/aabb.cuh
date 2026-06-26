#ifndef AABB_H
#define AABB_H

#include "interval.cuh"
#include "vec3.cuh"
#include "ray.cuh"

class aabb {
private:
  __device__ void pad_to_minimums() {
    float delta = 0.0001;
    if (x.size() < delta)
      x = x.expand(delta);
    if (y.size() < delta)
      y = y.expand(delta);
    if (z.size() < delta)
      z = z.expand(delta);
  }

public:
  interval x, y, z;

  __device__ aabb() {}
  __device__ aabb(const interval &x, const interval &y, const interval &z)
      : x(x), y(y), z(z) {
    pad_to_minimums();
  }
  __device__ aabb(const point3 &p, const point3 &q) {
    x = p[0] <= q[0] ? interval(p[0], q[0]) : interval(q[0], p[0]);
    y = p[1] <= q[1] ? interval(p[1], q[1]) : interval(q[1], p[1]);
    z = p[2] <= q[2] ? interval(p[2], q[2]) : interval(q[2], p[2]);
  }
  __device__ aabb(const aabb &box1, const aabb &box2) {
    x = interval(box1.x, box2.x);
    y = interval(box1.y, box2.y);
    z = interval(box1.z, box2.z);

    pad_to_minimums();
  }

  __device__ const interval &axis_interval(int n) const {
    if (n == 2)
      return z;
    else if (n == 1)
      return y;
    else
      return x;
  }

  __device__ bool hit(const ray &r, interval ray_t) const {
    const point3 &ray_origin = r.origin();
    const point3 &ray_direction = r.direction();

    for (int axis = 0; axis < 3; axis++) {
      const interval &ax_interval = axis_interval(axis);

      float adinv = 1 / ray_direction[axis];

      float t0 = (ax_interval.min - ray_origin[axis]) * adinv;
      float t1 = (ax_interval.max - ray_origin[axis]) * adinv;

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

      if (ray_t.max < ray_t.min)
        return false;
    }
    return true;
  }

  __device__ int longest_axis() const {
    if (x.size() > y.size())
      return x.size() > z.size() ? 0 : 2;
    else
      return y.size() > z.size() ? 1 : 2;
  }

  // static const aabb empty, universe;
  __device__ static aabb empty() {
    return aabb(interval::empty(), interval::empty(), interval::empty());
  }
  __device__ static aabb universe() {
    return aabb(interval::universe(), interval::universe(),
                interval::universe());
  }
};

// inline const aabb aabb::empty =
//     aabb(interval::empty, interval::empty, interval::empty);
// inline const aabb aabb::universe =
//     aabb(interval::universe, interval::universe, interval::universe);
__device__ inline aabb operator+(const aabb &bbox, const vec3 &offset) {
  return aabb(bbox.x + offset.x(), bbox.y + offset.y(), bbox.z + offset.z());
}
__device__ inline aabb operator+(const vec3 &offset, const aabb &bbox) {
  return bbox + offset;
}
#endif