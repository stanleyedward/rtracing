#include "color.h"
#include "ray.h"
#include <iostream>

color compute_color(const ray &r) { return color(0., 0., 1.); }

int main() {

  int image_width = 500;
  float aspect_ratio = 16.0 / 9.0;
  int image_height = int(image_width / aspect_ratio);
  image_height = image_height < 1 ? 1 : image_height;

  float viewport_height = 2.0;
  float viewport_width = viewport_height * (float(image_width / image_height));

  float focal_length = 1.0;
  point3 camera_center = point3(0., 0., 0.);

  // viewport vectors
  vec3 viewport_u = vec3(viewport_width, 0., 0.);
  vec3 viewport_v = vec3(0., -viewport_height, 0.);

  // du, dv
  vec3 pixel_delta_u = viewport_u / image_height;
  vec3 pixel_delta_v = viewport_v / image_width;

  // get upper left pixel (0, 0)
  point3 viewport_upper_left = camera_center - vec3(0., 0., focal_length) -
                               0.5 * (viewport_v)-0.5 * (viewport_u);
  point3 pixel_00_loc = (pixel_delta_u + pixel_delta_v) / 2;

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
      vec3 ray_direction = vec3(camera_center - pixel_center);
      ray r = ray(camera_center, ray_direction);
      color pixel_color = compute_color(r);
      write_color(std::cout, pixel_color);
    }
  }
  std::clog << "\rDone.                        \n";
}