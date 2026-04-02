#ifndef HITTABLE_H
#define HITTABLE_H

#include "ray.h"

class hit_record {
    public:
        point3 p;
        float t;
        vec3 normal;
};

class hittable {
    public:
        virtual ~hittable() = default; //or {}
        virtual bool hit(const ray& r, float rayT_min, float rayT_max, hit_record& record) const = 0;
};

#endif