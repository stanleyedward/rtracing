#ifndef HITTABLE_LIST_H
#define HITTABLE_LIST_H

#include "aabb.cuh"
#include "hittable.cuh"
#include "interval.cuh"

class hittable_list : public hittable {
private:
  aabb bbox;

public:
  hittable **objects;
  unsigned int list_size;

  __device__ hittable_list() {}
  __device__ hittable_list(hittable **objs, int obj_count)
      : objects(objs), list_size(obj_count) {
    set_bbox();
  }

  __device__ void set_bbox() {
    bbox = aabb::empty();
    for (int i = 0; i < list_size; i++) {
      bbox = aabb(bbox, objects[i]->bounding_box());
    }
  }

  __device__ aabb bounding_box() const override { return bbox; }

  __device__ bool hit(const ray &r, interval ray_t, hit_record &record,
                      curandState *state) const override {
    hit_record temp_record;
    bool hit_anything = false;
    float closest_hit_so_far = ray_t.max;

    for (int i = 0; i < list_size; i++) {
      if (objects[i]->hit(
              r, interval(ray_t.min, closest_hit_so_far), temp_record,
              state)) { // change rayT_max->closest_hit to get closest obj
        hit_anything = true;
        closest_hit_so_far = temp_record.t;
        record = temp_record; // record of the closest object hit
      }
    }
    return hit_anything;
  }
};

#endif