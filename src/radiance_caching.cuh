#ifndef RADIANCE_CACHE_H
#define RADIANCE_CACHE_H

#include <cassert>
#define CACHE_RES 64
#define CACHE_BINS 6
#define CACHE_UPDATE_PASSES 4
#define CACHE_MIN_SAMPLES 4
#define CACHE_MAX_VERTS 8

#include "color.cuh"
#include "common.cuh"
#include "hittable.cuh"

class cache_cell {
    public:
    float r,g,b;
    unsigned int count; 
};

class radiance_cache {
    public:

        cache_cell *cells;
        float min_x, min_y, min_z;
        float inv_cell_size;

        __device__ void add(int s, const color &L) {
            if (s<0) return;
            if (!isfinite(L.r()) || !isfinite(L.g()) || !isfinite(L.b())) return;
            atomicAdd(&cells[s].r, L.r());
            atomicAdd(&cells[s].g, L.g());
            atomicAdd(&cells[s].b, L.b());

            atomicAdd(&cells[s].count, 1);
        }

        __device__ int slot(const point3 &p, const vec3 &n) const {
            int ix = (int)((p.x() - min_x) * inv_cell_size);
            int iy = (int) ((p.y() - min_y) * inv_cell_size);
            int iz = (int) ((p.z() - min_z) * inv_cell_size);

            ix = min(max(ix, 0), CACHE_RES -1);
            iy = min(max(iy, 0), CACHE_RES -1);
            iz = min(max(iz, 0), CACHE_RES - 1);

            float ax = fabsf(n.x());
            float ay = fabsf(n.y());
            float az = fabsf(n.z());

            int dom_axis = (ax >= ay && ax >= az) ? 0 : (ay >= az ? 1 : 2);
            int bin = dom_axis * 2 + (n[dom_axis] < 0 ? 1 : 0);
            
            return ((iz + CACHE_RES * bin) * CACHE_RES + iy)*CACHE_RES + ix;
        }
        __device__ bool lookup(int s, color &L) const {
            if (s< 0) return false;
            cache_cell c = cells[s];
            if (c.count < CACHE_MIN_SAMPLES) return false;
            float inv_num_samples = 1.f / c.count;
            L = color(c.r * inv_num_samples, c.g * inv_num_samples, c.b * inv_num_samples);
            return true; 
        }
};

__global__ void init_cache_kernel(radiance_cache* cache, cache_cell* cells, hittable** world){
    aabb bbox = (*world)->bounding_box();

    cache->cells = cells;
    cache->min_x = bbox.x.min;
    cache->min_y = bbox.y.min;
    cache->min_z = bbox.z.min;

    float longest_axis = fmaxf(bbox.x.size(), fmaxf(bbox.y.size(), bbox.z.size()))*1.0001f;
    assert(longest >= 0.0f);
    cache->inv_cell_size = CACHE_RES/longest_axis;
}

#endif