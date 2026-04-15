#ifndef MATERIAL_H
#define MATERIAL_H

#include "color.h"
#include "hittable.h"
#include "vec3.h"

class material {
public:
  virtual ~material() = default;
  virtual bool scatter(const ray &r_in, const hit_record &record,
                       color &attenuation, ray &scattered) const {
    return false;
  }
};

class lambertian : public material {
public:
  lambertian(const color &albedo) : albedo(albedo) {}

  bool scatter(const ray &r_in, const hit_record &record, color &attenuation,
               ray &scattered) const override {
    vec3 lambertian_scatttered_direction =
        record.normal + random_unit_vector();          // lambertian
    if (lambertian_scatttered_direction.near_zero()) { // edge
      lambertian_scatttered_direction = record.normal;
    }
    scattered = ray(record.p, lambertian_scatttered_direction);
    attenuation = albedo;
    return true;
  }

private:
  color albedo;
};

class metal : public material {
public:
  metal(const color &albedo) : albedo(albedo) {}
  bool scatter(const ray &r_in, const hit_record &record, color &attenuation,
               ray &scattered) const override {
    vec3 reflected = reflect(r_in.direction(), record.normal);
    scattered = ray(record.p, reflected);
    attenuation = albedo;
    return true;
  }

private:
  color albedo;
};

#endif