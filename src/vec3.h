#ifndef VEC3_H
#define VEC3_H

#include <cmath>
#include <cstdlib>
#include <iostream>

class vec3 {
public:
  float e[3];

  vec3() : e{0, 0, 0} {}
  vec3(float e0, float e1, float e2) : e{e0, e1, e2} {}

  float x() const { return e[0]; }

  float y() const { return e[1]; }

  float z() const { return e[2]; }

  vec3 operator-() const { return vec3(-e[0], -e[1], -e[2]); }

  float operator[](int i) const { return e[i]; }

  float &operator[](int i) { return e[i]; }

  vec3 &operator+=(const vec3 &v) {
    e[0] += v.e[0];
    e[1] += v.e[1];
    e[2] += v.e[2];
    return *this;
  }

  vec3 &operator*=(float t) {
    e[0] *= t;
    e[1] *= t;
    e[2] *= t;
    return *this;
  }

  vec3 &operator/=(float t) {
    // e[0]/=t;
    // e[1]/=t;
    // e[2]/=t;
    // return *this;
    return *this *= 1 / t;
  }

  float length_squared() const {
    return e[0] * e[0] + e[1] * e[1] + e[2] * e[2];
  }

  float length() const { return std::sqrt(length_squared()); }

  static vec3 random() {
    return vec3(random_float(), random_float(), random_float());
  }

  static vec3 random(float min, float max) {
    return vec3(random_float(min, max), random_float(min, max),
                random_float(min, max));
  }

  bool near_zero() const {
    float s = 1e-8;
    return (std::fabs(e[0]) < s) && (std::fabs(e[1]) < s) &&
           (std::fabs(e[2]) < s);
  }
};

// point3 is just vec3, but useful for geometric clarity in the code.
using point3 = vec3;

// vec utility functions;

// printing
inline std::ostream &operator<<(std::ostream &out, const vec3 &v) {
  return out << v.e[0] << ' ' << v.e[1] << ' ' << v.e[2];
}

inline vec3 operator+(const vec3 &v, const vec3 &u) {
  return vec3(v.e[0] + u.e[0], v.e[1] + u.e[1], v.e[2] + u.e[2]);
}

inline vec3 operator+(const vec3 &v, float t) {
  return vec3(v.e[0] + t, v.e[1] + t, v.e[2] + t);
}

inline vec3 operator+(float t, const vec3 &v) { return v + t; }

inline vec3 operator-(const vec3 &v, const vec3 &u) {
  return vec3(v.e[0] - u.e[0], v.e[1] - u.e[1], v.e[2] - u.e[2]);
}

inline vec3 operator*(const vec3 &v, const vec3 &u) {
  return vec3(v.e[0] * u.e[0], v.e[1] * u.e[1], v.e[2] * u.e[2]);
}

inline vec3 operator*(float t, const vec3 &v) { // t*v
  return vec3(v.e[0] * t, v.e[1] * t, v.e[2] * t);
}

inline vec3 operator*(const vec3 &v, float t) { // v*t
  return t * v;
}

inline vec3 operator/(const vec3 &v, float t) { // v/t
  return (1 / t) * v;
}

inline float dot(const vec3 &u, const vec3 &v) {
  return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}

inline vec3 cross(const vec3 &u, const vec3 &v) {
  return vec3(u.e[1] * v.e[2] - u.e[2] * v.e[1],
              u.e[2] * v.e[0] - u.e[0] * v.e[2],
              u.e[0] * v.e[1] - u.e[1] * v.e[0]);
}

inline vec3 unit_vector(const vec3 &v) { return v / v.length(); }

inline vec3 random_unit_vector() {
  while (true) {
    vec3 p = vec3::random(-1, 1); // cube-like
    float lensq = p.length_squared();
    if (1e-20 < lensq && lensq <= 1) { // ensure inside sphere // edge
      return p / sqrtf(lensq);
    }
  }
}

inline vec3 random_on_hemisphere(const vec3 &normal) {
  vec3 on_unit_sphere = random_unit_vector();
  if (dot(normal, on_unit_sphere) > 0.f) {
    return on_unit_sphere;
  } else
    return -on_unit_sphere;
}

inline vec3 reflect(const vec3 &v, const vec3 &normal) {
  vec3 b = -dot(v, normal) * normal;
  return v + 2 * b;
}

inline vec3 refract(const vec3 &uv, const vec3 &normal, float etai_over_etat) {
  float cos_theta = std::fmin(dot(-uv, normal), 1.0);
  vec3 r_out_perp = etai_over_etat * (uv + (cos_theta * normal));
  vec3 r_out_parallel =
      -std::sqrt(std::fabs(1.0 - r_out_perp.length_squared())) * normal;
  vec3 r_out = r_out_parallel + r_out_perp;
  return r_out;
}
#endif
