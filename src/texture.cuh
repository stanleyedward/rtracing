#ifndef TEXTURE_H
#define TEXTURE_H

#include "perlin.cuh"
#include "utils.cuh"

class texture {
public:
  __device__ virtual ~texture() = default;
  __device__ virtual color value(float u, float v, const point3 &p) const = 0;
};

class solid_color : public texture {
private:
  color albedo;

public:
  __device__ solid_color(const color &albedo) : albedo(albedo) {}
  __device__ solid_color(float red, float green, float blue)
      : solid_color(color(red, green, blue)) {}

  __device__ color value(float u, float v,
                         const point3 &position) const override {
    return albedo;
  }
};

class checker_texture : public texture {
private:
  texture *even;
  texture *odd;
  float inv_scale;

public:
  __device__ checker_texture(float scale, texture *even, texture *odd)
      : inv_scale(1.0 / scale), even(even), odd(odd) {}
  __device__ checker_texture(float scale, const color &c1, const color &c2)
      : checker_texture(scale, new solid_color(c1), new solid_color(c2)) {}
  __device__ color value(float u, float v,
                         const point3 &position) const override {
    int xInt = int(floorf(inv_scale * position.x()));
    int yInt = int(floorf(inv_scale * position.y()));
    int zInt = int(floorf(inv_scale * position.z()));

    bool isEven = (xInt + yInt + zInt) % 2 == 0;
    return isEven ? even->value(u, v, position) : odd->value(u, v, position);
  }
};

class image_texture : public texture {
private:
  unsigned char *data;
  int width;
  int height;
  color debug_color = color(0.f, 0.1f, 0.1f);

public:
  __device__ image_texture(unsigned char *data, unsigned int width,
                           unsigned int height)
      : data(data), width(width), height(height) {}
  __device__ image_texture(GPUImage img)
      : image_texture(img.data, img.width, img.height) {}

  __device__ color value(float u, float v,
                         const point3 &position) const override {
    if (height <= 0 || width <= 0)
      return debug_color;

    v = 1.f - v; // stb reads from top to bottom
    int i = min(int(u * width), int(width - 1));
    int j = min(int(v * height), int(height - 1));
    int idx = (j * width + i) * CH;
    float s = 1.f / 255.f;
    color pixel_color =
        color(s * data[idx], s * data[idx + 1], s * data[idx + 2]);
    return pixel_color;
  }
};

class noise_texture : public texture {
private:
  perlin noise;
  float scale;

public:
  __device__ noise_texture(curandState *state, float scale)
      : noise(state), scale(scale) {}
  __device__ color value(float u, float v,
                         const point3 &position) const override {
    return color(.5, .5, .5) *
           (1 + sinf(scale * position.z() + 10 * noise.turb(position, 7)));
  }
};

#endif