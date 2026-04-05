#ifndef HITTABLE_LIST_H
#define HITTABLE_LIST_H

#include "hittable.h"
#include "interval.h"
#include <vector>

class hittable_list : public hittable {
public:
  std::vector<shared_ptr<hittable>> objects;

  hittable_list() {}
  hittable_list(shared_ptr<hittable> object) { add(object); }

  void add(shared_ptr<hittable> object) { objects.push_back(object); }

  void clear() { objects.clear(); }

  bool hit(const ray &r, interval ray_t, hit_record &record) const override {
    hit_record temp_record;
    bool hit_anything = false;
    float closest_hit_so_far = ray_t.max;

    for (const shared_ptr<hittable> &object : objects) {
      if (object->hit(
              r, interval(ray_t.min, closest_hit_so_far),
              temp_record)) { // change rayT_max->closest_hit to get closest obj
        hit_anything = true;
        closest_hit_so_far = temp_record.t;
        record = temp_record; // record of the closest object hit
      }
    }
    return hit_anything;
  }
};

#endif