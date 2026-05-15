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
    scattered = ray(record.p, lambertian_scatttered_direction, r_in.time());
    attenuation = albedo;
    return true;
  }

private:
  color albedo;
};

class metal : public material {
public:
  metal(const color &albedo, float fuzz)
      : albedo(albedo), fuzz(fuzz < 1 ? fuzz : 1) {}
  bool scatter(const ray &r_in, const hit_record &record, color &attenuation,
               ray &scattered) const override {
    vec3 reflected = reflect(r_in.direction(), record.normal);
    reflected =
        unit_vector(reflected) + (fuzz * random_unit_vector()); // add fuzz
    scattered = ray(record.p, reflected, r_in.time());
    attenuation = albedo;
    return (dot(scattered.direction(), record.normal) > 0);
  }

private:
  color albedo;
  float fuzz;
};

class dielectric : public material {
public:
  dielectric(float refractive_index) : refractive_index(refractive_index) {}
  bool scatter(const ray &r_in, const hit_record &record, color &attenuation,
               ray &scattered) const override {
    attenuation = color(1.0, 1.0, 1.0);
    float ri = record.front_face ? (1.0 / refractive_index) : refractive_index;

    vec3 unit_direction =
        unit_vector(r_in.direction()); // has to be unit to give us cos(theta)
    float cos_theta = std::fmin(dot(-unit_direction, record.normal), 1.0);
    float sin_theta = std::sqrt(1 - cos_theta * cos_theta);

    bool cannot_refract = ri * sin_theta > 1.0;
    vec3 direction;

    if (cannot_refract || reflectance(cos_theta, ri) >
                              random_float()) { // total internal reflection
      direction = reflect(unit_direction, record.normal);
    } else {
      direction = refract(unit_direction, record.normal, ri);
    }
    scattered = ray(record.p, direction, r_in.time());
    return true;
  }

private:
  float refractive_index;

  static float reflectance(float cos_theta, float refractive_index) {
    // schlick approximation for refl
    float r0 = (1 - refractive_index) / (1 + refractive_index);
    r0 = r0 * r0;
    return r0 + (1 - r0) * std::pow((1 - cos_theta), 5);
  }
};
#endif
