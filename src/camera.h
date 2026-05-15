#ifndef CAMERA_H
#define CAMERA_H

#include "common.h"
#include "hittable.h"
#include "material.h"
#include "vec3.h"
#include <cstdlib>

class camera {
private:
  float image_height;
  point3 pixel_00_loc;
  vec3 pixel_delta_u;
  vec3 pixel_delta_v;
  float pixel_sample_scale;
  vec3 v, u, w;
  vec3 defocus_disk_u;
  vec3 defocus_disk_v;

  void initialize() {
    image_height = int(image_width / aspect_ratio);
    image_height = image_height < 1 ? 1 : image_height;

    pixel_sample_scale = 1.0 / samples_per_pixel;

    camera_center = lookfrom;
    // float focal_length = (lookat - lookfrom).length();
    float theta = degree_to_radian(vFov);
    float h = std::tan(theta / 2);
    float viewport_height = 2.0 * h * focus_distance;
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
                                 0.5 * (viewport_v)-0.5 * (viewport_u);
    pixel_00_loc = viewport_upper_left + ((pixel_delta_u + pixel_delta_v) / 2);

    // camera defocus disk
    float defocus_radius =
        focus_distance * std::tan(degree_to_radian(defocus_angle / 2));
    defocus_disk_u = u * defocus_radius;
    defocus_disk_v = v * defocus_radius;
  }

  color ray_color(const ray &r, const hittable &world, int depth) {
    if (depth <= 0) {
      return color(0., 0., 0.);
    }
    hit_record record;

    if (world.hit(r, interval(0.001, infinity), record)) { // edge
      ray scattered;
      color attenuation;
      if (record.mat->scatter(r, record, attenuation, scattered)) {
        return attenuation * ray_color(scattered, world, depth - 1);
      }
      return color(0., 0., 0.);
    }

    vec3 unit_vector_r = unit_vector(r.direction());
    // go from [-1, 1] to [0, 1]
    float a = (unit_vector_r.y() + 1.0) * 0.5;
    color white(1., 1., 1.);
    color blue(0.5, 0.7, 1.0);
    color c = (1 - a) * white + a * blue;
    return c;
  }

  ray get_ray(int i, int j) const {
    // gives us a camera ray from defocus disk directed at randomly sampled
    // point around the viewport pixel location i,j.
    vec3 offset = sample_square();
    point3 pixel_sample = pixel_00_loc + ((i + offset.x()) * pixel_delta_u) +
                          ((j + offset.y()) * pixel_delta_v);
    // point3 ray_origin = camera_center;
    point3 ray_origin =
        (defocus_angle <= 0.0) ? camera_center : defocus_disk_sample();
    vec3 ray_direction = pixel_sample - ray_origin;
    float ray_time = random_float();
    return ray(ray_origin, ray_direction, ray_time);
  }

  point3 defocus_disk_sample() const {
    point3 p = random_in_unit_disk();
    return camera_center + (p[0] * defocus_disk_u) + (p[1] * defocus_disk_v);
  }

  vec3 sample_square() const {
    // returns a vector to a random point in the [-0.5, -0.5] to [+0.5, +0.5]
    // unit square space.
    return vec3(random_float() - 0.5, random_float() - 0.5, 0.0);
  }

public:
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
  float focus_distance = 10.0; // distance from lens to focal plane in real
                               // world
  void render(const hittable &world) {
    initialize();

    // render the image
    std::string color_code = "P3";
    std::cout << color_code << "\n"
              << image_width << " " << image_height << "\n255\n";
    for (int i = 0; i < image_height; i++) {
      std::clog << "\rScanlines remaining: " << (image_height - i) << " "
                << std::flush;
      for (int j = 0; j < image_width; j++) {
        color pixel_color(0., 0., 0.);
        for (int sample = 0; sample < samples_per_pixel; sample++) {
          ray r = get_ray(j, i);
          pixel_color += ray_color(r, world, max_depth);
        }
        write_color(std::cout, pixel_color * pixel_sample_scale);
      }
    }
    std::clog << "\rDone.                        \n";
  }
};

#endif
