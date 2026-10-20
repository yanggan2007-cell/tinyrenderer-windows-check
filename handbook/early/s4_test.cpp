#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <tuple>
#include "tgaimage.h"
#include "mymodel.h"
constexpr int width = 800, height = 800;
double signed_triangle_area(int ax, int ay, int bx, int by, int cx, int cy) {   // [hide]
    return .5 * ((bx - ax) * (cy - ay) - (cx - ax) * (by - ay)); }               // [hide]
#include "s4_zbuf.inc"   // [hide]
//@ // …… signed_triangle_area()、带 z 的 triangle() 和 project() 放在这里 ……
int main(int argc, char **argv) {
    Model model(argv[1]);
    TGAImage framebuffer(width, height, TGAImage::RGB);
    TGAImage zbuffer(width, height, TGAImage::GRAYSCALE);   // 全 0 = “无限远”
    for (int i = 0; i < model.nfaces(); i++) {
        auto [ax, ay, az] = project(model.vert(i, 0));
        auto [bx, by, bz] = project(model.vert(i, 1));
        auto [cx, cy, cz] = project(model.vert(i, 2));
        TGAColor rnd;
        for (int c = 0; c < 3; c++) rnd[c] = std::rand() % 255;
        triangle(ax, ay, az, bx, by, bz, cx, cy, cz, zbuffer, framebuffer, rnd);
    }
    framebuffer.write_tga_file("framebuffer.tga", true, false);
    zbuffer.write_tga_file("zbuffer.tga", true, false);
}
