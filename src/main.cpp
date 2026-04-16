#include "common.h"

#include "hittable.h"
#include "hittable_list.h"
#include "material.h"
#include "sphere.h"

#include "camera.h"
#include <memory>

int main() {

  camera cam;
  cam.image_width = 800;
  cam.aspect_ratio = 16.0 / 9.0;
  cam.camera_center = point3(0.0f, 0.f, 0.f);
  cam.focal_length = 1.0f;
  cam.max_depth = 50;
  cam.samples_per_pixel = 100; // anti-alias, other stuff as well now

  // materials
  shared_ptr<material> material_ground =
      std::make_shared<lambertian>(color(0.8, 0.8, 0.0));
  shared_ptr<material> material_center =
      std::make_shared<lambertian>(color(0.1, 0.2, 0.5));
  shared_ptr<material> material_left = std::make_shared<dielectric>(1.50);
  shared_ptr<material> material_bubble =
      std::make_shared<dielectric>(1.00 / 1.50);
  shared_ptr<material> material_right =
      std::make_shared<metal>(color(0.8, 0.6, 0.2), 0.25);

  // world
  hittable_list world;
  world.add(make_shared<sphere>(point3(0.0f, -100.5f, -1.0f), 100.0f,
                                material_ground));
  world.add(
      make_shared<sphere>(point3(0.0f, 0.0f, -1.2f), 0.5, material_center));
  world.add(
      make_shared<sphere>(point3(-1.0f, 0.0f, -1.0f), 0.5, material_left));
  world.add(
      make_shared<sphere>(point3(-1.0f, 0.f, -1.0f), 0.4, material_bubble));
  world.add(
      make_shared<sphere>(point3(1.0f, 0.0f, -1.0f), 0.5, material_right));

  cam.render(world);
}
