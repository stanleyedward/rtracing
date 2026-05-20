// clang-format off
#include "common.h"
#include "color.h"

#include "bvh.h"
#include "hittable.h"
#include "hittable_list.h"
#include "material.h"
#include "sphere.h"

#include "camera.h"
#include "vec3.h"
#include <memory>
// clang-format on

int main() {

  camera cam;
  cam.image_width = 400;
  cam.aspect_ratio = 16.0 / 9.0;
  cam.camera_center = point3(0.0f, 0.f, 0.f);
  cam.max_depth = 50;
  cam.samples_per_pixel = 100; // anti-alias, other stuff as well now
  cam.vFov = 20.0f;

  cam.lookfrom = point3(13, 2, 3);
  cam.lookat = point3(0, 0, 0);
  cam.vUp = vec3(0, 1, 0);
  cam.defocus_angle = 0.6;
  cam.focus_distance = 10.0;

  // world
  hittable_list world;

  shared_ptr<material> ground_material =
      make_shared<lambertian>(color(0.5, 0.5, 0.5));
  world.add(make_shared<sphere>(point3(0, -1000, 0), 1000, ground_material));

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

  cam.render(world);
}
