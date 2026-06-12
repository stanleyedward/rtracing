https://developer.nvidia.com/blog/thinking-parallel-part-ii-tree-traversal-gpu/
https://developer.nvidia.com/blog/accelerated-ray-tracing-cuda/

Things to keep in mind when porting to CUDA:
1. move funcs to `__host__` or `__device__`
2. curand for random states for each thread
3. Instead of shared_ptr<> we use nested pointers
4. freeing space because not using shared_ptr
5. Move to iterative approach over recursive because the stack is smaller

#### Later
6. BVH using the tree traversal blog? or use nested grid launches?