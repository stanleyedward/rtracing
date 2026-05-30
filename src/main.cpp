// clang-format off
#include "common.h"
#include "color.h"

#include "bvh.h"
#include "hittable.h"
#include "hittable_list.h"
#include "material.h"
#include "perlin.h"
#include "sphere.h"

#include "camera.h"
#include "vec3.h"
#include <memory>
#include <chrono>
#include "texture.h"
// clang-format on

void perlin_spheres() {
  hittable_list world;

  shared_ptr<texture> perlin_tex = make_shared<noise_texture>(4);
  world.add(make_shared<sphere>(point3(0, -1000, 0), 1000,
                                make_shared<lambertian>(perlin_tex)));
  world.add(make_shared<sphere>(point3(0, 2, 0), 2,
                                make_shared<lambertian>(perlin_tex)));

  camera cam;

  cam.aspect_ratio = 16.0 / 9.0;
  cam.image_width = 400;
  cam.samples_per_pixel = 100;
  cam.max_depth = 50;

  cam.vFov = 20;
  cam.lookfrom = point3(13, 2, 3);
  cam.lookat = point3(0, 0, 0);
  cam.vUp = vec3(0, 1, 0);

  cam.defocus_angle = 0;

  std::chrono::time_point start = std::chrono::high_resolution_clock::now();
  cam.render(world);
  std::chrono::time_point end = std::chrono::high_resolution_clock::now();
  std::clog << "Total: "
            << std::chrono::duration_cast<std::chrono::milliseconds>(end -
                                                                     start)
                   .count()
            << "ms\n";
}

void junior() {
  shared_ptr<texture> junior_tex =
      make_shared<image_texture>("textures/junior.png");
  shared_ptr<material> junior_surface = make_shared<lambertian>(junior_tex);
  shared_ptr<hittable> globe =
      make_shared<sphere>(point3(0, 0, -2), 2, junior_surface);

  hittable_list world;
  world.add(globe);
  shared_ptr<material> mat1 = make_shared<metal>(color(0.7, 0.9, 0.9), 0.0);
  shared_ptr<hittable> globe2 = make_shared<sphere>(point3(0, 0, 2.2), 2, mat1);
  world.add(globe2);
  shared_ptr<material> ground_mat =
      make_shared<lambertian>(color(0.8, 0.8, 0.0));
  world.add(make_shared<sphere>(point3(0, -1002, 0), 1000, ground_mat));
  camera cam;

  cam.aspect_ratio = 16.0 / 9;
  cam.image_width = 600;
  cam.samples_per_pixel = 100;
  cam.max_depth = 50;

  cam.vFov = 20;
  cam.lookfrom = point3(36 / 3.0, 0, 6 / 3.0);
  cam.lookat = point3(0, 0, 0);
  cam.vUp = vec3(0, 1, 0);
  cam.defocus_angle = 0;
  cam.render(world);
}

void earth() {
  shared_ptr<texture> earth_tex =
      make_shared<image_texture>("textures/earthmap.jpg");
  shared_ptr<material> earth_surface = make_shared<lambertian>(earth_tex);
  shared_ptr<hittable> globe =
      make_shared<sphere>(point3(0, 0, 0), 2, earth_surface);

  camera cam;

  cam.aspect_ratio = 16.0 / 9;
  cam.image_width = 1200;
  cam.samples_per_pixel = 100;
  cam.max_depth = 50;

  cam.vFov = 20;
  cam.lookfrom = point3(0, 0, -12);
  cam.lookat = point3(0, 0, 0);
  cam.vUp = vec3(0, 1, 0);
  cam.defocus_angle = 0;
  cam.render(hittable_list(globe));
}

