#ifndef BVH_H
#define BVH_H

#include "aabb.cuh"
#include "hittable.cuh"
#include "hittable_list.cuh"
#include <algorithm>

class bvh_node : public hittable {
private:
  hittable* left;
  hittable* right;
  aabb bbox;

  __device__ static bool box_compare(const hittable* a,
                          const hittable* b, int axis_idx) {
    interval a_axis_interval = a->bounding_box().axis_interval(axis_idx);
    interval b_axis_interval = b->bounding_box().axis_interval(axis_idx);
    return a_axis_interval.min < b_axis_interval.min;
  }

  __device__ static bool box_compare_x(const hittable* a,
                            const hittable* b) {
    return box_compare(a, b, 0);
  }
  __device__ static bool box_compare_y(const hittable* a,
                            const hittable* b) {
    return box_compare(a, b, 1);
  }
  __device__ static bool box_compare_z(const hittable* a,
                            const hittable* b) {
    return box_compare(a, b, 2);
  }

public:
  __device__ bvh_node(hittable_list list)
      : bvh_node(list.objects, 0, list.objects.size()) {}
  __device__ bvh_node(std::vector<hittable*> &objects, size_t start,
           size_t end) {
    // int axis = random_int(0, 2);

    // getting the longest axis to split from; better than random.
    bbox = aabb::empty;
    for (size_t object_index = start; object_index < end; object_index++) {
      bbox = aabb(bbox, objects[object_index]->bounding_box());
    }
    int axis = bbox.longest_axis();

    auto comparator = (axis == 0)   ? box_compare_x
                      : (axis == 1) ? box_compare_y
                                    : box_compare_z;
    size_t object_span = end - start;
    if (object_span == 1) { // 1 object
      left = right = objects[start];
    } else if (object_span == 2) {
      left = objects[start];
      right = objects[start + 1];
    } else { // recursive
      std::sort(std::begin(objects) + start, std::begin(objects) + end,
                comparator);
      size_t mid = start + (object_span / 2);
      left = make_shared<bvh_node>(objects, start, mid);
      right = make_shared<bvh_node>(objects, mid, end);
    }
  }

  __device__ bool hit(const ray &r, interval ray_t, hit_record &rec) const override {
    if (!bbox.hit(r, ray_t)) {
      return false;
    }

    bool hit_left = left->hit(r, ray_t, rec);
    bool hit_right =
        right->hit(r, interval(ray_t.min, hit_left ? rec.t : ray_t.max), rec);
    return hit_left || hit_right;
  }

  __device__ aabb bounding_box() const override { return bbox; }
};

class bvh_node_gpu : public hittable {
  private:
  hittable* left;
  hittable* right;
  aabb box; 
  
  public:
    __device__ bvh_node_gpu(hittable_list objects) { 
      // TODO: tree creation code 
      } 

    __device__ bool hit(const ray& r, interval ray_t, hit_record& rec) const override {
      // TODO: tree traversal code
      hittable* stack[64];
      int ptr = 0;
      hittable* node = (hittable*) this;
      bool hit_anything = false;
      interval closest = ray_t;
      hit_record tmp;

      do{
        bvh_node* bvh = (bvh_node*)node;
        hittable* childL =  bvh->left;
        hittable* childR =  bvh->right;
        
        bool hitL = childL->bounding_box().hit(r, closest); //first check if hit childs bbox
        bool hitR = childR->bounding_box().hit(r, closest);

        //if hit child and child is not a bvh -> set hitL = false else if its not a child it hitL remains true.
        if (hitL && !childL->is_bvh()) {
          if (childL->hit(r, closest, tmp)) {
            hit_anything=true;
            closest.max = tmp.t;
            rec = tmp;
          }
          hitL = false;
        }

        if(hitR && !childR->is_bvh()){
          if(childR->hit(r, closest, tmp)) {
              hit_anything = true;
              closest.max = tmp.t;
              rec = tmp;
            {
            hitR = false;
        }

        bool traverseL = hitL && childL->is_bvh();
        bool traverseR = hitR && childR->is_bvh();

        if(!traverseL && !traverseR){
          if(ptr > 0){
            node = stack[--ptr]; 
          }
          else 
            break;
        }
        else{
          node = traveseL? childL : childR;
          if(traveseL && traverseR)
            stack[ptr++] = childR;
        }
      } while(true);
      return hit_anything;
    }
    __device__ aabb bounding_box() const override { return bbox; }
};


#endif