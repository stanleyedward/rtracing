### raytracing the next week but with cuda
it may be faster
note:
i have redundant imports because LSP was being annoying (help)

![junior](junior_scene.png)
  
- https://raytracing.github.io/books/RayTracingInOneWeekend.html
- https://developer.nvidia.com/blog/thinking-parallel-part-ii-tree-traversal-gpu/
1 curand for random states for each thread
1. Instead of shared_ptr<> we use nested pointers
2. freeing space because not using shared_ptr
3. Move to iterative approach over recursive because the stack is smaller