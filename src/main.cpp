#include "color.h"
#include "ray.h"
#include <iostream>

float hit_sphere(const point3 &center, float radius, const ray &r) {
  vec3 center_minus_point = center - r.origin();
  float a = dot(r.direction(), r.direction());
  // float b = -2.0 * dot(r.direction(), center_minus_point); using
  // simplification
  float h = dot(r.direction(), center_minus_point);
  float c = dot(center_minus_point, center_minus_point) - (radius * radius);

  float discriminant = (h * h) - a * c;

  if (discriminant < 0.0) {
    return -1.0;
  }
  // float t = (-b - std::sqrt(discriminant)) / (2.0 * a); simplify
  float t = (h - std::sqrt(discriminant)) / a;
  return t;
}

color compute_color(const ray &r) {
  point3 sphere_center(0.0, 0.0, -1.0);
  float radius = 0.5;
  float t = hit_sphere(sphere_center, radius, r);

  if (t > 0.0) {
    point3 intersection_point = r.at(t);
    vec3 intersection_normal = unit_vector(intersection_point - sphere_center);
    color color_normal =
        0.5 * color(intersection_normal +
                    1.0f); // inter_normal range [-1, 1] -> [0, 1]
    return color_normal;
  }

  vec3 unit_vector_r = unit_vector(r.direction());
  // go from [-1, 1] to [0, 1]
  float a = (unit_vector_r.y() + 1.0) * 0.5;
  color white(1., 1., 1.);
  color blue(0.5, 0.7, 1.0);
  // color blue(0., 0., 1.0);
  color c = (1 - a) * white + a * blue;
  return c;
}

int main() {

  int image_width = 500;
  float aspect_ratio = 16.0 / 9.0;
  int image_height = int(image_width / aspect_ratio);
  image_height = image_height < 1 ? 1 : image_height;

  float viewport_height = 2.0;
  float viewport_width = viewport_height * (float(image_width) / image_height);

  float focal_length = 1.0;
  point3 camera_center = point3(0., 0., 0.);

  // viewport vectors
  vec3 viewport_u = vec3(viewport_width, 0., 0.);
  vec3 viewport_v = vec3(0., -viewport_height, 0.);

  // du, dv
  vec3 pixel_delta_u = viewport_u / image_width;
  vec3 pixel_delta_v = viewport_v / image_height;

  // get upper left pixel (0, 0)
  point3 viewport_upper_left = camera_center - vec3(0., 0., focal_length) -
                               0.5 * (viewport_v)-0.5 * (viewport_u);
  point3 pixel_00_loc =
      viewport_upper_left + ((pixel_delta_u + pixel_delta_v) / 2);

  // render the image
  std::string color_code = "P3";
  std::cout << color_code << "\n"
            << image_width << " " << image_height << "\n255\n";
  for (int i = 0; i < image_height; i++) {
    std::clog << "\rScanlines remaining: " << (image_height - i) << " "
              << std::flush;
    for (int j = 0; j < image_width; j++) {
      point3 pixel_center =
          pixel_00_loc + (j * pixel_delta_u) + (i * pixel_delta_v);
      vec3 ray_direction = vec3(pixel_center - camera_center);
      ray r = ray(camera_center, ray_direction);
      color pixel_color = compute_color(r);
      write_color(std::cout, pixel_color);
    }
  }
  std::clog << "\rDone.                        \n";
}