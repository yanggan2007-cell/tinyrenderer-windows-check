#include <algorithm>
#include <cmath>
#include "our_gl.h"
#include "model2.h"
extern mat<4,4> ModelView, Perspective;
#include "s7_tangent.inc"
int main(int argc, char **argv) {
    constexpr int width = 800, height = 800;
    constexpr vec3 light{1, 1, 1}, eye{0, 0.3, 1.6}, center{0, -0.6, 0}, up{0, 1, 0};
    lookat(eye, center, up);
    init_perspective(norm(eye - center));
    init_viewport(width / 16, height / 16, width * 7 / 8, height * 7 / 8);
    init_zbuffer(width, height);
    TGAImage framebuffer(width, height, TGAImage::RGB, {177, 195, 209, 255});
    Model model("obj/floor.obj");
    TangentShader shader(light, model);
    for (int f = 0; f < model.nfaces(); f++) {
        Triangle clip = { shader.vertex(f, 0), shader.vertex(f, 1), shader.vertex(f, 2) };
        rasterize(clip, shader, framebuffer);
    }
    framebuffer.write_tga_file(argv[1], true, false);
}
