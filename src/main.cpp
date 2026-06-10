// clang-format off
#include "common.h"
#include "color.h"

#include "bvh.h"
#include "hittable.h"
#include "hittable_list.h"
#include "material.h"
#include "perlin.h"
#include "sphere.h"
#include "quad.h"

#include "camera.h"
#include "constant_medium.h"
#include "vec3.h"
#include <chrono>
#include "texture.h"
// clang-format on

void final_scene(int image_width, int samples_per_pixel, int max_depth) {
  hittable_list boxes1;
  auto ground = make_shared<lambertian>(color(0.48, 0.83, 0.53));

  int boxes_per_side = 20;
  for (int i = 0; i < boxes_per_side; i++) {
    for (int j = 0; j < boxes_per_side; j++) {
      auto w = 100.0;
      auto x0 = -1000.0 + i * w;
      auto z0 = -1000.0 + j * w;
      auto y0 = 0.0;
      auto x1 = x0 + w;
      auto y1 = random_float(1, 101);
      auto z1 = z0 + w;

      boxes1.add(box(point3(x0, y0, z0), point3(x1, y1, z1), ground));
    }
  }

  hittable_list world;

  world.add(make_shared<bvh_node>(boxes1));

  auto light = make_shared<diffuse_light>(color(7, 7, 7));
  world.add(make_shared<quad>(point3(123, 554, 147), vec3(300, 0, 0),
                              vec3(0, 0, 265), light));

  auto center1 = point3(400, 400, 200);
  auto center2 = center1 + vec3(30, 0, 0);
  auto sphere_material = make_shared<lambertian>(color(0.7, 0.3, 0.1));
  world.add(make_shared<sphere>(center1, center2, 50, sphere_material));

  world.add(make_shared<sphere>(point3(260, 150, 45), 50,
                                make_shared<dielectric>(1.5)));
  world.add(make_shared<sphere>(point3(0, 150, 145), 50,
                                make_shared<metal>(color(0.8, 0.8, 0.9), 1.0)));

  auto boundary = make_shared<sphere>(point3(360, 150, 145), 70,
                                      make_shared<dielectric>(1.5));
  world.add(boundary);
  world.add(make_shared<constant_medium>(boundary, 0.2, color(0.2, 0.4, 0.9)));
  boundary =
      make_shared<sphere>(point3(0, 0, 0), 5000, make_shared<dielectric>(1.5));
  world.add(make_shared<constant_medium>(boundary, .0001, color(1, 1, 1)));

  auto emat = make_shared<lambertian>(
      make_shared<image_texture>("textures/junior.png"));
  world.add(make_shared<sphere>(point3(400, 200, 400), 100, emat));
  auto pertext = make_shared<noise_texture>(0.2);
  world.add(make_shared<sphere>(point3(220, 280, 300), 80,
                                make_shared<lambertian>(pertext)));

  hittable_list boxes2;
  auto white = make_shared<lambertian>(color(.73, .73, .73));
  int ns = 1000;
  for (int j = 0; j < ns; j++) {
    boxes2.add(make_shared<sphere>(point3::random(0, 165), 10, white));
  }

  world.add(make_shared<translate>(
      make_shared<rotate_y>(make_shared<bvh_node>(boxes2), 15),
      vec3(-100, 270, 395)));

  camera cam;

  cam.aspect_ratio = 1.0;
  cam.image_width = image_width;
  cam.samples_per_pixel = samples_per_pixel;
  cam.max_depth = max_depth;
  cam.background = color(0, 0, 0);

  cam.vFov = 40;
  cam.lookfrom = point3(478, 278, -600);
  cam.lookat = point3(278, 278, 0);
  cam.vUp = vec3(0, 1, 0);

  cam.defocus_angle = 0;

  cam.render(world);
}
void cornell_smoke() {
  hittable_list world;

  auto red = make_shared<lambertian>(color(.65, .05, .05));
  auto white = make_shared<lambertian>(color(.73, .73, .73));
  auto green = make_shared<lambertian>(color(.12, .45, .15));
  auto light = make_shared<diffuse_light>(color(7, 7, 7));

  world.add(make_shared<quad>(point3(555, 0, 0), vec3(0, 555, 0),
                              vec3(0, 0, 555), green));
  world.add(make_shared<quad>(point3(0, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555),
                              red));
  world.add(make_shared<quad>(point3(113, 554, 127), vec3(330, 0, 0),
                              vec3(0, 0, 305), light));
  world.add(make_shared<quad>(point3(0, 555, 0), vec3(555, 0, 0),
                              vec3(0, 0, 555), white));
  world.add(make_shared<quad>(point3(0, 0, 0), vec3(555, 0, 0), vec3(0, 0, 555),
                              white));
  world.add(make_shared<quad>(point3(0, 0, 555), vec3(555, 0, 0),
                              vec3(0, 555, 0), white));

  shared_ptr<hittable> box1 =
      box(point3(0, 0, 0), point3(165, 330, 165), white);
  box1 = make_shared<rotate_y>(box1, 15);
  box1 = make_shared<translate>(box1, vec3(265, 0, 295));

  shared_ptr<hittable> box2 =
      box(point3(0, 0, 0), point3(165, 165, 165), white);
  box2 = make_shared<rotate_y>(box2, -18);
  box2 = make_shared<translate>(box2, vec3(130, 0, 65));

  world.add(make_shared<constant_medium>(box1, 0.01, color(0, 0, 0)));
  world.add(make_shared<constant_medium>(box2, 0.01, color(1, 1, 1)));

  camera cam;

  cam.aspect_ratio = 1.0;
  cam.image_width = 600;
  cam.samples_per_pixel = 200;
  cam.max_depth = 50;
  cam.background = color(0, 0, 0);

  cam.vFov = 40;
  cam.lookfrom = point3(278, 278, -800);
  cam.lookat = point3(278, 278, 0);
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

void cornell_box() {
  hittable_list world;

  auto red = make_shared<lambertian>(color(.65, .05, .05));
  auto white = make_shared<lambertian>(color(.73, .73, .73));
  auto green = make_shared<lambertian>(color(.12, .45, .15));
  auto light = make_shared<diffuse_light>(color(15, 15, 15));

  world.add(make_shared<quad>(point3(555, 0, 0), vec3(0, 555, 0),
                              vec3(0, 0, 555), green));
  world.add(make_shared<quad>(point3(0, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555),
                              red));
  world.add(make_shared<quad>(point3(343, 554, 332), vec3(-130, 0, 0),
                              vec3(0, 0, -105), light));
  world.add(make_shared<quad>(point3(0, 0, 0), vec3(555, 0, 0), vec3(0, 0, 555),
                              white));
  world.add(make_shared<quad>(point3(555, 555, 555), vec3(-555, 0, 0),
                              vec3(0, 0, -555), white));
  world.add(make_shared<quad>(point3(0, 0, 555), vec3(555, 0, 0),
                              vec3(0, 555, 0), white));

  shared_ptr<hittable> box1 =
      box(point3(0, 0, 0), point3(165, 330, 165), white);
  box1 = make_shared<rotate_y>(box1, 15);
  box1 = make_shared<translate>(box1, vec3(265, 0, 295));
  world.add(box1);

  shared_ptr<hittable> box2 =
      box(point3(0, 0, 0), point3(165, 165, 165), white);
  box2 = make_shared<rotate_y>(box2, -18);
  box2 = make_shared<translate>(box2, vec3(130, 0, 65));
  world.add(box2);
  camera cam;

  cam.aspect_ratio = 1.0;
  cam.image_width = 600;
  cam.samples_per_pixel = 200;
  cam.max_depth = 50;
  cam.background = color(0, 0, 0);
  cam.use_sky_gradient = false;

  cam.vFov = 40;
  cam.lookfrom = point3(278, 278, -800);
  cam.lookat = point3(278, 278, 0);
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

void simple_light() {
  hittable_list world;

  auto pertext = make_shared<noise_texture>(4);
  world.add(make_shared<sphere>(point3(0, -1000, 0), 1000,
                                make_shared<lambertian>(pertext)));
  world.add(make_shared<sphere>(point3(0, 2, 0), 2,
                                make_shared<lambertian>(pertext)));

  auto difflight = make_shared<diffuse_light>(color(4, 4, 4));
  world.add(make_shared<sphere>(point3(0, 7, 0), 2, difflight));
  world.add(make_shared<quad>(point3(3, 1, -2), vec3(2, 0, 0), vec3(0, 2, 0),
                              difflight));

  camera cam;

  cam.aspect_ratio = 16.0 / 9.0;
  cam.image_width = 400;
  cam.samples_per_pixel = 100;
  cam.max_depth = 50;
  cam.background = color(0, 0, 0);
  cam.use_sky_gradient = false;

  cam.vFov = 20;
  cam.lookfrom = point3(26, 3, 6);
  cam.lookat = point3(0, 2, 0);
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

void more2d() {
  hittable_list world;

  auto left_red = make_shared<lambertian>(color(1.0, 0.2, 0.2));
  auto back_green = make_shared<lambertian>(color(0.2, 1.0, 0.2));
  auto right_blue = make_shared<lambertian>(color(0.2, 0.2, 1.0));
  auto upper_orange = make_shared<lambertian>(color(1.0, 0.5, 0.0));
  auto lower_teal = make_shared<lambertian>(color(0.2, 0.8, 0.8));

  world.add(make_shared<quad>(point3(-3, -2, 5), vec3(0, 0, -4), vec3(0, 4, 0),
                              left_red));
  world.add(make_shared<quad>(point3(-2, -2, 0), vec3(4, 0, 0), vec3(0, 4, 0),
                              back_green));
  world.add(make_shared<tri>(point3(3, -2, 1), vec3(0, 0, 4), vec3(0, 4, 0),
                             right_blue));
  world.add(make_shared<ellipse>(point3(-2, 3, 1), vec3(4, 0, 0), vec3(0, 0, 4),
                                 upper_orange));
  world.add(make_shared<annulus>(point3(-2, -3, 5), vec3(4, 0, 0),
                                 vec3(0, 0, -4), .2, lower_teal));

  camera cam;

  cam.aspect_ratio = 1.0;
  cam.image_width = 400;
  cam.samples_per_pixel = 100;
  cam.max_depth = 50;

  cam.vFov = 80;
  cam.lookfrom = point3(0, 0, 9);
  cam.lookat = point3(0, 0, 0);
  cam.vUp = vec3(0, 1, 0);
  cam.background = color(0.70, 0.80, 1.00);
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

  cam.background = color(0.70, 0.80, 1.00);
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

void quads() {
  hittable_list world;

  auto left_red = make_shared<lambertian>(color(1.0, 0.2, 0.2));
  auto back_green = make_shared<lambertian>(color(0.2, 1.0, 0.2));
  auto right_blue = make_shared<lambertian>(color(0.2, 0.2, 1.0));
  auto upper_orange = make_shared<lambertian>(color(1.0, 0.5, 0.0));
  auto lower_teal = make_shared<lambertian>(color(0.2, 0.8, 0.8));

  world.add(make_shared<quad>(point3(-3, -2, 5), vec3(0, 0, -4), vec3(0, 4, 0),
                              left_red));
  world.add(make_shared<quad>(point3(-2, -2, 0), vec3(4, 0, 0), vec3(0, 4, 0),
                              back_green));
  world.add(make_shared<quad>(point3(3, -2, 1), vec3(0, 0, 4), vec3(0, 4, 0),
                              right_blue));
  world.add(make_shared<quad>(point3(-2, 3, 1), vec3(4, 0, 0), vec3(0, 0, 4),
                              upper_orange));
  world.add(make_shared<quad>(point3(-2, -3, 5), vec3(4, 0, 0), vec3(0, 0, -4),
                              lower_teal));

  camera cam;

  cam.aspect_ratio = 1.0;
  cam.image_width = 400;
  cam.samples_per_pixel = 100;
  cam.max_depth = 50;

  cam.vFov = 80;
  cam.lookfrom = point3(0, 0, 9);
  cam.lookat = point3(0, 0, 0);
  cam.vUp = vec3(0, 1, 0);

  cam.background = color(0.70, 0.80, 1.00);
  cam.defocus_angle = 0;

  cam.render(world);
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

  cam.background = color(0.70, 0.80, 1.00);
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

  cam.background = color(0.70, 0.80, 1.00);
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

  cam.background = color(0.70, 0.80, 1.00);
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

  cam.background = color(0.70, 0.80, 1.00);
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

int main() { // these are just different scenes
  switch (12) {
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
  case 6:
    quads();
    break;
  case 7:
    more2d();
    break;
  case 8:
    simple_light();
    break;
  case 9:
    cornell_box();
    break;
  case 10:
    cornell_smoke();
    break;
  case 11:
    final_scene(800, 10000, 40);
    break;
  case 12:
    final_scene(600, 1000, 25);
    break;
  default:
    final_scene(400, 50, 4);
    break;
  }
}
