#ifndef HITTABLE_H
#define HITTABLE_H

#include "common.cuh"
#include "interval.cuh"
#include "ray.cuh"
#include "aabb.cuh"

class material; // forward declaration;

class hit_record {
public:
  point3 p;
  float t;
  vec3 normal;
  bool front_face;
  material *mat;
  float u;
  float v;

  __device__ void set_face_normal(const ray &r, const vec3 &outward_normal) {
    front_face = (dot(r.direction(), outward_normal) < 0.0);
    normal = front_face ? outward_normal : -outward_normal;
  }
};

class hittable {
public:
  __device__ virtual ~hittable() = default; // or {}
  __device__ virtual bool hit(const ray &r, interval ray_t, hit_record &record,
                              curandState *state) const = 0;
  __device__ virtual aabb bounding_box() const = 0;
  __device__ virtual bool is_bvh() const { return false; }
};

class translate : public hittable {
private:
  hittable *object;
  vec3 offset;
  aabb bbox;

public:
  __device__ translate(hittable *object, const vec3 &offset)
      : object(object), offset(offset) {
    bbox = object->bounding_box() + offset;
  }

  __device__ aabb bounding_box() const override { return bbox; }
  __device__ bool hit(const ray &r, interval ray_t, hit_record &record,
                      curandState *state) const override {
    ray offset_r(r.origin() - offset, r.direction(), r.time());
    if (!object->hit(offset_r, ray_t, record, state))
      return false;
    record.p += offset;
    return true;
  }
};

class rotate_y : public hittable {
private:
  hittable *object;
  aabb bbox;
  float sin_theta;
  float cos_theta;

public:
  __device__ rotate_y(hittable *object, float angle) : object(object) {
    float radians = degree_to_radian(angle);
    sin_theta = sinf(radians);
    cos_theta = cosf(radians);
    bbox = object->bounding_box();

    point3 min(infinity, infinity, infinity);
    point3 max(-infinity, -infinity, -infinity);
    // go through 8 corners
    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          float x = i * bbox.x.max + (1 - i) * bbox.x.min;
          float y = j * bbox.y.max + (1 - j) * bbox.y.min;
          float z = k * bbox.z.max + (1 - k) * bbox.z.min;

          float newx = cos_theta * x + sin_theta * z;
          float newz = -sin_theta * x + cos_theta * z;

          vec3 tester = vec3(newx, y, newz);

          for (int c = 0; c < 3; c++) {
            min[c] = fminf(min[c], tester[c]);
            max[c] = fmaxf(max[c], tester[c]);
          }
        }
      }
    }
    bbox = aabb(min, max);
  }

  __device__ aabb bounding_box() const override { return bbox; }
  __device__ bool hit(const ray &r, interval ray_t, hit_record &record,
                      curandState *state) const override {
    // transform the ray from world to object space
    point3 origin =
        point3((cos_theta * r.origin().x()) - (sin_theta * r.origin().z()),
               r.origin().y(),
               (sin_theta * r.origin().x()) + (cos_theta * r.origin().z()));

    point3 direction = point3(
        (cos_theta * r.direction().x()) - (sin_theta * r.direction().z()),
        r.direction().y(),
        (sin_theta * r.direction().x()) + (cos_theta * r.direction().z()));

    ray rotated_r(origin, direction, r.time());

    // determine if intersection in rotated object space and where
    if (!object->hit(rotated_r, ray_t, record, state))
      return false;
    // transform intesrsect from obj to world space;
    record.p = point3((cos_theta * record.p.x()) + (sin_theta * record.p.z()),
                      record.p.y(),
                      (-sin_theta * record.p.x()) + (cos_theta * record.p.z()));

    record.normal = vec3(
        (cos_theta * record.normal.x()) + (sin_theta * record.normal.z()),
        record.normal.y(),
        (-sin_theta * record.normal.x()) + (cos_theta * record.normal.z()));

    return true;
  }
};

#endif