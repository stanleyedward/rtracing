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

void cornell_box() {
  hittable_list world;

  auto red = make_shared<lambertian>(color(.65, .05, .05));
  auto white = make_shared<lambertian>(color(.73, .73, .73));
  auto green = make_shared<lambertian>(color(.12, .45, .15));
  auto light = make_shared<diffuse_light>(color(15, 15, 15));

  world.add(make_shared<quad>(point3(555, 0, 0), vec3(0, 555, 0),
                              vec3(0, 0, 555), green));
  world.add(make_shared<quad>(point3(0, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555),
                              red));
  world.add(make_shared<quad>(point3(343, 554, 332), vec3(-130, 0, 0),
                              vec3(0, 0, -105), light));
  world.add(make_shared<quad>(point3(0, 0, 0), vec3(555, 0, 0), vec3(0, 0, 555),
                              white));
  world.add(make_shared<quad>(point3(555, 555, 555), vec3(-555, 0, 0),
                              vec3(0, 0, -555), white));
  world.add(make_shared<quad>(point3(0, 0, 555), vec3(555, 0, 0),
                              vec3(0, 555, 0), white));

  shared_ptr<hittable> box1 =
      box(point3(0, 0, 0), point3(165, 330, 165), white);
  box1 = make_shared<rotate_y>(box1, 15);
  box1 = make_shared<translate>(box1, vec3(265, 0, 295));
  world.add(box1);

  shared_ptr<hittable> box2 =
      box(point3(0, 0, 0), point3(165, 165, 165), white);
  box2 = make_shared<rotate_y>(box2, -18);
  box2 = make_shared<translate>(box2, vec3(130, 0, 65));
  world.add(box2);
  camera cam;

  cam.aspect_ratio = 1.0;
  cam.image_width = 600;
  cam.samples_per_pixel = 200;
  cam.max_depth = 50;
  cam.background = color(0, 0, 0);
  cam.use_sky_gradient = false;

  cam.vFov = 40;
  cam.lookfrom = point3(278, 278, -800);
  cam.lookat = point3(278, 278, 0);
  cam.vUp = vec3(0, 1, 0);

  cam.defocus_angle = 0;

  std::chrono::time_point start = std::chrono::high_resolution_clock::now();
  cam.render(world);
  std::chrono::time_point end = std::chrono::high_resolution_clock::now();
  std::clog << "Total: "
            << std::chrono::duration_cast<std::chrono::milliseconds>(end -
                                                                     start)
                   .count()
            << "ms\n";
}
__global__ void create_cornell_box(hittable_list* world, camera* cam,curandState* state) {
    if(!(threadIdx.x == 0 && blockIdx.x == 0)) return;
    //init_world
    hittable** objects_list;
    unsigned int object_count = 0 ;

    //walls
    auto red = new lambertian(color(.65, .05, .05));
    auto white = new lambertian(color(.73, .73, .73));
    auto green = new lambertian(color(.12, .45, .15));
    auto light = new diffuse_light(color(15, 15, 15));
    
    objects_list[object_count++] = new quad(point3(555, 0, 0), vec3(0, 555, 0),
                                vec3(0, 0, 555), green));
    objects_list[object_count++] = new quad(point3(0, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555),
                                red));
    objects_list[object_count++] = new quad(point3(343, 554, 332), vec3(-130, 0, 0),
                                vec3(0, 0, -105), light));
    objects_list[object_count++] = new quad(point3(0, 0, 0), vec3(555, 0, 0), vec3(0, 0, 555),
                                white));
    objects_list[object_count++] = new quad(point3(555, 555, 555), vec3(-555, 0, 0),
                                vec3(0, 0, -555), white));
    objects_list[object_count++] = new quad(point3(0, 0, 555), vec3(555, 0, 0),
                                vec3(0, 555, 0), white));

    //boxes
    hittable_list* box1 = box(point3(0, 0, 0), point3(165, 330, 165), white);
    box1 = new rotate_y(box1, 15);
    box1 = new translate(box1, vec3(265, 0, 295));
    objects_list[object_count++] = box1;

    hittable_list* box2 = box(point3(0, 0, 0), point3(165, 165, 165), white);
    box2 = new rotate_y(box2, -18);
    box2 = new translate(box2, vec3(130, 0, 65));
    objects_list[object_count++] = box2;

    world->objects = objects_list;
    world->list_size = object_count;
    world->set_bbox();

    //init_camera
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

void cornell_box(hittable_list* world, camera* cam, curandState* state){
    cudaMalloc(&world, sizeof(hittable_list));
    cudaMalloc(&cam, sizeof(camera));
    create_cornell_box<<<1, 1>>>(d_world, d_camera, state);
    CHECK_CUDA(cudaDeviceSynchronize());
}

__global__ void render(float* output_image, hittable_list* world, camera* cam, curandState* render_states){
    unsigned int row = blockDim.y * blockIdx.y + threadIdx.y;
    unsigned int col = blockDim.x * blockIdx.x + threadIdx.x;
    if (row >= cam->image_height || col >= cam->image_width) return;
    vec3 pixel_color;
    unsigned int pixel_idx = row*image_width + col;
    curandState local_rand_state = render_states[row*image_width+col];
    pixel_color = cam->render(row, col, world, &local_rand_state);
    unsigned int output_idx = pixel_idx*3;
    #pragma unroll 3
    for(int i = 0; i < 3; i++)
        output_image[output_idx+i] = pixel_color[i]; 
    render_states[pixel_idx] = local_rand_state; //wrtb if need more frames
}

int main() {
  //get random states
  curandState* d_render_states;
  curandState* d_init_rand_state;
  cudaMalloc((void**) &d_render_states, output_image_size*sizeof(curandState));
  cudaMalloc((void**) &d_init_rand_state, 1*sizeof(curandState));
  rand_init_states<<<1, 1>>>(d_init_rand_state,seed);
  rand_render_states<<<numBlocksPerGrid, numThreadsPerBlock>>>(image_width, image_height, d_render_states, seed);
  CHECK_CUDA(cudaGetlastError());
  CHECK_CUDA(cudaDeviceSynchronize());
  
  hittable_list* d_world;
  camera* d_cam;
  //create the scene use the init state rand
  switch (scene_number) {
  case 1: cornell_box(d_world, d_cam, d_init_rand_state); break;
  default: cornell_box(d_world, d_cam, d_init_rand_state); break;
  }

  //after creating scene get the camer details and alloc space for the output image using image_height and image_width
  float* output_image;
  checkCudaErrors(cudaMallocManaged((void**) &output_image, output_image_size*CH*sizeof(float)));
  dim3 numThreadsPerBlock(TILE_SIZE, TILE_SIZE, 1);
  dim3 numBlocksPerGrid(CEIL_DIV(image_width, TILE_SIZE), CEIL_DIV(image_height, TILE_SIZE), 1);
  render<<<numBlocksPerGrid, numThreadsPerBlock>>>(output_image, d_world, d_cam, d_render_states);
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