#ifndef SPHERE_H
#define SPHERE_H

#include "ray.h"
#include "hittable.h"

class sphere : public hittable {
    private:
        point3 center;
        float radius;
    
    public:
        //sphere constructor
        sphere(const point3& p, float r): center(p), radius(std::fmax(0.0, r)) {}
        
        bool hit(const ray& r, float rayT_min, float rayT_max, hit_record& record) const override {
            vec3 center_minus_point = center - r.origin();
            float a = dot(r.direction(), r.direction());
            float h = dot(r.direction(), center_minus_point);
            float c = dot(center_minus_point, center_minus_point) - (radius * radius);

            float discriminant = (h * h) - a * c;
            if (discriminant < 0.0) {
                return false;
            }
            
            float sqrt_disc = std::sqrt(discriminant);
            float root = (h - sqrt_disc) / a;
            if(root <= rayT_min || rayT_max <= root){
                root = (h + sqrt_disc) / a;
                if(root <= rayT_min || rayT_max <= root){
                    return false;
                }
            }
            
            record.t = root;
            record.p = r.at(root);
            vec3 normal = (record.p - center) / radius;
            record.set_face_normal(r, normal); //stores normal and if ray is from inside or outside inside record
            
            return true;
        }
        
        float hit_sphere(const point3 &center, float radius, const ray &r) {
        }
};

#endif