### raytracing the next week but with cuda
it may be faster <br>
note:i have redundant imports because LSP was being annoying (help)

![junior](junior_scene.png)
  
- https://raytracing.github.io/books/RayTracingInOneWeekend.html
- https://developer.nvidia.com/blog/thinking-parallel-part-ii-tree-traversal-gpu/

1. curandstate to get rand states for each thread
2. Instead of shared_ptr<> we use nested pointers
3. freeing space because not using shared_ptr
4. Move to iterative approach over recursive because the stack is smaller

#### optimization
- maybe remove virtual dispatch and use flat structs for mem locality and no vtable traversal (will take time)
- faster bvh construction with structs too