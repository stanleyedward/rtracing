#ifndef CONSTANT_MEDIUM_H
#define CONSTANT_MEDIUM_H

#include "common.h"
#include "hittable.h"
#include "interval.h"
#include "material.h"
#include "texture.h"

class constant_medium : public hittable {
private:
  shared_ptr<hittable> boundary;
  double neg_inv_density;
  shared_ptr<material> phase_function;

public:
  constant_medium(shared_ptr<hittable> boundary, float density,
                  shared_ptr<texture> tex)
      : boundary(boundary), neg_inv_density(-1 / density),
        phase_function(make_shared<isotropic>(tex)) {}
  constant_medium(shared_ptr<hittable> boundary, float density,
                  const color &albedo)
      : boundary(boundary), neg_inv_density(-1 / density),
        phase_function(make_shared<isotropic>(albedo)) {}

  aabb bounding_box() const override { return boundary->bounding_box(); }

  bool hit(const ray &r, interval ray_t, hit_record &record) const override {
    hit_record rec1, rec2;
    if (!boundary->hit(r, interval::universe, rec1))
      return false;
    if (!boundary->hit(r, interval(rec1.t + 0.0001, infinity), rec2))
      return false;
    if (rec1.t < ray_t.min)
      rec1.t = ray_t.min;
    if (rec2.t < ray_t.min)
      rec2.t = ray_t.min;
    if (rec1.t >= rec2.t)
      return false;
    if (rec1.t < 0)
      rec1.t = 0;

    float ray_length = r.direction().length();
    float distance_inside_boundary = (rec2.t - rec1.t) * ray_length;
    float hit_distance = neg_inv_density * std::log(random_float());

    if (hit_distance > distance_inside_boundary)
      return false;

    record.t = rec1.t + hit_distance / ray_length;
    record.p = r.at(record.t);

    record.normal = vec3(1, 0, 0); // arbitary
    record.front_face = true;      // arbies
    record.mat = phase_function;
    return true;
  }
};
#endif
