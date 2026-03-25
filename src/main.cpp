#include "color.h"
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
      auto pixel_color =
          color(float(j) / (image_width - 1), 0, float(i) / (image_height - 1));
      write_color(std::cout, pixel_color);
    }
  }
  std::clog << "\rDone.                        \n";
}