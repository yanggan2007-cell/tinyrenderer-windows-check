#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <tuple>
#include <vector>
#include "tgaimage.h"
#include "mymodel.h"
#include "s3_triangle_cull.inc"
constexpr int width = 800, height = 800;
std::tuple<int, int> project(vec3 v) { return { (v.x + 1.) * width / 2, (v.y + 1.) * height / 2 }; }
int main(int argc, char **argv) {
    Model model(argv[1]);
    TGAImage framebuffer(width, height, TGAImage::RGB);
#include "s4_painter.inc"
    framebuffer.write_tga_file("painter.tga", true, false);
}
