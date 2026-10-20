#include <algorithm>
#include <cmath>
#include <cstdlib>
#include "our_gl.h"
#include "model.h"
extern mat<4,4> ModelView, Perspective;
#include "s6_random.inc"
int main(int argc, char **argv) {
    constexpr int width = 800, height = 800;
    constexpr vec3 light{1, 1, 1}, eye{-1, 0, 2}, center{0, 0, 0}, up{0, 1, 0};
    lookat(eye, center, up); init_perspective(norm(eye - center));
    init_viewport(width / 16, height / 16, width * 7 / 8, height * 7 / 8); init_zbuffer(width, height);
    TGAImage framebuffer(width, height, TGAImage::RGB);
    for (int m = 1; m < argc; m++) {
        Model model(argv[m]);
        RandomShader shader(light, model);
        for (int f = 0; f < model.nfaces(); f++) {
            for (int c : {0, 1, 2}) shader.color[c] = std::rand() % 255;
            Triangle clip = { shader.vertex(f, 0), shader.vertex(f, 1), shader.vertex(f, 2) };
            rasterize(clip, shader, framebuffer);
        }
    }
    framebuffer.write_tga_file("framebuffer.tga", true, false);
}
