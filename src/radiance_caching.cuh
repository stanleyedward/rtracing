#ifndef RADIANCE_CACHE_H
#define RADIANCE_CACHE_H

#include <cassert>
#include <functional>
#define CACHE_BINS 6
#define CACHE_RES (64 * 4)
#define CACHE_UPDATE_PASSES (4 * 4)
#define CACHE_MIN_SAMPLES (4 * 4)
#define CACHE_MAX_VERTS 8

#define CACHE_TABLE_SIZE (1u << 20)
#define CACHE_MAX_PROBES 8
#define CACHE_CELL_SIZE (2.17f)

// #define CACHE_RES 128
// #define CACHE_UPDATE_PASSES 8
// #define CACHE_MIN_SAMPLES 8

#include "color.cuh"
#include "common.cuh"
#include "hittable.cuh"

__device__ inline unsigned int hash64(unsigned long long k) {
  k ^= k >> 33;
  k *= 0xff51afd7ed558ccdull;
  k ^= k >> 33;
  k *= 0xc4ceb93fe53ba34eull;
  k ^= k >> 33;
  return (unsigned int)k;
}

class cache_cell {
public:
  float r, g, b;
  unsigned int count;
};

class radiance_cache {
public:
  cache_cell *cells;
  // float min_x, min_y, min_z;
  unsigned long long *keys;
  float inv_cell_size;

  __device__ void add(int s, const color &L) {
    if (s < 0)
      return;
    if (!isfinite(L.r()) || !isfinite(L.g()) || !isfinite(L.b()))
      return;
    atomicAdd(&cells[s].r, L.r());
    atomicAdd(&cells[s].g, L.g());
    atomicAdd(&cells[s].b, L.b());

    atomicAdd(&cells[s].count, 1);
  }

  // __device__ int slot(const point3 &p, const vec3 &n) const {
  //   int ix = (int)((p.x() - min_x) * inv_cell_size);
  //   int iy = (int)((p.y() - min_y) * inv_cell_size);
  //   int iz = (int)((p.z() - min_z) * inv_cell_size);

  //   ix = min(max(ix, 0), CACHE_RES - 1);
  //   iy = min(max(iy, 0), CACHE_RES - 1);
  //   iz = min(max(iz, 0), CACHE_RES - 1);

  //   float ax = fabsf(n.x());
  //   float ay = fabsf(n.y());
  //   float az = fabsf(n.z());

  //   int dom_axis = (ax >= ay && ax >= az) ? 0 : (ay >= az ? 1 : 2);
  //   int bin = dom_axis * 2 + (n[dom_axis] < 0 ? 1 : 0);

  //   return ((iz + CACHE_RES * bin) * CACHE_RES + iy) * CACHE_RES + ix;
  // }

  __device__ int slot(const point3 &p, const vec3 &n, bool insert) const {
    unsigned long long key = make_key(p, n);
    unsigned int h = hash64(key) & (CACHE_TABLE_SIZE - 1);

    for (int i = 0; i < CACHE_MAX_PROBES; i++) {
      unsigned int idx = (h + i) & (CACHE_TABLE_SIZE - 1);
      unsigned long long k = keys[idx];
      if (k == key)
        return (int)idx;
      if (k == 0) {
        if (!insert)
          return -1;
        unsigned long long old = atomicCAS(&keys[idx], 0ull, key);
        if (old == 0 || old == key)
          return (int)idx;
      }
    }
    return -1;
  }

  __device__ unsigned long long make_key(const point3 &p, const vec3 &n) const {

    long long ix = floorf(p.x() * inv_cell_size + 0.37f);
    long long iy = floorf(p.y() * inv_cell_size + 0.37f);
    long long iz = floorf(p.z() * inv_cell_size + 0.37f);

    float ax = fabsf(n.x());
    float ay = fabsf(n.y());
    float az = fabsf(n.z());

    int dom_axis = (ax >= ay && ax >= az) ? 0 : (ay >= az ? 1 : 2);
    int bin = dom_axis * 2 + (n[dom_axis] < 0 ? 1 : 0);

    const long long OFF = 1 << 19;
    unsigned long long key = ((unsigned long long)(ix + OFF) & 0xFFFFF) |
                             ((unsigned long long)(iy + OFF) & 0xFFFFF) << 20 |
                             ((unsigned long long)(iz + OFF) & 0xFFFFF) << 40 |
                             ((unsigned long long)bin) << 60 | (1ull << 63);

    return key;
  }

  __device__ bool lookup(int s, color &L) const {
    if (s < 0)
      return false;
    cache_cell c = cells[s];
    if (c.count < CACHE_MIN_SAMPLES)
      return false;
    float inv_num_samples = 1.f / c.count;
    L = color(c.r * inv_num_samples, c.g * inv_num_samples,
              c.b * inv_num_samples);
    return true;
  }
};

__global__ void init_cache_kernel(radiance_cache *cache, cache_cell *cells,
                                  unsigned long long *keys) {
  cache->cells = cells;
  cache->keys = keys;
  cache->inv_cell_size = 1.f / CACHE_CELL_SIZE;
}

__device__ inline float safe_div(float num1, float num2) {
  if (num2 < 1e-4f)
    return 0.f;
  return fminf(fmaxf(num1 / num2, 0.f), 50.f); // if too bright clamp
}

#endif