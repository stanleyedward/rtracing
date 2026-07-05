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

  bool use_bvh = true;

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

  static Scene cornell_box(curandState *init_state) {
    Scene scene;
    scene.image_width = 600;
    scene.image_height = 600;

    GPUImage textures[2];
    textures[scene.num_textures++] = load_image_to_gpu("textures/junior.png");
    textures[scene.num_textures++] = load_image_to_gpu("textures/earthmap.jpg");
    CHECK_CUDA(
        cudaMalloc(&scene.d_textures, scene.num_textures * sizeof(GPUImage)));
    CHECK_CUDA(cudaMemcpy(scene.d_textures, textures,
                          scene.num_textures * sizeof(GPUImage),
                          cudaMemcpyHostToDevice));
    create_cornell_box_kernel<<<1, 1>>>(scene.d_world, scene.d_cam,
                                        scene.d_textures, init_state);
    CHECK_CUDA(cudaGetLastError());
    CHECK_CUDA(cudaDeviceSynchronize());
    return scene;
  }
};

#endif