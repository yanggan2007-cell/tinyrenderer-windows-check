#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <tuple>
#include "tgaimage.h"
#include "model.h"
#include "s3_triangle_cull.inc"
constexpr int width = 800, height = 800;
std::tuple<int, int> project(vec3 v) { return { int((v.x + 1.) * width / 2), int((v.y + 1.) * height / 2) }; }
int main(int argc, char **argv) {
    TGAImage small(128, 128, TGAImage::RGB);
    triangle(  7, 45, 35, 100, 45,  60, small, {0, 0, 255, 255});
    triangle(120, 35, 90,   5, 45, 110, small, {255, 255, 255, 255});
    triangle(115, 83, 80,  90, 85, 120, small, {0, 255, 0, 255});
    small.write_tga_file("tri_small.tga", true, false);
    Model model(argv[1]);
    TGAImage framebuffer(width, height, TGAImage::RGB);
    for (int i = 0; i < model.nfaces(); i++) {
        auto [ax, ay] = project(model.vert(i, 0));
        auto [bx, by] = project(model.vert(i, 1));
        auto [cx, cy] = project(model.vert(i, 2));
        TGAColor rnd;
        for (int c = 0; c < 3; c++) rnd[c] = std::rand() % 255;   // 随机颜色，方便看清每个三角形
        triangle(ax, ay, bx, by, cx, cy, framebuffer, rnd);
    }
    framebuffer.write_tga_file("framebuffer.tga", true, false);
}
