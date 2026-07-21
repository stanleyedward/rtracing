#ifndef MATERIAL_H
#define MATERIAL_H

#include "common.cuh"
#include "hittable.cuh"
#include "texture.cuh"
#include "onb.cuh"

class material {
public:
  __device__ virtual ~material() = default;
  __device__ virtual color emitted(float u, float v, const point3 &p) const {
    return color(0, 0, 0);
  }
  __device__ virtual bool scatter(const ray &r_in, const hit_record &record,
                                  color &attenuation, ray &scattered,
                                  float &pdf, curandState *state) const {
    return false;
  }

  __device__ virtual float scattering_pdf(const ray &ray_in,
                                          const hit_record &record,
                                          const ray &scattered) const {
    return 0;
  }
};

class lambertian : public material {
private:
  texture *tex;

public:
  __device__ lambertian(const color &albedo) : tex(new solid_color(albedo)) {}
  __device__ lambertian(texture *tex) : tex(tex) {}

  __device__ bool scatter(const ray &r_in, const hit_record &record,
                          color &attenuation, ray &scattered, float &pdf,
                          curandState *state) const override {
    // vec3 lambertian_scatttered_direction =
    //     record.normal + random_unit_vector(state);     // lambertian
    // if (lambertian_scatttered_direction.near_zero()) { // edge
    //   lambertian_scatttered_direction = record.normal;
    // }
    // scattered = ray(record.p, lambertian_scatttered_direction, r_in.time());
    // attenuation = tex->value(record.u, record.v, record.p);
    // return true;

    onb uvw(record.normal);
    auto scatter_direction = uvw.transform(random_cosine_direction(state));
    scattered = ray(record.p, unit_vector(scatter_direction), r_in.time());
    attenuation = tex->value(record.u, record.v, record.p);
    pdf = dot(uvw.w(), scattered.direction()) / pi; // denom p()

    return true;
  }

  __device__ float
  scattering_pdf(const ray &ray_in, const hit_record &record,
                 const ray &scattered) const override { // numerator pScatter)
    float cos_theta = dot(record.normal, unit_vector(scattered.direction()));
    return cos_theta < 0 ? 0 : cos_theta / pi;
  }
};

class diffuse_light : public material {
private:
  texture *tex;

public:
  __device__ diffuse_light(texture *tex) : tex(tex) {}
  __device__ diffuse_light(const color &emit) : tex(new solid_color(emit)) {}
  __device__ color emitted(float u, float v, const point3 &p) const override {
    return tex->value(u, v, p);
  }
};

class metal : public material {
public:
  __device__ metal(const color &albedo, float fuzz)
      : albedo(albedo), fuzz(fuzz < 1 ? fuzz : 1) {}
  __device__ bool scatter(const ray &r_in, const hit_record &record,
                          color &attenuation, ray &scattered, float &pdf,
                          curandState *state) const override {
    vec3 reflected = reflect(r_in.direction(), record.normal);
    reflected =
        unit_vector(reflected) + (fuzz * random_unit_vector(state)); // add fuzz
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
  __device__ dielectric(float refractive_index)
      : refractive_index(refractive_index) {}
  __device__ bool scatter(const ray &r_in, const hit_record &record,
                          color &attenuation, ray &scattered, float &pdf,
                          curandState *state) const override {
    attenuation = color(1.0, 1.0, 1.0);
    float ri = record.front_face ? (1.0 / refractive_index) : refractive_index;

    vec3 unit_direction =
        unit_vector(r_in.direction()); // has to be unit to give us cos(theta)
    float cos_theta = fminf(dot(-unit_direction, record.normal), 1.0);
    float sin_theta = sqrtf(1 - cos_theta * cos_theta);

    bool cannot_refract = ri * sin_theta > 1.0;
    vec3 direction;

    if (cannot_refract ||
        reflectance(cos_theta, ri) >
            random_float(state)) { // total internal reflection
      direction = reflect(unit_direction, record.normal);
    } else {
      direction = refract(unit_direction, record.normal, ri);
    }
    scattered = ray(record.p, direction, r_in.time());
    return true;
  }

private:
  float refractive_index;

  __device__ static float reflectance(float cos_theta, float refractive_index) {
    // schlick approximation for refl
    float r0 = (1 - refractive_index) / (1 + refractive_index);
    r0 = r0 * r0;
    return r0 + (1 - r0) * powf((1 - cos_theta), 5);
  }
};

class isotropic : public material {
private:
  texture *tex;

public:
  __device__ isotropic(const color &abledo) : tex(new solid_color(abledo)) {}
  __device__ isotropic(texture *tex) : tex(tex) {}

  __device__ bool scatter(const ray &r_in, const hit_record &record,
                          color &attenuation, ray &scattered, float &pdf,
                          curandState *state) const override {
    scattered = ray(record.p, random_unit_vector(state), r_in.time());
    attenuation = tex->value(record.u, record.v, record.p);
    pdf = 1 / (4 * pi);
    return true;
  }

  __device__ float scattering_pdf(const ray &r_in, const hit_record &rec,
                                  const ray &scattered) const override {
    return 1 / (4 * pi);
  }
};
#endif
