#ifndef QUAD_H
#define QUAD_H

#include "hittable.cuh"
#include "hittable_list.cuh"

class quad : public hittable {
protected:
  point3 Q;
  vec3 u;
  vec3 v;
  material *mat;
  aabb bbox;
  float D;
  vec3 normal;
  vec3 w;

public:
  __device__ quad(const point3 &Q, const vec3 &u, const vec3 &v, material *mat)
      : Q(Q), u(u), v(v), mat(mat) {
    vec3 n = cross(u, v);
    normal = unit_vector(n);
    D = dot(normal, Q);
    w = n / dot(n, n);
    set_bounding_box();
  }
  __device__ virtual void set_bounding_box() {
    aabb bbox_diag_1 = aabb(Q, Q + u + v);
    aabb bbox_diag_2 = aabb(Q + u, Q + v);
    bbox = aabb(bbox_diag_1, bbox_diag_2);
  }

  __device__ virtual bool is_interior(float a, float b, hit_record &rec) const {
    interval unit_interval = interval(0, 1);
    if (!unit_interval.contains(a) || !unit_interval.contains(b)) {
      return false;
    }
    // for textures
    rec.u = a;
    rec.v = b;
    return true;
  }

  __device__ bool hit(const ray &r, interval ray_t,
                      hit_record &record, curandState* state) const override {
    float denom = dot(normal, r.direction());
    if (fabsf(denom) < 1e-8) {
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

  __device__ aabb bounding_box() const override { return bbox; }
};

class tri : public quad {
public:
  __device__ tri(const point3 &o, const vec3 &aa, const vec3 &ab, material *m)
      : quad(o, aa, ab, m) {}

  __device__ virtual bool is_interior(float a, float b,
                                      hit_record &rec) const override {
    if ((a < 0) || (b < 0) || (a + b > 1))
      return false;

    rec.u = a;
    rec.v = b;
    return true;
  }
};

class ellipse : public quad {
public:
  __device__ ellipse(const point3 &center, const vec3 &u, const vec3 &v,
                     material *m)
      : quad(center, u, v, m) {}

  __device__ virtual void set_bounding_box() override {
    bbox = aabb(Q - u - v, Q + u + v);
  }

  __device__ virtual bool is_interior(float a, float b,
                                      hit_record &rec) const override {
    if ((a * a + b * b) > 1)
      return false;

    rec.u = a / 2 + 0.5f;
    rec.v = b / 2 + 0.5f;
    return true;
  }
};

class annulus : public quad {
  public:
    __device__ annulus(const point3 &center, const vec3 &side_A,
                      const vec3 &side_B, float _inner, material *m)
        : quad(center, side_A, side_B, m), inner(_inner) {}

    __device__ virtual void set_bounding_box() override {
      bbox = aabb(Q - u - v, Q + u + v);
    }

    __device__ virtual bool is_interior(float a, float b,
                                        hit_record &rec) const override {
      auto center_dist = sqrt(a * a + b * b);
      if ((center_dist < inner) || (center_dist > 1))
        return false;

      rec.u = a / 2 + 0.5f;
      rec.v = b / 2 + 0.5f;
      return true;
    }

  private:
    float inner;
};

__device__ inline hittable_list *box(const point3 &a, const point3 &b,
                                     material *mat) {

  auto min =
      point3(fminf(a.x(), b.x()), fminf(a.y(), b.y()), fminf(a.z(), b.z()));
  auto max =
      point3(fmaxf(a.x(), b.x()), fmaxf(a.y(), b.y()), fmaxf(a.z(), b.z()));

  auto dx = vec3(max.x() - min.x(), 0, 0);
  auto dy = vec3(0, max.y() - min.y(), 0);
  auto dz = vec3(0, 0, max.z() - min.z());

  hittable **sides = new hittable *[6];

  sides[0] = new quad(point3(min.x(), min.y(), max.z()), dx, dy,
                               mat); // front
  sides[1] = new quad(point3(max.x(), min.y(), max.z()), -dz, dy,
                               mat); // right
  sides[2] = new quad(point3(max.x(), min.y(), min.z()), -dx, dy,
                               mat); // back
  sides[3] = new quad(point3(min.x(), min.y(), min.z()), dz, dy,
                               mat); // left
  sides[4] = new quad(point3(min.x(), max.y(), max.z()), dx, -dz,
                              mat); // top
  sides[5] = new quad(point3(min.x(), min.y(), min.z()), dx, dz,
                               mat); // bottom

  return new hittable_list(sides, 6);
}
#endif