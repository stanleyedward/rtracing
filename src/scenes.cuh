#ifndef SCENES_CUH
#define SCENES_CUH

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

// class scene {
// public:
//   virtual ~scene() = default;
//   __device__ virtual void create_scene() const = 0;
//   __device__ virtual void free_scene() const = 0;
// };

// class cornell_box : public scene {
// public:
//   int image_width = 600;
//   float aspect_ratio = 1.0f;
//   int image_height;

//   cornell_box(hittable** world, camera* cam, curandState* state) {
//     image_height = int(image_width / aspect_ratio);
//     image_height = image_height < 1 ? 1 : image_height;
//     GPUImage textures[2];
//     int num_textures = 0;

//     textures[num_textures++] = load_image_to_gpu("textures/junior.png");
//     textures[num_textures++] = load_image_to_gpu("textures/earthmap.jpg");

//     GPUImage *d_textures;
//     cudaMalloc(&d_textures, num_textures * sizeof(GPUImage));
//     cudaMemcpy(d_textures, textures, num_textures * sizeof(GPUImage),
//                 cudaMemcpyHostToDevice);

//   }

//   __device__ void create_scene() const override {}

//   __device__ void free_scene() const override { return; }
// };

__global__ void create_cornell_box(hittable **world, camera *cam,
                                   GPUImage *textures, curandState *state) {
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

void cornell_box(hittable **world, camera *cam, curandState *state) {

  GPUImage textures[2];
  int num_textures = 0;

  textures[num_textures++] = load_image_to_gpu("textures/junior.png");
  textures[num_textures++] = load_image_to_gpu("textures/earthmap.jpg");

  GPUImage *d_textures;
  cudaMalloc(&d_textures, num_textures * sizeof(GPUImage));
  cudaMemcpy(d_textures, textures, num_textures * sizeof(GPUImage),
             cudaMemcpyHostToDevice);

  create_cornell_box<<<1, 1>>>(world, cam, d_textures, state);
  CHECK_CUDA(cudaDeviceSynchronize());
}

#endif