void checkered_spheres() {
  hittable_list world;
  shared_ptr<texture> checker = make_shared<checker_texture>(
      0.32, color(0.2, 0.3, 0.1), color(0.9, 0.9, 0.9));

  world.add(make_shared<sphere>(point3(0, -10, 0.), 10,
                                make_shared<lambertian>(checker)));
  world.add(make_shared<sphere>(point3(0, 10, 0.), 10,
                                make_shared<lambertian>(checker)));

  camera cam;
  cam.aspect_ratio = 16.0 / 9.0;
  cam.image_width = 400;
  cam.samples_per_pixel = 100;
  cam.max_depth = 50;

  cam.vFov = 20;
  cam.lookfrom = point3(13, 2, 3);
  cam.lookat = point3(0, 0, 0);
  cam.vUp = vec3(0, 1, 0);

  cam.defocus_angle = 0;
  cam.render(world);
}
void bouncing_spheres() {
  camera cam;
  cam.image_width = 400;
  cam.aspect_ratio = 16.0 / 9.0;
  cam.camera_center = point3(0.0f, 0.f, 0.f);
  cam.max_depth = 50;
  cam.samples_per_pixel = 100;
  cam.vFov = 20.0f;

  cam.lookfrom = point3(13, 2, 3);
  cam.lookat = point3(0, 0, 0);
  cam.vUp = vec3(0, 1, 0);
  cam.defocus_angle = 0.6;
  cam.focus_distance = 10.0;

  // world
  hittable_list world;

  // shared_ptr<material> ground_material =
  //     make_shared<lambertian>(color(0.5, 0.5, 0.5));
  shared_ptr<texture> checkers =
      make_shared<checker_texture>(0.32, color(.2, .3, .1), color(.9, .9, .9));
  world.add(make_shared<sphere>(point3(0, -1000, 0), 1000,
                                make_shared<lambertian>(checkers)));

  for (int a = -11; a < 11; a++) {
    for (int b = -11; b < 11; b++) {
      float choose_mat = random_float();
      point3 center(a + 0.9 * random_float(), 0.2, b + 0.9 * random_float());

      if ((center - point3(4, 0.2, 0)).length() > 0.9) {
        shared_ptr<material> sphere_material;

        if (choose_mat < 0.8) { // diffuse/lambertian
          color albedo = vec3::random() * vec3::random();
          sphere_material = make_shared<lambertian>(albedo);
          point3 center2 = center + vec3(0, random_float(0, 0.5), 0);
          world.add(make_shared<sphere>(center, center2, 0.2, sphere_material));
        }

        else if (choose_mat < 0.95) { // metal
          color albedo = vec3::random(0.5, 1);
          float fuzz = random_float(0, 0.5);
          sphere_material = make_shared<metal>(albedo, fuzz);
          world.add(make_shared<sphere>(center, 0.2, sphere_material));
        }

        else { // dielectric
          sphere_material = make_shared<dielectric>(1.5);
          world.add(make_shared<sphere>(center, 0.2, sphere_material));
        }
      }
    }
  }

  shared_ptr<material> material1 = make_shared<dielectric>(1.5);
  world.add(make_shared<sphere>(point3(0, 1, 0), 1.0, material1));

  shared_ptr<material> material2 =
      make_shared<lambertian>(color(0.4, 0.2, 0.1));
  world.add(make_shared<sphere>(point3(-4, 1, 0), 1.0, material2));

  shared_ptr<material> material3 =
      make_shared<metal>(color(0.7, 0.6, 0.5), 0.0);
  world.add(make_shared<sphere>(point3(4, 1, 0), 1.0, material3));

  world = hittable_list(make_shared<bvh_node>(world));

  std::chrono::time_point start = std::chrono::high_resolution_clock::now();
  cam.render(world);
  std::chrono::time_point end = std::chrono::high_resolution_clock::now();
  std::clog << "Total: "
            << std::chrono::duration_cast<std::chrono::milliseconds>(end -
                                                                     start)
                   .count()
            << "ms\n";
}

int main() {
  switch (5) {
  case 1:
    bouncing_spheres();
    break;
  case 2:
    checkered_spheres();
    break;
  case 3:
    junior();
    break;
  case 4:
    earth();
    break;
  case 5:
    perlin_spheres();
    break;
  }
}
