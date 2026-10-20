#include <cmath>
#include <utility>
#include <tuple>
#include "tgaimage.h"
#include "model.h"
#include "s2_line_int.inc"   // [hide]
//@ // …… 这里放上面的整数版 line() ……
constexpr int width = 800, height = 800;

// 正交投影 + 视口变换：丢掉 z，把 [-1,1] 映射到 [0,width] × [0,height]
std::tuple<int, int> project(vec3 v) {
    return { int((v.x + 1.) * width / 2), int((v.y + 1.) * height / 2) };   // 显式转成 int（截掉小数）
}

int main(int argc, char **argv) {
    if (argc != 2) { std::cerr << "usage: " << argv[0] << " obj/model.obj\n"; return 1; }
    Model model(argv[1]);
    TGAImage framebuffer(width, height, TGAImage::RGB);
    constexpr TGAColor red = {0, 0, 255, 255};
    for (int i = 0; i < model.nfaces(); i++) {
        auto [ax, ay] = project(model.vert(i, 0));    // 结构化绑定：一次拿到 x 和 y
        auto [bx, by] = project(model.vert(i, 1));
        auto [cx, cy] = project(model.vert(i, 2));
        line(ax, ay, bx, by, framebuffer, red);
        line(bx, by, cx, cy, framebuffer, red);
        line(cx, cy, ax, ay, framebuffer, red);
    }
    framebuffer.write_tga_file("framebuffer.tga", true, false);
    return 0;
}
