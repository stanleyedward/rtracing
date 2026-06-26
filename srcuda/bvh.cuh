#ifndef BVH_H
#define BVH_H

#include "aabb.cuh"
#include "hittable.cuh"
#include "hittable_list.cuh"
#include <algorithm>

class bvh_node : public hittable {
private:
  hittable *left;
  hittable *right;
  aabb bbox;

  __device__ static bool box_compare(const hittable *a, const hittable *b,
                                     int axis_idx) {
    interval a_axis_interval = a->bounding_box().axis_interval(axis_idx);
    interval b_axis_interval = b->bounding_box().axis_interval(axis_idx);
    return a_axis_interval.min < b_axis_interval.min;
  }

  __device__ static bool box_compare_x(const hittable *a, const hittable *b) {
    return box_compare(a, b, 0);
  }
  __device__ static bool box_compare_y(const hittable *a, const hittable *b) {
    return box_compare(a, b, 1);
  }
  __device__ static bool box_compare_z(const hittable *a, const hittable *b) {
    return box_compare(a, b, 2);
  }

public:
  __device__ bvh_node(hittable_list list)
      : bvh_node(list.objects, 0, list.objects.size()) {}
  __device__ bvh_node(std::vector<hittable *> &objects, size_t start,
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

  __device__ bool hit(const ray &r, interval ray_t,
                      hit_record &rec) const override {
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

class bvh_node : public hittable {
private:
  hittable *left;
  hittable *right;
  aabb box;

public:
  __device__ bvh_node() : left(nullptr), right(nullptr) {}

  __device__ aabb bounding_box() const override { return bbox; }

  __device__ bool is_bvh() const override { return true; }

  __device__ bool hit(const ray &r, interval ray_t,
                      hit_record &rec) const override {
    hittable *stack[64];
    int ptr = 0;
    hittable *node = (hittable *)this;
    bool hit_anything = false;
    interval closest = ray_t;
    hit_record tmp;

    do {
      bvh_node *bvh = (bvh_node *)node;
      hittable *childL = bvh->left;
      hittable *childR = bvh->right;

      bool hitL = childL->bounding_box().hit(r, closest);
      bool hitR = childR->bounding_box().hit(r, closest);

      if (hitL && !childL->is_bvh()) {
        if (childL->hit(r, closest, tmp)) {
          hit_anything = true;
          closest.max = tmp.t;
          rec = tmp;
        }
        hitL = false;
      }

      if (hitR && !childR->is_bvh()) {
        if (childR->hit(r, closest, tmp)) {
          hit_anything = true;
          closest.max = tmp.t;
          rec = tmp;
        }
        hitR = false;
      }

      bool traverseL = hitL && childL->is_bvh();
      bool traverseR = hitR && childR->is_bvh();

      // DFS
      if (!traverseL && !traverseR) {
        if (ptr > 0) {
          node = stack[--ptr];
        } else
          break;
      } else {
        node = traveseL ? childL : childR;
        if (traveseL && traverseR)
          stack[ptr++] = childR;
      }
    } while (true);
    return hit_anything;
  }
};

__device__ static void sort_objects(hittable **objects, size_t start,
                                    size_t end, int axis) {
  // insertionsrort
  for (size_t i = start + 1; i < end; i++) {
    hittable *key = objects[i];
    float key_val = key->bounding_box().axis_interval(axis).min;
    int j = i - 1;
    while (j >= (int)start &&
           objects[j]->bounding_box().axis_interval(axis).min > key_val) {
      objects[j + 1] = objects[j];
      j--;
    }
    objects[j + 1] = key;
  }
}

__device__ hittable *create_bvh_tree(hittable **objects, size_t start,
                                     size_t end) {
  struct BVHWork {
    bvh_node *node;
    size_t start;
    size_t end;
  };

  BVHWork work_stack[128];
  int work_ptr = 0;

  bvh_node *root = new bvh_node();
  work_stack[work_ptr++] = {root, start, end};

  while (work_ptr > 0) {
    BVHWork current = work_stack[--work_ptr];
    bvh_node *node = current.node;
    size_t s = current.start;
    size_t e = current.end;
    size_t span = e - s;

    node->bbox = aabb::empty();
    for (size_t i = s; i < e; i++) {
      node->bbox = aabb(node->bbox, objects[i]->bounding_box());
    }

    if (span == 1) {
      node->left = objects[s];
      node->right = objects[s]; // dontwant to deal with nullptr
    } else if (span == 2) {
      node->left = objects[s];
      node->right = objects[s + 1];
    } else {
      int axis = node->bbox.longest_axis();
      sort_objects(objects, s, e, axis);
      size_t mid = s + span / 2;

      bvh_node *left_child = new bvh_node();
      bvh_node *right_chid = new bvh_node();
      node->left = left_child;
      node->right = right_child;

      work_stack[work_ptr++] = {right_child, mid, e};
      work_stack[work_ptr++] = {left_child, s, mid}; // left first in dfs
    }
  }
  return root;
}

#endif