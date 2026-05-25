#ifndef TEXTURE_H
#define TEXTURE_H

#include "vec3.h"
#include "color.h"

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

#endif