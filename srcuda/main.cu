#include <iostream>
#include "vec3.cuh"
#include "ray.cuh"

#define TILE_SIZE 16
#define CEIL_DIV(N, M)((N + M - 1) / M)

// limited version of checkCudaErrors from helper_cuda.h in CUDA examples
#define CHECK_CUDA(val) check_cuda( (val), #val, __FILE__, __LINE__ )
void check_cuda(cudaError_t result, char const *const func, const char *const file, int const line) {
    if (result) {
        std::cerr << "CUDA error = " << static_cast<unsigned int>(result) << " at " <<
            file << ":" << line << " '" << func << "' \n";
        cudaDeviceReset();
        exit(99);
    }
}

__device__ vec3 color(const ray& r){
    vec3 unit_direction = unit_vector(r.direction());
    float t = 0.5f*(unit_direction.y() + 1.f);
    return (1.0f-t)*vec3(1.0, 1.0, 1.0) + t*vec3(0.5, 0.7, 1.0);
}

__global__ void render(float *output_image, unsigned int image_width, unsigned int image_height){
    unsigned int row = blockDim.y * blockIdx.y + threadIdx.y;
    unsigned int col = blockDim.x * blockIdx.x + threadIdx.x;

    if (col >= image_width || row >= image_height) {return;}
    unsigned int pixel_id = (row*image_width*CH) + (col * CH);
    output_image[pixel_id + 0] = float(col) / image_width;
    output_image[pixel_id + 1] = float(row) / image_height;
    output_image[pixel_id + 2] = 0.2;
}

int main() {
  unsigned int image_width = 1200;
  float aspect_ratio = 16.0/9;
  unsigned int image_height = int(image_width / aspect_ratio);
  image_height = image_height < 1 ? 1 : image_height;

  //alloc mem for image
  int output_image_size = image_width * image_height;
  float *output_image;
  checkCudaErrors(cudaMallocManaged((void**) &output_image, output_image_size*sizeof(vec3)));
  
  dim3 numThreadsPerBlock(TILE_SIZE, TILE_SIZE, 1);
  dim3 numBlocksPerGrid(CEIL_DIV(image_width, TILE_SIZE), CEIL_DIV(image_height, TILE_SIZE), 1);
  render<<<numBlocksPerGrid, numThreadsPerBlock>>>(output_image, image_width, image_height);
  checkCudaErrors(cudaGetLastError());
  checkCudaErrors(cudaDeviceSynchronize());


  //write to .ppm
    std::cout << "P3\n" << image_width << " " << image_height << "\n255\n";
    for (int i = image_height-1; i >= 0; i--) {
        for (int j = 0; j < image_width; j++) {
            size_t pixel_index = i*3*image_width + j*3;
            float r = output_image[pixel_index + 0];
            float g = output_image[pixel_index + 1];
            float b = output_image[pixel_index + 2];
            int ir = int(255.99*r);
            int ig = int(255.99*g);
            int ib = int(255.99*b);
            std::cout << ir << " " << ig << " " << ib << "\n";
        }
    }
    
  //free
  checkCudaErrors(cudaFree(output_image));
  return 0;
}