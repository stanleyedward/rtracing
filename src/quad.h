#ifndef QUAD_H
#define QUAD_H

#include "common.h"
#include "hittable.h"
#include "interval.h"
#include "vec3.h"
#include <memory>

class quad : public hittable {
private:
  point3 Q;
  vec3 u;
  vec3 v;
  shared_ptr<material> mat;
  aabb bbox;
  float D;
  vec3 normal;
  vec3 w;

public:
  quad(const point3 &Q, const vec3 &u, const vec3 &v,
       const shared_ptr<material> mat)
      : Q(Q), u(u), v(v), mat(mat) {
    vec3 n = cross(u, v);
    normal = unit_vector(n);
    D = dot(normal, Q);
    w = n / dot(n, n);
    set_bounding_box();
  }
  virtual void set_bounding_box() {
    aabb bbox_diag_1 = aabb(Q, Q + u + v);
    aabb bbox_diag_2 = aabb(Q + u, Q + v);
    bbox = aabb(bbox_diag_1, bbox_diag_2);
  }

  virtual bool is_interior(float a, float b, hit_record &rec) const {
    interval unit_interval = interval(0, 1);
    if (!unit_interval.contains(a) || !unit_interval.contains(b)) {
      return false;
    }
    // for textures
    rec.u = a;
    rec.v = b;
    return true;
  }

  bool hit(const ray &r, interval ray_t, hit_record &record) const override {
    float denom = dot(normal, r.direction());
    if (std::fabs(denom) < 1e-8) {
      return false;
    }
    float t = (D - dot(normal, r.origin())) / denom;
    if (!ray_t.contains(t)) {
      return false;
    }

    point3 intersection = r.at(t);
    vec3 planar_hitpt_vector = intersection - Q;
    float alpha = dot(w, cross(planar_hitpt_vector, v));
    float beta = dot(w, cross(u, planar_hitpt_vector));

    if (!is_interior(alpha, beta, record)) {
      return false;
    }

    record.t = t;
    record.p = intersection;
    record.mat = mat;
    record.set_face_normal(r, normal);
    return true;
  }

  aabb bounding_box() const override { return bbox; }
};

#endif