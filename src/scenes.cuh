#ifndef SCENES_CUH
#define SCENES_CUH

#include "cuda_runtime_api.h"
#include "driver_types.h"
#include "utils.cuh"
#include "common.cuh"
#include "bvh.cuh"

#include "hittable.cuh"
#include "hittable_list.cuh"
#include "material.cuh"
#include "perlin.cuh"
#include "sphere.cuh"
#include "quad.cuh"

#include "camera.cuh"
#include "constant_medium.cuh"
#include "texture.cuh"
#include <algorithm>

#define USE_BVH true

__global__ void create_final_scene_kernel(hittable **world, camera *cam,
                                          GPUImage *textures,
                                          curandState *state, int image_width,
                                          int samples_per_pixel,
                                          int max_depth) {
  if (threadIdx.x != 0 || blockIdx.x != 0)
    return;

  hittable **objects_list = new hittable *[11];
  unsigned int object_count = 0;

  // boxes on the floor
  int boxes_per_side = 20;
  int b1_total = boxes_per_side * boxes_per_side;
  hittable **boxes1 = new hittable *[b1_total];
  int b1_count = 0;
  auto ground = new lambertian(color(0.48, 0.83, 0.53));

  for (int i = 0; i < boxes_per_side; i++) {
    for (int j = 0; j < boxes_per_side; j++) {
      auto w = 100.0f;
      auto x0 = -1000.0f + i * w;
      auto z0 = -1000.0f + j * w;
      auto y0 = 0.0f;
      auto x1 = x0 + w;
      auto y1 = random_float(1.0f, 101.0f, state);
      auto z1 = z0 + w;

      boxes1[b1_count++] = box(point3(x0, y0, z0), point3(x1, y1, z1), ground);
    }
  }
  objects_list[object_count++] = bvh_node::create_bvh_tree(boxes1, 0, b1_count);

  /// light quad
  auto light = new diffuse_light(color(7, 7, 7));
  objects_list[object_count++] =
      new quad(point3(123, 554, 147), vec3(300, 0, 0), vec3(0, 0, 265), light);

  // moving sphere
  auto center1 = point3(400, 400, 200);
  auto center2 = center1 + vec3(30, 0, 0);
  auto sphere_material = new lambertian(color(0.7, 0.3, 0.1));
  objects_list[object_count++] =
      new sphere(center1, center2, 50, sphere_material);

  // glass metal
  objects_list[object_count++] =
      new sphere(point3(260, 150, 45), 50, new dielectric(1.5));
  objects_list[object_count++] =
      new sphere(point3(0, 150, 145), 50, new metal(color(0.8, 0.8, 0.9), 1.0));

  // boudnary spehre and constant med
  auto boundary = new sphere(point3(360, 150, 145), 70, new dielectric(1.5));
  objects_list[object_count++] = boundary;
  objects_list[object_count++] =
      new constant_medium(boundary, 0.2, color(0.2, 0.4, 0.9));

  // globalfog
  auto boundary2 = new sphere(point3(0, 0, 0), 5000, new dielectric(1.5));
  objects_list[object_count++] =
      new constant_medium(boundary2, 0.0001, color(1, 1, 1));

  // texture pshere
  auto emat = new lambertian(new image_texture(textures[0]));
  auto junior_sphere = new sphere(point3(0, 0, 0), 100, emat);
  objects_list[object_count++] =
      new translate(new rotate_y(junior_sphere, 90), vec3(400, 200, 400));

  // noise sphere
  auto pertext = new noise_texture(state, 0.2);
  objects_list[object_count++] =
      new sphere(point3(220, 280, 300), 80, new lambertian(pertext));

  // 100 spheres box
  int ns = 1000;
  hittable **boxes2 = new hittable *[ns];
  auto white = new lambertian(color(.73, .73, .73));
  for (int j = 0; j < ns; j++) {
    point3 rand_pt(random_float(0.0f, 165.0f, state),
                   random_float(0.0f, 165.0f, state),
                   random_float(0.0f, 165.0f, state));
    boxes2[j] = new sphere(rand_pt, 10, white);
  }
  hittable *boxes2_bvh = bvh_node::create_bvh_tree(boxes2, 0, ns);
  objects_list[object_count++] =
      new translate(new rotate_y(boxes2_bvh, 15), vec3(-100, 270, 395));

  // final bvh
  *world = bvh_node::create_bvh_tree(objects_list, 0, object_count);

  new (cam) camera();
  cam->aspect_ratio = 1.0;
  cam->image_width = image_width;
  cam->samples_per_pixel = samples_per_pixel;
  cam->max_depth = max_depth;
  cam->background = color(0, 0, 0);

  cam->vFov = 40;
  cam->lookfrom = point3(478, 278, -600);
  cam->lookat = point3(278, 278, 0);
  cam->vUp = vec3(0, 1, 0);
  cam->defocus_angle = 0;

  cam->initialize();
}

