#ifndef UTILS_CUH
#define UTILS_CUH

#include "cuda_runtime_api.h"
#include "rtw_stb.h"
#include "common.cuh"

// limited version of checkCudaErrors from helper_cuda.h in CUDA examples
#define CHECK_CUDA(val) check_cuda((val), #val, __FILE__, __LINE__)
void check_cuda(cudaError_t result, char const *const func,
                const char *const file, int const line) {
  if (result) {
    std::cerr << "CUDA error = " << static_cast<unsigned int>(result) << " at "
              << file << ":" << line << " '" << func << "' \n";
    cudaDeviceReset();
    exit(99);
  }
}

struct GPUImage {
  unsigned char *data;
  int width;
  int height;
  int channels;
};

GPUImage load_image_to_gpu(const char *filename) {
  GPUImage img;
  unsigned char *h_data =
      stbi_load(filename, &img.width, &img.height, &img.channels, CH);

  size_t size = img.width * img.height * CH;
  cudaMalloc(&img.data, size * sizeof(unsigned char));
  cudaMemcpy(img.data, h_data, size * sizeof(unsigned char),
             cudaMemcpyHostToDevice);
  stbi_image_free(h_data);
  return img;
}

class GPUTimer {
public:
  cudaEvent_t start;
  cudaEvent_t stop;

  GPUTimer() {
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
  }

  ~GPUTimer() {
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
  }

  void begin() { cudaEventRecord(start); }
  float end() {
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms = 0;
    cudaEventElapsedTime(&ms, start, stop);
    return ms;
  }
};

#endif
