#ifndef QUAD_H
#define QUAD_H

#include "common.h"
#include "hittable.h"
#include "interval.h"
#include "vec3.h"
#include <memory>

class quad : public hittable {
protected:
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

class tri : public quad {
public:
  tri(const point3 &o, const vec3 &aa, const vec3 &ab, shared_ptr<material> m)
      : quad(o, aa, ab, m) {}

  virtual bool is_interior(float a, float b, hit_record &rec) const override {
    if ((a < 0) || (b < 0) || (a + b > 1))
      return false;

    rec.u = a;
    rec.v = b;
    return true;
  }
};

class ellipse : public quad {
public:
  ellipse(const point3 &center, const vec3 &u, const vec3 &v,
          shared_ptr<material> m)
      : quad(center, u, v, m) {}

  virtual void set_bounding_box() override {
    bbox = aabb(Q - u - v, Q + u + v);
  }

  virtual bool is_interior(float a, float b, hit_record &rec) const override {
    if ((a * a + b * b) > 1)
      return false;

    rec.u = a / 2 + 0.5;
    rec.v = b / 2 + 0.5;
    return true;
  }
};

class annulus : public quad {
public:
  annulus(const point3 &center, const vec3 &side_A, const vec3 &side_B,
          float _inner, shared_ptr<material> m)
      : quad(center, side_A, side_B, m), inner(_inner) {}

  virtual void set_bounding_box() override {
    bbox = aabb(Q - u - v, Q + u + v);
  }

  virtual bool is_interior(float a, float b, hit_record &rec) const override {
    auto center_dist = sqrt(a * a + b * b);
    if ((center_dist < inner) || (center_dist > 1))
      return false;

    rec.u = a / 2 + 0.5;
    rec.v = b / 2 + 0.5;
    return true;
  }

private:
  float inner;
};
#endif