__global__ void create_cornell_box_kernel(hittable **world, camera *cam,
                                          GPUImage *textures,
                                          curandState *state) {
  if (!(threadIdx.x == 0 && blockIdx.x == 0))
    return;
  // init_world
  hittable **objects_list = new hittable *[8];
  unsigned int object_count = 0;

  // walls
  auto red = new lambertian(color(.65, .05, .05));
  auto white = new lambertian(color(.73, .73, .73));
  auto green = new lambertian(color(.12, .45, .15));
  auto light = new diffuse_light(color(15, 15, 15));
  auto junior_tex = new image_texture(textures[0]);

  objects_list[object_count++] =
      new quad(point3(555, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555), green);
  objects_list[object_count++] =
      new quad(point3(0, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555), red);
  objects_list[object_count++] = new quad(
      point3(343, 554, 332), vec3(-130, 0, 0), vec3(0, 0, -105), light);
  objects_list[object_count++] =
      new quad(point3(0, 0, 0), vec3(555, 0, 0), vec3(0, 0, 555), white);
  objects_list[object_count++] = new quad(
      point3(555, 555, 555), vec3(-555, 0, 0), vec3(0, 0, -555), white);
  objects_list[object_count++] =
      new quad(point3(0, 0, 555), vec3(555, 0, 0), vec3(0, 555, 0), white);

  // boxes
  hittable *box1 = box(point3(0, 0, 0), point3(165, 330, 165), white);
  box1 = new rotate_y(box1, 15);
  box1 = new translate(box1, vec3(265, 0, 295));
  objects_list[object_count++] = box1;

  hittable *box2 = box(point3(0, 0, 0), point3(165, 165, 165), white);
  box2 = new rotate_y(box2, -18);
  box2 = new translate(box2, vec3(130, 0, 65));
  objects_list[object_count++] = box2;

  bool use_bvh = USE_BVH;

  if (use_bvh) {
    *world = bvh_node::create_bvh_tree(objects_list, 0, object_count);
  } else
    *world = new hittable_list(objects_list, object_count);

  new (cam) camera();
  // init_camera
  cam->aspect_ratio = 1.0;
  cam->image_width = 600;
  cam->samples_per_pixel = 1000;
  cam->max_depth = 50;
  cam->background = color(0, 0, 0);
  cam->use_sky_gradient = false;

  cam->vFov = 40;
  cam->lookfrom = point3(278, 278, -800);
  cam->lookat = point3(278, 278, 0);
  cam->vUp = vec3(0, 1, 0);
  cam->defocus_angle = 0;
  cam->initialize();
}

__global__ void create_cornell_smoke_kernel(hittable **world, camera *cam,
                                            GPUImage *textures,
                                            curandState *state) {
  if (!(threadIdx.x == 0 && blockIdx.x == 0))
    return;
  // init_world
  hittable **objects_list = new hittable *[8];
  unsigned int object_count = 0;

  // walls
  auto red = new lambertian(color(.65, .05, .05));
  auto white = new lambertian(color(.73, .73, .73));
  auto green = new lambertian(color(.12, .45, .15));
  auto light = new diffuse_light(color(15, 15, 15));

  // side quads
  objects_list[object_count++] =
      new quad(point3(555, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555), green);
  objects_list[object_count++] =
      new quad(point3(0, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555), red);
  objects_list[object_count++] = new quad(
      point3(343, 554, 332), vec3(-130, 0, 0), vec3(0, 0, -105), light);
  objects_list[object_count++] =
      new quad(point3(0, 0, 0), vec3(555, 0, 0), vec3(0, 0, 555), white);
  objects_list[object_count++] = new quad(
      point3(555, 555, 555), vec3(-555, 0, 0), vec3(0, 0, -555), white);
  objects_list[object_count++] =
      new quad(point3(0, 0, 555), vec3(555, 0, 0), vec3(0, 555, 0), white);

  // boxes
  hittable *box1 = box(point3(0, 0, 0), point3(165, 330, 165), white);
  box1 = new rotate_y(box1, 15);
  box1 = new translate(box1, vec3(265, 0, 295));
  box1 = new constant_medium(box1, 0.01, color(0, 0, 0));
  objects_list[object_count++] = box1;

  hittable *box2 = box(point3(0, 0, 0), point3(165, 165, 165), white);
  box2 = new rotate_y(box2, -18);
  box2 = new translate(box2, vec3(130, 0, 65));
  box2 = new constant_medium(box2, 0.01, color(1, 1, 1));
  objects_list[object_count++] = box2;

  bool use_bvh = USE_BVH;

  if (use_bvh) {
    *world = bvh_node::create_bvh_tree(objects_list, 0, object_count);
  } else
    *world = new hittable_list(objects_list, object_count);

  new (cam) camera();
  // init_camera
  cam->aspect_ratio = 1.0;
  cam->image_width = 600;
  cam->samples_per_pixel = 200;
  cam->max_depth = 50;
  cam->background = color(0, 0, 0);
  cam->use_sky_gradient = false;

  cam->vFov = 40;
  cam->lookfrom = point3(278, 278, -800);
  cam->lookat = point3(278, 278, 0);
  cam->vUp = vec3(0, 1, 0);
  cam->defocus_angle = 0;
  cam->initialize();
}

