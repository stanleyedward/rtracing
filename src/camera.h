#ifndef CAMERA_H
#define CAMERA_H

#include "common.h"
#include "hittable.h"

class camera {
private:
  float image_height;
  point3 pixel_00_loc;
  vec3 pixel_delta_u;
  vec3 pixel_delta_v;

  void initialize() {
    image_height = int(image_width / aspect_ratio);
    image_height = image_height < 1 ? 1 : image_height;

    float viewport_height = 2.0;
    float viewport_width =
        viewport_height * (float(image_width) / image_height);

    float focal_length = 1.0f;

    // viewport vectors
    vec3 viewport_u = vec3(viewport_width, 0., 0.);
    vec3 viewport_v = vec3(0., -viewport_height, 0.);

    // du, dv
    pixel_delta_u = viewport_u / image_width;
    pixel_delta_v = viewport_v / image_height;

    // get upper left pixel (0, 0)
    point3 viewport_upper_left = camera_center - vec3(0., 0., focal_length) -
                                 0.5 * (viewport_v)-0.5 * (viewport_u);
    pixel_00_loc = viewport_upper_left + ((pixel_delta_u + pixel_delta_v) / 2);
  }

  color ray_color(const ray &r, const hittable &world) {
    hit_record record;
    if (world.hit(r, interval(0, infinity), record)) {
      // turn normals from [-1, +1] -> [0,1] for coloring
      color normal_color = color(0.5 * (record.normal + 1));
      return normal_color;
    }

    vec3 unit_vector_r = unit_vector(r.direction());
    // go from [-1, 1] to [0, 1]
    float a = (unit_vector_r.y() + 1.0) * 0.5;
    color white(1., 1., 1.);
    color blue(0.5, 0.7, 1.0);
    color c = (1 - a) * white + a * blue;
    return c;
  }

public:
  int image_width = 300;
  float aspect_ratio = 1.0;
  point3 camera_center = point3(0.0, 0.0, 0.0);

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
        point3 pixel_center =
            pixel_00_loc + (j * pixel_delta_u) + (i * pixel_delta_v);
        vec3 ray_direction = vec3(pixel_center - camera_center);
        ray r = ray(camera_center, ray_direction);
        color pixel_color = ray_color(r, world);
        write_color(std::cout, pixel_color);
      }
    }
    std::clog << "\rDone.                        \n";
  }
};

#endif