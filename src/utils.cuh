#ifndef UTILS_CUH
#define UTILS_CUH

#include "cuda_runtime_api.h"

struct GPUImage {
  unsigned char *data;
  int width;
  int height;
  int channels;
};

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
