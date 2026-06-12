#ifndef TEXTURE_H
#define TEXTURE_H

#include "interval.cuh"
#include "rtw_stb.h"
#include "vec3.cuh"
#include "color.cuh"
#include "perlin.cuh"

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

  __device__ color value(float u, float v, const point3 &position) const override {
    return albedo;
  }
};

class checker_texture : public texture {
private:
  texture* even;
  texture* odd;
  float inv_scale;

public:
  __device__ checker_texture(float scale, texture* even,
                  texture* odd)
      : inv_scale(1.0 / scale), even(even), odd(odd) {}
  __device__ checker_texture(float scale, const color &c1, const color &c2)
      : checker_texture(scale, new solid_color(c1), new solid_color(c2)){}
  __device__ color value(float u, float v, const point3 &position) const override {
    int xInt = int(floorf(inv_scale * position.x()));
    int yInt = int(floorf(inv_scale * position.y()));
    int zInt = int(floorf(inv_scale * position.z()));

    bool isEven = (xInt + yInt + zInt) % 2 == 0;
    return isEven ? even->value(u, v, position) : odd->value(u, v, position);
  }
};

class image_texture : public texture { //figure how this will work.
private:
  rtw_image image;

public:
  __device__ image_texture(const char *filename) : image(filename) {}

  __device__ color value(float u, float v, const point3 &position) const override {
    // if not texture found, return cyan for debugging
    if (image.height() <= 0)
      return color(0, 1, 1);

    // clamp input tex coords to [0, 1] x [1, 0]
    u = interval(0, 1).clamp(u);
    v = 1.0 - interval(0, 1).clamp(v);

    int i = int(u * image.width());
    int j = int(v * image.height());
    const unsigned char *pixel = image.pixel_data(i, j);

    float color_scale = 1.0 / 255.0;
    color pixel_color = color(color_scale * pixel[0], color_scale * pixel[1],
                              color_scale * pixel[2]);
    return pixel_color;
  }
};

class noise_texture : public texture {
private:
  perlin noise;
  float scale;

public:
  noise_texture(float scale) : scale(scale) {}
  color value(float u, float v, const point3 &position) const override {
    return color(.5, .5, .5) *
           (1 + sinf(scale * position.z() + 10 * noise.turb(position, 7)));
  }
};

#endif