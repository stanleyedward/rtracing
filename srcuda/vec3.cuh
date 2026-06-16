#ifndef VEC3_H
#define VEC3_H

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <curand_kernel.h>

class vec3 {
public:
  float e[3];

   __device__ vec3() : e{0, 0, 0} {}
   __device__ vec3(float e0, float e1, float e2) : e{e0, e1, e2} {}

   __device__ float x() const { return e[0]; }

   __device__ float y() const { return e[1]; }

   __device__ float z() const { return e[2]; }

   __device__ float r() const { return e[0]; }

   __device__ float g() const { return e[1]; }

   __device__ float b() const { return e[2]; }

   __device__ vec3 operator-() const { return vec3(-e[0], -e[1], -e[2]); }

   __device__ float operator[](int i) const { return e[i]; }

   __device__ float &operator[](int i) { return e[i]; }

  __device__ vec3 &operator+=(const vec3 &v) {
    e[0] += v.e[0];
    e[1] += v.e[1];
    e[2] += v.e[2];
    return *this;
  }

   __device__ vec3 &operator*=(float t) {
    e[0] *= t;
    e[1] *= t;
    e[2] *= t;
    return *this;
  }

   __device__ vec3 &operator/=(float t) {
    // e[0]/=t;
    // e[1]/=t;
    // e[2]/=t;
    // return *this;
    return *this *= 1 / t;
  }

   __device__ float length_squared() const {
    return e[0] * e[0] + e[1] * e[1] + e[2] * e[2];
  }

   __device__ float length() const { return sqrtf(length_squared()); }

   __device__ static vec3 random(curandState* state) {
    return vec3(random_float(state), random_float(state), random_float(state));
  }

   __device__ static vec3 random(float min, float max, curandState* state) {
    return vec3(random_float(min, max, state), random_float(min, max, state),
                random_float(min, max, state));
  }

   __device__ bool near_zero() const {
    float s = 1e-8;
    return (fabsf(e[0]) < s) && (fabsf(e[1]) < s) &&
           (fabsf(e[2]) < s);
  }
};

// point3 is just vec3, but useful for geometric clarity in the code.
using point3 = vec3;

// vec utility functions;

// printing
inline std::ostream &operator<<(std::ostream &out, const vec3 &v) {
  return out << v.e[0] << ' ' << v.e[1] << ' ' << v.e[2];
}

 __device__ inline vec3 operator+(const vec3 &v, const vec3 &u) {
  return vec3(v.e[0] + u.e[0], v.e[1] + u.e[1], v.e[2] + u.e[2]);
}

 __device__ inline vec3 operator+(const vec3 &v, float t) {
  return vec3(v.e[0] + t, v.e[1] + t, v.e[2] + t);
}

 __device__ inline vec3 operator+(float t, const vec3 &v) { return v + t; }

 __device__ inline vec3 operator-(const vec3 &v, const vec3 &u) {
  return vec3(v.e[0] - u.e[0], v.e[1] - u.e[1], v.e[2] - u.e[2]);
}

 __device__ inline vec3 operator*(const vec3 &v, const vec3 &u) {
  return vec3(v.e[0] * u.e[0], v.e[1] * u.e[1], v.e[2] * u.e[2]);
}

 __device__ inline vec3 operator*(float t, const vec3 &v) { // t*v
  return vec3(v.e[0] * t, v.e[1] * t, v.e[2] * t);
}

 __device__ inline vec3 operator*(const vec3 &v, float t) { // v*t
  return t * v;
}

 __device__ inline vec3 operator/(const vec3 &v, float t) { // v/t
  return (1 / t) * v;
}

 __device__ inline float dot(const vec3 &u, const vec3 &v) {
  return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}

 __device__ inline vec3 cross(const vec3 &u, const vec3 &v) {
  return vec3(u.e[1] * v.e[2] - u.e[2] * v.e[1],
              u.e[2] * v.e[0] - u.e[0] * v.e[2],
              u.e[0] * v.e[1] - u.e[1] * v.e[0]);
}

 __device__ inline vec3 unit_vector(const vec3 &v) { return v / v.length(); }

 __device__ inline point3 random_in_unit_disk(curandState *state) {
  while (true) {
    point3 p = point3(random_float(-1, 1, state), random_float(-1, 1, state), 0);
    if (p.length_squared() < 1) {
      return p;
    }
  }
}

 __device__ inline vec3 random_unit_vector(curandState *state) {
  while (true) {
    vec3 p = vec3::random(-1, 1, state); // cube-like
    float lensq = p.length_squared();
    if (1e-20 < lensq && lensq <= 1) { // ensure inside sphere // edge
      return p / sqrtf(lensq);
    }
  }
}

 __device__ inline vec3 random_on_hemisphere(const vec3 &normal, curandState* state) {
  vec3 on_unit_sphere = random_unit_vector(state);
  if (dot(normal, on_unit_sphere) > 0.f) {
    return on_unit_sphere;
  } else
    return -on_unit_sphere;
}

 __device__ inline vec3 reflect(const vec3 &v, const vec3 &normal) {
  vec3 b = -dot(v, normal) * normal;
  return v + 2 * b;
}

 __device__ inline vec3 refract(const vec3 &uv, const vec3 &normal, float etai_over_etat) {
  float cos_theta = fminf(dot(-uv, normal), 1.0);
  vec3 r_out_perp = etai_over_etat * (uv + (cos_theta * normal));
  vec3 r_out_parallel =
      -sqrtf(fabsf(1.0 - r_out_perp.length_squared())) * normal;
  vec3 r_out = r_out_parallel + r_out_perp;
  return r_out;
}
#endif
