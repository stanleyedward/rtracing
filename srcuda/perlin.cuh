#ifndef PERLIN_H
#define PERLIN_H

#include "vec3.cuh"
class perlin {
private:
  __device__ static const int point_count = 256;
  // float randfloat[point_count];
  vec3 randvec[point_count];
  int perm_x[point_count];
  int perm_y[point_count];
  int perm_z[point_count];

  __device__ static void perlin_generate_perm(int *p, curandState *state) {
    for (int i = 0; i < point_count; i++) {
      p[i] = i;
    }

    permute(p, point_count, state);
  }

  __device__ static void permute(int *p, int count, curandState *state) {
    for (int i = count - 1; i > 0; i--) { // fisher-yates shuffle
      int target = random_int(0, i, state);
      int temp = p[i];
      p[i] = p[target];
      p[target] = temp;
    }
  }
  __device__ static float perlin_interp(vec3 c[2][2][2], float u, float v,
                                        float w) {

    float uu = u * u * (3 - 2 * u);
    float vv = v * v * (3 - 2 * v);
    float ww = w * w * (3 - 2 * w);

    float accum = 0.0;
    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          vec3 weight_v = vec3(u - i, v - j, w - k);
          accum += (i * uu + (1 - i) * (1 - uu)) *
                   (j * vv + (1 - j) * (1 - vv)) *
                   (k * ww + (1 - k) * (1 - ww)) * dot(c[i][j][k], weight_v);
        }
      }
    }
    return accum;
  }

public:
  __device__ perlin(curandState *state) {
    for (int i = 0; i < point_count; i++) {
      randvec[i] = unit_vector(vec3::random(-1, 1, state));
    }

    perlin_generate_perm(perm_x, state);
    perlin_generate_perm(perm_y, state);
    perlin_generate_perm(perm_z, state);
  }

  __device__ float noise(const point3 &p) const {
    float u = p.x() - floorf(p.x());
    float v = p.y() - floorf(p.y());
    float w = p.z() - floorf(p.z());

    int i = int(floorf(p.x()));
    int j = int(floorf(p.y()));
    int k = int(floorf(p.z()));
    vec3 c[2][2][2];

    for (int di = 0; di < 2; di++) {
      for (int dj = 0; dj < 2; dj++) {
        for (int dk = 0; dk < 2; dk++) {
          c[di][dj][dk] =
              randvec[perm_x[(i + di) & 255] ^ perm_y[(j + dj) & 255] ^
                      perm_z[(k + dk) & 255]];
        }
      }
    }

    return perlin_interp(c, u, v, w);
  }

  __device__ float turb(const point3 &pos, int depth) const {
    float accum = 0.0;
    vec3 temp_p = pos;
    float weight = 1.0;

    for (int i = 0; i < depth; i++) {
      accum += weight * noise(temp_p);
      weight *= 0.5;
      temp_p *= 2;
    }

    return fabsf(accum);
  }
};

#endif