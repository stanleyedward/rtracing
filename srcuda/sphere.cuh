#ifndef SPHERE_H
#define SPHERE_H

#include "common.cuh"
#include "hittable.cuh"
#include "interval.cuh"
#include <memory>

class sphere : public hittable {
private:
  ray center;
  float radius;
  shared_ptr<material> mat;
  aabb bbox;

public:
  // sphere constructor
  __device__ sphere(const point3 &static_center, float r, material* mat)
      : center(static_center, vec3(0, 0, 0)), radius(fmaxf(0.0, r)),
        mat(mat) {
    vec3 rvec = vec3(radius, radius, radius);
    bbox = aabb(static_center - rvec, static_center + rvec);
  }

  // moving sphere
  __device__ sphere(const point3 &center1, const point3 &center2, float r,
         material* mat)
      : center(center1, center2 - center1), radius(fmaxf(0.0, r)),
        mat(mat) {
    vec3 rvec = vec3(radius, radius, radius);
    aabb box1(center.at(0) - rvec, center.at(0) + rvec);
    aabb box2(center.at(1) - rvec, center.at(1) + rvec);
    bbox = aabb(box1, box2);
  }

  __device__ aabb bounding_box() const override { return bbox; }

  __device__ static void get_sphere_uv(const point3 &pos, float &u, float &v) {
    float theta = acosf(-pos.y());
    float phi = atan2f(-pos.z(), pos.x()) + pi;

    u = phi / (2 * pi);
    v = theta / pi;
  }

  __device__ bool hit(const ray &r, interval ray_t, hit_record &record) const override {
    point3 current_center = center.at(r.time());
    vec3 center_minus_point = current_center - r.origin();
    float a = dot(r.direction(), r.direction());
    float h = dot(r.direction(), center_minus_point);
    float c = dot(center_minus_point, center_minus_point) - (radius * radius);

    float discriminant = (h * h) - a * c;
    if (discriminant < 0.0) {
      return false;
    }

    float sqrt_disc = std::sqrt(discriminant);
    float root = (h - sqrt_disc) / a;
    if (!ray_t.surrounds(root)) {
      root = (h + sqrt_disc) / a;
      if (!ray_t.surrounds(root)) {
        return false;
      }
    }

    record.t = root;
    record.p = r.at(root);
    vec3 normal = (record.p - current_center) / radius;
    record.set_face_normal(r, normal); // stores normal and if ray is from
                                       // inside or outside inside record
    get_sphere_uv(normal, record.u, record.v);
    record.mat = mat;

    return true;
  }
};

#endif