#ifndef PDF_H
#define PDF_H

#include "onb.cuh"
#include "vec3.cuh"
#include "hittable_list.cuh"

class pdf {
public:
  __device__ virtual ~pdf() {}

  __device__ virtual float value(const vec3 &direction,
                                 curandState *state) const = 0;
  __device__ virtual vec3 generate(curandState *state) const = 0;
};

class sphere_pdf : public pdf {
public:
  __device__ sphere_pdf() {}

  __device__ float value(const vec3 &direction,
                         curandState *state) const override {
    return 1 / (4 * pi);
  }

  __device__ vec3 generate(curandState *state) const override {
    return random_unit_vector(state);
  }
};

class cosine_pdf : public pdf {
private:
  onb uvw;

public:
  __device__ cosine_pdf() : uvw(vec3(0, 1, 0)) {}
  __device__ cosine_pdf(const vec3 &w) : uvw(w) {}
  __device__ float value(const vec3 &direction,
                         curandState *state) const override {
    float cos_theta = dot(unit_vector(direction), uvw.w());
    return cos_theta < 0 ? 0 : cos_theta / pi;
  }
  __device__ vec3 generate(curandState *state) const override {
    return uvw.transform(random_cosine_direction(state));
  }
};

class hittable_pdf : public pdf {
private:
  const hittable &objects;
  point3 origin;

public:
  __device__ hittable_pdf(const hittable &objects, const point3 &origin)
      : objects(objects), origin(origin) {}

  __device__ float value(const vec3 &direction,
                         curandState *state) const override {
    return objects.pdf_value(origin, direction, state);
  }
  __device__ vec3 generate(curandState *state) const override {
    return objects.random(origin, state);
  }
};

class mixture_pdf : public pdf {
private:
  pdf *p[2];

public:
  __device__ mixture_pdf(pdf *p0, pdf *p1) {
    p[0] = p0;
    p[1] = p1;
  }

  __device__ float value(const vec3 &direction,
                         curandState *state) const override {
    return (0.5 * p[0]->value(direction, state)) +
           (0.5f * p[1]->value(direction, state));
  }

  __device__ vec3 generate(curandState *state) const override {
    if (random_float(state) < 0.5)
      return p[0]->generate(state);
    else
      return p[1]->generate(state);
  }
};

enum PDFType { PDF_COSINE, PDF_SPHERE, PDF_NONE };

struct surface_pdf_holder {
  cosine_pdf cos_pdf;
  sphere_pdf sph_pdf;
  pdf *ptr;

  __device__ surface_pdf_holder(PDFType type, const vec3 &normal) {
    if (type == PDF_COSINE) {
      cos_pdf = cosine_pdf(normal);
      ptr = &cos_pdf;
    } else if (type == PDF_SPHERE) {
      sph_pdf = sphere_pdf();
      ptr = &sph_pdf;
    }
  }
};

#endif