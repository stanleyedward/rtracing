#ifndef HITTABLE_H
#define HITTABLE_H

#include "interval.h"
#include "ray.h"
#include "aabb.h"

class material; // forward declaration;

class hit_record {
public:
  point3 p;
  float t;
  vec3 normal;
  bool front_face;
  shared_ptr<material> mat;
  float u;
  float v;

  void set_face_normal(const ray &r, const vec3 &outward_normal) {
    front_face = (dot(r.direction(), outward_normal) < 0.0);
    normal = front_face ? outward_normal : -outward_normal;
  }
};

class hittable {
public:
  virtual ~hittable() = default; // or {}
  virtual bool hit(const ray &r, interval ray_t, hit_record &record) const = 0;
  virtual aabb bounding_box() const = 0;
};

#endif