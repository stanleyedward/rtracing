#ifndef RADIANCE_CACHE_H
#define RADIANCE_CACHE_H

#include "common.cuh"

class cache_cell {
    public:
    float r,g,b;
    unsigned int count; 
};

class radiance_cache {
    public:
        unsigned int cache_res = 64;
        unsigned int cache_bins = 6;
        unsigned int update_passes = 4;
        unsigned int min_samples = 4;
        unsigned int max_verts = 8;
        //change later

        cache_cell *cells;
        float min_x, min_y, min_z;
        float cell_size;
        float inv_cell_size = 1/ cell_size;

        __device__ void add(int s, const color &L) {
            if (s<0) return;
            if (isnan(L.r()) || isnan(L.g()) || isnan(L.b())) return;
            atomicAdd(&cells[s].r, L.r());
            atomicAdd(&cells[s].g, L.g());
            atomicAdd(&cells[s].b, L.b());

            atomicAdd(&cells[s].count, 1);
        }

        __device__ int slot(const point3 &p, const vec3 &n) const {
            int ix = (int)((p.x() - min_x) * inv_cell_size);
            int iy = (int) ((p.y() - min_y) * inv_cell_size);
            int iz = (int) ((p.z() - min_z) * inv_cell_size);

            ix = min(max(ix, 0), cache_res -1);
            iy = min(max(iy, 0), cache_res -1);
            iz = min(max(iz, 0), cache_res - 1);

            float ax = fabsf(n.x());
            float ay = fabsf(n.y());
            float az = fabsf(n.z());

            int dom_axis = (ax >= ay && ax >= az) ? 0 : (ay >= az ? 1 : 2);
            int bin = dom_axis * 2 + (n[dom_axis] < 0 ? 1 : 0);
            
            return ((iz + cache_res * bin) * cache_res + iy)*cache_res + ix;
        }
        __device__ bool lookup(int s, color &L) const;


};


#endif