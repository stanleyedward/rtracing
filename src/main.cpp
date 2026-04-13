#include "common.h"

#include "hittable.h"
#include "hittable_list.h"
#include "sphere.h"

#include "camera.h"

int main() {

  camera cam;
  cam.image_width = 500;
  cam.aspect_ratio = 16.0 / 9.0;
  cam.camera_center = point3(0.f, 0.f, 0.f);

  // world
  hittable_list world;
  world.add(make_shared<sphere>(point3(0.0f, 0.0f, -1.0f), 0.5));
  world.add(make_shared<sphere>(point3(0.0f, -100.5f, -1.0f), 100.0f));

  cam.render(world);
}
