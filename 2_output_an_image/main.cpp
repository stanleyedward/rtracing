#include <iostream>

int main() {

  // image config
  std::string color_code = "P3";
  int image_height = 256;
  int image_width = 512;

  std::cout << color_code << "\n"
            << image_width << " " << image_height << "\n255\n";

  // render the image
  for (int i = 0; i < image_height; i++) {
    std::clog << "\rScanlines remaining: " << (image_height - i) << " "
              << std::flush;
    for (int j = 0; j < image_width; j++) {
      // convert to [0,1] -> float
      auto r = float(i) / (image_width - 1);
      auto g = 0.0;
      auto b = float(j) / (image_height - 1);

      // convert to [0, 255]
      int ir = int(r * 255.999);
      int ig = int(g * 255.999);
      int ib = int(b * 255.999);

      std::cout << ir << " " << ig << " " << ib << "\n";
    }
  }
  std::clog << "\rDone.                        \n";
}