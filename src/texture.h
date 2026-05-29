#ifndef TEXTURE_H
#define TEXTURE_H

#include "interval.h"
#include "rtw_stb.h"
#include "vec3.h"
#include "color.h"
#include "perlin.h"

class texture {
public:
  virtual ~texture() = default;
  virtual color value(float u, float v, const point3 &p) const = 0;
};

class solid_color : public texture {
private:
  color albedo;

public:
  solid_color(const color &albedo) : albedo(albedo) {}
  solid_color(float red, float green, float blue)
      : solid_color(color(red, green, blue)) {}

  color value(float u, float v, const point3 &position) const override {
    return albedo;
  }
};

class checker_texture : public texture {
private:
  shared_ptr<texture> even;
  shared_ptr<texture> odd;
  float inv_scale;

public:
  checker_texture(float scale, shared_ptr<texture> even,
                  shared_ptr<texture> odd)
      : inv_scale(1.0 / scale), even(even), odd(odd) {}
  checker_texture(float scale, const color &c1, const color &c2)
      : checker_texture(scale, make_shared<solid_color>(c1),
                        make_shared<solid_color>(c2)) {}
  color value(float u, float v, const point3 &position) const override {
    int xInt = int(std::floor(inv_scale * position.x()));
    int yInt = int(std::floor(inv_scale * position.y()));
    int zInt = int(std::floor(inv_scale * position.z()));

    bool isEven = (xInt + yInt + zInt) % 2 == 0;
    return isEven ? even->value(u, v, position) : odd->value(u, v, position);
  }
};

class image_texture : public texture {
private:
  rtw_image image;

public:
  image_texture(const char *filename) : image(filename) {}

  color value(float u, float v, const point3 &position) const override {
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

public:
  noise_texture() {}
  color value(float u, float v, const point3 &position) const override {
    return color(1, 1, 1) * noise.noise(position);
  }
};

#endif