class Scene {
public:
  int image_width;
  int image_height;

  // gpu res
  hittable **d_world;
  camera *d_cam;
  GPUImage *d_textures;
  int num_textures;

  Scene()
      : d_world(nullptr), d_cam(nullptr), d_textures(nullptr), num_textures(0) {
    CHECK_CUDA(cudaMalloc(&d_world, sizeof(hittable *)));
    CHECK_CUDA(cudaMalloc(&d_cam, sizeof(camera)));
  }

  ~Scene() {
    // TODO: free world kernel somehow
    if (d_world)
      cudaFree(d_world);
    if (d_cam)
      cudaFree(d_cam);
    if (d_textures)
      cudaFree(d_textures);
  }

  static std::unique_ptr<Scene> cornell_box(curandState *init_state) {
    auto scene = std::make_unique<Scene>();
    scene->image_width = 600;
    scene->image_height = 600;

    GPUImage textures[2];
    textures[scene->num_textures++] = load_image_to_gpu("textures/junior.png");
    textures[scene->num_textures++] =
        load_image_to_gpu("textures/earthmap.jpg");
    CHECK_CUDA(
        cudaMalloc(&scene->d_textures, scene->num_textures * sizeof(GPUImage)));
    CHECK_CUDA(cudaMemcpy(scene->d_textures, textures,
                          scene->num_textures * sizeof(GPUImage),
                          cudaMemcpyHostToDevice));
    create_cornell_box_kernel<<<1, 1>>>(scene->d_world, scene->d_cam,
                                        scene->d_textures, init_state);
    CHECK_CUDA(cudaGetLastError());
    CHECK_CUDA(cudaDeviceSynchronize());
    return scene;
  }

  static std::unique_ptr<Scene> cornell_smoke(curandState *init_state) {
    auto scene = std::make_unique<Scene>();
    scene->image_width = 600;
    scene->image_height = 600;

    create_cornell_smoke_kernel<<<1, 1>>>(scene->d_world, scene->d_cam,
                                          scene->d_textures, init_state);
    CHECK_CUDA(cudaGetLastError());
    CHECK_CUDA(cudaDeviceSynchronize());
    return scene;
  }

  static std::unique_ptr<Scene> final_scene(curandState *init_state,
                                            int image_width, int spp,
                                            int max_depth) {
    auto scene = std::make_unique<Scene>();

    scene->image_width = image_width;
    scene->image_height = image_width;

    GPUImage textures[1];
    textures[scene->num_textures++] = load_image_to_gpu("textures/junior.png");

    CHECK_CUDA(
        cudaMalloc(&scene->d_textures, scene->num_textures * sizeof(GPUImage)));
    CHECK_CUDA(cudaMemcpy(scene->d_textures, textures,
                          scene->num_textures * sizeof(GPUImage),
                          cudaMemcpyHostToDevice));

    create_final_scene_kernel<<<1, 1>>>(scene->d_world, scene->d_cam,
                                        scene->d_textures, init_state,
                                        image_width, spp, max_depth);

    CHECK_CUDA(cudaGetLastError());
    CHECK_CUDA(cudaDeviceSynchronize());

    return scene;
  }
};

#endif