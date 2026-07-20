#ifndef CAMERA_H
#define CAMERA_H

#include "common.cuh"
#include "hittable.cuh"
#include "interval.cuh"
#include "material.cuh"
#include "vec3.cuh"
#include <cmath>

class camera {
private:
  point3 pixel_00_loc;
  vec3 pixel_delta_u;
  vec3 pixel_delta_v;
  float pixel_sample_scale;
  vec3 v, u, w;
  vec3 defocus_disk_u;
  vec3 defocus_disk_v;
  int sqrt_spp;
  float recip_sqrt_spp;

  __device__ color ray_color(const ray &r, const hittable *world, int depth,
                             curandState *state) {
    color final_color = color(0.f, 0.f, 0.f);
    color throughput = color(1.f, 1.f, 1.f);
    ray current_ray = r;

    for (int i = 0; i < depth; i++) {
      hit_record record;
      if (!world->hit(current_ray, interval(0.0001f, infinity), record,
                      state)) {
        if (use_sky_gradient) {
          vec3 unit_vector_r = unit_vector(current_ray.direction());
          // go from [-1, 1] to [0, 1]
          float a = (unit_vector_r.y() + 1.0) * 0.5;
          color white(1., 1., 1.);
          color blue(0.5, 0.7, 1.0);
          color sky = (1 - a) * white + a * blue;
          final_color += throughput * sky;
          break;
        }
        final_color += throughput * background;
        break;
      }

      ray scattered;
      color attenuation;
      float pdf_value;
      color color_from_emission =
          record.mat->emitted(record.u, record.v, record.p);
      final_color += throughput * color_from_emission;
      if (!record.mat->scatter(current_ray, record, attenuation, scattered,
                               pdf_value, state)) {
        break;
      }

      float scattering_pdf =
          record.mat->scattering_pdf(current_ray, record, scattered);
      pdf_value = scattering_pdf;

      throughput *= attenuation * scattering_pdf / pdf_value;
      current_ray = scattered;
    }
    return final_color;
  }

  __device__ ray get_ray(const unsigned int i, const unsigned int j,
                         const unsigned int s_i, const unsigned int s_j,
                         curandState *state) const {
    // gives us a camera ray from defocus disk directed at randomly sampled
    // point around the viewport pixel location i,j. stratifed for sample square
    // s_i/j.

    // vec3 offset = sample_square(state);
    vec3 offset = sample_square_stratified(s_i, s_j, state);
    point3 pixel_sample = pixel_00_loc + ((i + offset.x()) * pixel_delta_u) +
                          ((j + offset.y()) * pixel_delta_v);
    // point3 ray_origin = camera_center;
    point3 ray_origin =
        (defocus_angle <= 0.0) ? camera_center : defocus_disk_sample(state);
    vec3 ray_direction = pixel_sample - ray_origin;
    float ray_time = random_float(state);
    return ray(ray_origin, ray_direction, ray_time);
  }

  __device__ point3 defocus_disk_sample(curandState *state) const {
    point3 p = random_in_unit_disk(state);
    return camera_center + (p[0] * defocus_disk_u) + (p[1] * defocus_disk_v);
  }

  __device__ vec3 sample_square(curandState *state) const {
    // returns a vector to a random point in the [-0.5, -0.5] to [+0.5, +0.5]
    // unit square space.
    return vec3(random_float(state) - 0.5, random_float(state) - 0.5, 0.0);
  }

  __device__ vec3 sample_square_stratified(const unsigned int s_i,
                                           const unsigned int s_j,
                                           curandState *state) const {
    // stratified sample_square()
    //  returns a vector to a random point in the [-0.5, -0.5] to [+0.5, +0.5]
    float px = ((s_i + random_float(state)) * recip_sqrt_spp) - 0.5f;
    float py = ((s_j + random_float(state)) * recip_sqrt_spp) - 0.5f;
    return vec3(px, py, 0);
  }

public:
  float image_height;
  int image_width = 300;
  float aspect_ratio = 1.0;
  point3 camera_center = point3(0.0, 0.0, 0.0);
  // camera to lens
  int samples_per_pixel =
      10;             // count of random sampled per pixel for anti aliasing
  int max_depth = 10; // max num of ray bounces
  float vFov = 90.0f; // vertical field of view

  // camera pos
  point3 lookat = point3(0.f, 0.f, -1.f);
  point3 lookfrom = point3(0, 0, 0);
  vec3 vUp = vec3(0, 1, 0);

  // focus
  float defocus_angle = 0.0;
  float focus_distance =
      10.0; // distance from lens to focal plane in world space
  color background;
  bool use_sky_gradient = false;

  __device__ color render(const unsigned int row, const unsigned int col,
                          const hittable *world,
                          curandState *state) { // TODO change this later
    interval color_intensity = interval(0.000f, 0.999f);
    color pixel_color(0., 0., 0.);
    for (int s_i = 0; s_i < sqrt_spp; s_i++) {
      for (int s_j = 0; s_j < sqrt_spp; s_j++) {
        ray r = get_ray(col, row, s_i, s_j, state);
        pixel_color += ray_color(r, world, max_depth, state);
      }
    }
    color gamma_corrected_color =
        linear_to_gamma(pixel_color * pixel_sample_scale);
    return color_intensity.clamp(gamma_corrected_color);
  }

  __device__ void initialize() {
    image_height = int(image_width / aspect_ratio);
    image_height = image_height < 1 ? 1 : image_height;

    sqrt_spp = int(sqrtf(samples_per_pixel));
    pixel_sample_scale = 1.0f / (sqrt_spp * sqrt_spp);
    recip_sqrt_spp = 1.f / sqrt_spp;

    camera_center = lookfrom;
    // float focal_length = (lookat - lookfrom).length();
    float theta = degree_to_radian(vFov);
    float h = tanf(theta / 2);
    float viewport_height = 2.0f * h * focus_distance;
    float viewport_width =
        viewport_height * (float(image_width) / image_height);

    // camera basis vectors for the camera coord frame
    w = unit_vector(lookfrom - lookat);
    u = unit_vector(cross(vUp, w));
    v = cross(w, u);

    // viewport vectors
    vec3 viewport_u = viewport_width * u;
    vec3 viewport_v = viewport_height * -v;

    // du, dv
    pixel_delta_u = viewport_u / image_width;
    pixel_delta_v = viewport_v / image_height;

    // get upper left pixel (0, 0)
    point3 viewport_upper_left = camera_center - (focus_distance * w) -
                                 0.5f * (viewport_v)-0.5f * (viewport_u);
    pixel_00_loc = viewport_upper_left + ((pixel_delta_u + pixel_delta_v) / 2);

    // camera defocus disk
    float defocus_radius =
        focus_distance * tanf(degree_to_radian(defocus_angle / 2));
    defocus_disk_u = u * defocus_radius;
    defocus_disk_v = v * defocus_radius;
  }
};

#endif
