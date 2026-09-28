#include "cuda_device_runtime_api.h"
#include "utils.cuh"
#include "common.cuh"
#include "scenes.cuh"
#include "radiance_caching.cuh"

#include "cuda_runtime.h"
#include "cuda_runtime_api.h"
#include "hittable.cuh"

#include "camera.cuh"
#include <iostream>

#define SCENE_NUMBER 1
#define SEED 2004
#define RADIANCE_CACHING false //for now

__global__ void render(float *output_image, hittable **world, hittable **lights, 
                       camera *cam, radiance_cache* cache, curandState *render_states) {
  unsigned int row = blockDim.y * blockIdx.y + threadIdx.y;
  unsigned int col = blockDim.x * blockIdx.x + threadIdx.x;
  if (row >= cam->image_height || col >= cam->image_width)
    return;
  vec3 pixel_color;
  unsigned int pixel_idx = row * cam->image_width + col;
  curandState local_rand_state = render_states[row * cam->image_width + col];
  pixel_color = cam->render(row, col, *world, *lights, cache, &local_rand_state);
  unsigned int output_idx = pixel_idx * 3;
#pragma unroll 3
  for (int i = 0; i < 3; i++)
    output_image[output_idx + i] = pixel_color[i];
  render_states[pixel_idx] = local_rand_state; // wrtb if need more frames
}

int main() {
  // cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024); // 128mb
  // cudaDeviceSetLimit(cudaLimitStackSize, 8192); // 8kb
  GPUTimer timer;

  // get random states
  curandState *d_init_rand_state;
  CHECK_CUDA(cudaMalloc((void **)&d_init_rand_state, 1 * sizeof(curandState)));
  rand_init_states<<<1, 1>>>(d_init_rand_state, SEED);
  CHECK_CUDA(cudaGetLastError());
  CHECK_CUDA(cudaDeviceSynchronize());

  std::unique_ptr<Scene> scene;
  switch (SCENE_NUMBER) {
  case 1:
    cudaDeviceSetLimit(cudaLimitStackSize, 8192);
    scene = Scene::cornell_box(d_init_rand_state);
    break;
  case 2:
    cudaDeviceSetLimit(cudaLimitStackSize, 8192 / 2);
    scene = Scene::cornell_smoke(d_init_rand_state);
    break;
  case 3:
    cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024);
    cudaDeviceSetLimit(cudaLimitStackSize, 8192);
    scene = Scene::final_scene(d_init_rand_state, 400, 450, 20);
    break;
  case 4:
    cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024);
    cudaDeviceSetLimit(cudaLimitStackSize, 8192);
    scene = Scene::final_scene(d_init_rand_state, 800, 10000, 40);
    break;
  default:
    scene = Scene::cornell_box(d_init_rand_state);
    break;
  }

  unsigned int output_image_size = scene->image_width * scene->image_height;
  curandState *d_render_states;

  CHECK_CUDA(cudaMalloc((void **)&d_render_states,
                        output_image_size * sizeof(curandState)));
  dim3 numThreadsPerBlock(TILE_SIZE, TILE_SIZE, 1);
  dim3 numBlocksPerGrid(CEIL_DIV(scene->image_width, TILE_SIZE),
                        CEIL_DIV(scene->image_height, TILE_SIZE), 1);
  rand_render_states<<<numBlocksPerGrid, numThreadsPerBlock>>>(
      scene->image_width, scene->image_height, d_render_states, SEED);
  CHECK_CUDA(cudaGetLastError());
  CHECK_CUDA(cudaDeviceSynchronize());

  float *d_output_image;
  float *h_output_image;
  h_output_image = (float *)malloc(output_image_size * CH * sizeof(float));

  radiance_cache* d_radcache = nullptr;
  cache_cell* d_cells = nullptr;
  if (RADIANCE_CACHING){
    size_t n_cells = CACHE_RES*CACHE_RES*CACHE_RES*CACHE_BINS;
    CHECK_CUDA(cudaMalloc(&d_cells, n_cells*sizeof(cache_cell)));
    CHECK_CUDA(cudaMemset(&d_cells, 0, n_cells*sizeof(cache_cell)));
    CHECK_CUDA(cudaMalloc(&d_radcache, sizeof(radiance_cache)));

    init_cache_kernel<<<1,1>>>(d_radcache, d_cells, scene->d_world);
    CHECK_CUDA(cudaGetLastError());
    CHECK_CUDA(cudaDeviceSynchronize());
  }

  CHECK_CUDA(
      cudaMalloc(&d_output_image, output_image_size * CH * sizeof(float)));
  std::clog << "[INFO] started rendering.\n";
  timer.begin();
  render<<<numBlocksPerGrid, numThreadsPerBlock>>>(
      d_output_image, scene->d_world, scene->d_lights, scene->d_cam, d_radcache,
      d_render_states);
  float time = timer.end();
  CHECK_CUDA(cudaGetLastError());
  CHECK_CUDA(cudaDeviceSynchronize());

  cudaMemcpy(h_output_image, d_output_image,
             output_image_size * CH * sizeof(float), cudaMemcpyDeviceToHost);

  std::clog << "time to render: " << time << " ms\n";

  // write to .ppm
  std::cout << "P3\n"
            << scene->image_width << " " << scene->image_height << "\n255\n";
  for (int i = 0; i < scene->image_height; i++) {
    for (int j = 0; j < scene->image_width; j++) {
      size_t pixel_index = (i * scene->image_width + j) * 3;
      float r = h_output_image[pixel_index + 0];
      float g = h_output_image[pixel_index + 1];
      float b = h_output_image[pixel_index + 2];

      write_color(std::cout, r, g, b);
    }
  }

  // free - figure out how to do this properly if we wnat animations.
  free(h_output_image);
  cudaFree(d_output_image);
  cudaFree(d_render_states);
  cudaFree(d_init_rand_state);
  if(d_radcache) CHECK_CUDA(cudaFree(d_radcache));
  if(d_cells) CHECK_CUDA(cudaFree(d_cells));

  return 0;
}