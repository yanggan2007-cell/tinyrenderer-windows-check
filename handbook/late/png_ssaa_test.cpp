#include <algorithm>
#include <cmath>
#include "our_gl.h"
#include "model.h"
extern mat<4,4> ModelView, Perspective;
#include "s7_savepng.inc"
#include "s7_ssaa.inc"
#include "s6_flat.inc"
TGAImage render(int width, int height, int argc, char **argv) {
    constexpr vec3 light{1, 1, 1}, eye{-1, 0, 2}, center{0, 0, 0}, up{0, 1, 0};
    lookat(eye, center, up); init_perspective(norm(eye - center));
    init_viewport(width / 16, height / 16, width * 7 / 8, height * 7 / 8); init_zbuffer(width, height);
    TGAImage fb(width, height, TGAImage::RGB, {177, 195, 209, 255});
    for (int m = 1; m < argc; m++) { Model model(argv[m]); FlatShader shader(light, model);
        for (int f = 0; f < model.nfaces(); f++) { Triangle clip = { shader.vertex(f, 0), shader.vertex(f, 1), shader.vertex(f, 2) }; rasterize(clip, shader, fb); } }
    return fb;
}
int main(int argc, char **argv) {
    TGAImage a = render(400, 400, argc, argv);
    TGAImage b = downsample(render(1600, 1600, argc, argv), 4);
    save_png(a, "noaa.png"); save_png(b, "ssaa4.png");
}
