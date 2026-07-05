#include "utils.cuh"
#include "common.cuh"
#include "scenes.cuh"

#include "cuda_runtime.h"
#include "cuda_runtime_api.h"
#include "hittable.cuh"

#include "camera.cuh"
#include <iostream>

#define SCENE_NUMBER 1
#define SEED 2004

__global__ void render(float *output_image, hittable **world, camera *cam,
                       curandState *render_states) {
  unsigned int row = blockDim.y * blockIdx.y + threadIdx.y;
  unsigned int col = blockDim.x * blockIdx.x + threadIdx.x;
  if (row >= cam->image_height || col >= cam->image_width)
    return;
  vec3 pixel_color;
  unsigned int pixel_idx = row * cam->image_width + col;
  curandState local_rand_state = render_states[row * cam->image_width + col];
  pixel_color = cam->render(row, col, *world, &local_rand_state);
  unsigned int output_idx = pixel_idx * 3;
#pragma unroll 3
  for (int i = 0; i < 3; i++)
    output_image[output_idx + i] = pixel_color[i];
  render_states[pixel_idx] = local_rand_state; // wrtb if need more frames
}

int main() {
  // cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024); // 128mb
  // cudaDeviceSetLimit(cudaLimitStackSize, 8192); //8kb
  GPUTimer timer;

  int image_width;
  int image_height;
  float aspect_ratio;

  // get random states
  curandState *d_init_rand_state;
  CHECK_CUDA(cudaMalloc((void **)&d_init_rand_state, 1 * sizeof(curandState)));
  rand_init_states<<<1, 1>>>(d_init_rand_state, SEED);
  CHECK_CUDA(cudaGetLastError());
  CHECK_CUDA(cudaDeviceSynchronize());

  hittable **d_world;
  camera *d_cam;
  CHECK_CUDA(cudaMalloc(&d_world, sizeof(hittable *)));
  CHECK_CUDA(cudaMalloc(&d_cam, sizeof(camera)));
  // create the scene use the init state rand
  switch (SCENE_NUMBER) {
  case 1: // cornell box
    image_width = 600;
    aspect_ratio = 1.0f;
    image_height = int(image_width / aspect_ratio);
    image_height = image_height < 1 ? 1 : image_height;
    cornell_box(d_world, d_cam, d_init_rand_state);
    break;
  default:
    image_width = 600;
    aspect_ratio = 1.0f;
    image_height = int(image_width / aspect_ratio);
    image_height = image_height < 1 ? 1 : image_height;
    cornell_box(d_world, d_cam, d_init_rand_state);
    break;
  }

  // 2 ways to do it
  /*
  either i have switch statements here in main, or i try to just pass the number
  then do something, or i could look into using if statments and objcount to get
  1 freeing method
  */

  unsigned int output_image_size = image_width * image_height;
  curandState *d_render_states;

  CHECK_CUDA(cudaMalloc((void **)&d_render_states,
                        output_image_size * sizeof(curandState)));
  dim3 numThreadsPerBlock(TILE_SIZE, TILE_SIZE, 1);
  dim3 numBlocksPerGrid(CEIL_DIV(image_width, TILE_SIZE),
                        CEIL_DIV(image_height, TILE_SIZE), 1);
  timer.begin();
  rand_render_states<<<numBlocksPerGrid, numThreadsPerBlock>>>(
      image_width, image_height, d_render_states, SEED);
  float time = timer.end();

  CHECK_CUDA(cudaGetLastError());
  CHECK_CUDA(cudaDeviceSynchronize());

  float *d_output_image;
  float *h_output_image;
  h_output_image = (float *)malloc(output_image_size * CH * sizeof(float));

  cudaMalloc(&d_output_image, output_image_size * CH * sizeof(float));
  render<<<numBlocksPerGrid, numThreadsPerBlock>>>(d_output_image, d_world,
                                                   d_cam, d_render_states);
  CHECK_CUDA(cudaGetLastError());
  CHECK_CUDA(cudaDeviceSynchronize());

  cudaMemcpy(h_output_image, d_output_image,
             output_image_size * CH * sizeof(float), cudaMemcpyDeviceToHost);

  std::clog << "time to render: " << time << " ms\n";

  // write to .ppm
  std::cout << "P3\n" << image_width << " " << image_height << "\n255\n";
  for (int i = 0; i < image_height; i++) {
    for (int j = 0; j < image_width; j++) {
      size_t pixel_index = (i * image_width + j) * 3;
      float r = h_output_image[pixel_index + 0];
      float g = h_output_image[pixel_index + 1];
      float b = h_output_image[pixel_index + 2];

      write_color(std::cout, r, g, b);
    }
  }

  // free - figure out how to do this.
  CHECK_CUDA(cudaFree(d_output_image));
  return 0;
}