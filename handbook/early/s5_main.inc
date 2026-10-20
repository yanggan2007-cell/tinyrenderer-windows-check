int main(int argc, char **argv) {
    constexpr int width = 800, height = 800;
    constexpr vec3 eye{-1, 0, 2}, center{0, 0, 0}, up{0, 1, 0};
    lookat(eye, center, up);
    init_perspective(norm(eye - center));
    init_viewport(width / 16, height / 16, width * 7 / 8, height * 7 / 8);
    TGAImage framebuffer(width, height, TGAImage::RGB);
    std::vector<double> zbuffer(width * height, -std::numeric_limits<double>::max());
    for (int m = 1; m < argc; m++) {                  // 可以一次传入多个 .obj
        Model model(argv[m]);
        for (int i = 0; i < model.nfaces(); i++) {
            vec4 clip[3];
            for (int d : {0, 1, 2}) {
                vec3 v = model.vert(i, d);
                clip[d] = Perspective * ModelView * vec4{v.x, v.y, v.z, 1.};   // 点：w = 1
            }
            TGAColor rnd;
            for (int c = 0; c < 3; c++) rnd[c] = std::rand() % 255;
            rasterize(clip, zbuffer, framebuffer, rnd);
        }
    }
    framebuffer.write_tga_file("framebuffer.tga", true, false);
}
