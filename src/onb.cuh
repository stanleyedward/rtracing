
#ifndef ONB_H
#define ONB_H

#include "common.cuh"

class onb {
    private:
        vec3 axis[3];
    public:
        __device__ onb(const vec3& n){
            axis[2] = unit_vector(n);
            vec3 a = fabsf(axis[2].x()) > 0.9 ? vec3(0.f, 1.f, 0.f) : vec3(1, 0, 0);
            axis[1] = unit_vector(cross(axis[2], a));
            axis[0] = cross(axis[2], axis[1]);
        }
        
        __device__ const vec3& u() const {return axis[0];}
        __device__ const vec3& v() const {return axis[1];}
        __device__ const vec3& w() const {return axis[2];}

        __device__ vec3 transform(const vec3& v) const {
            return (v[0] *  axis[0]) + (v[1] * axis[1]) + (v[2] * axis[2]);
        }
};

#endif
