struct DepthShader : IShader {             // 第 1 遍用：只要深度，颜色无所谓
    const Model &model;
    // 光照方向用不到；保留这个参数只是为了和其他着色器的构造函数长得一样
    DepthShader(const vec3, const Model &m) : model(m) {}
    vec4 vertex(const int face, const int vert) {
        vec3 v = model.vert(face, vert);
        return Perspective * ModelView * vec4{v.x, v.y, v.z, 1.};
    }
    std::pair<bool, TGAColor> fragment(const vec3) const override {
        return {false, {255, 255, 255, 255}};
    }
};

template <class Shader> void render_scene(int argc, char **argv, const vec3 light, TGAImage &target) {
    for (int m = 1; m < argc; m++) {
        Model model(argv[m]);
        Shader shader(light, model);              // Shader 是模板参数：可配不同着色器
        for (int f = 0; f < model.nfaces(); f++) {
            Triangle clip = { shader.vertex(f, 0), shader.vertex(f, 1), shader.vertex(f, 2) };
            rasterize(clip, shader, target);
        }
    }
}

int main(int argc, char **argv) {
    constexpr int width = 800, height = 800, shadow_size = 2048;
    constexpr vec3 light{1, 1, 1}, eye{-1, 0, 2}, center{0, 0, 0}, up{0, 1, 0};

    // ===== 第 1 遍：从相机看，正常渲染 =====
    lookat(eye, center, up);
    init_perspective(norm(eye - center));
    init_viewport(width / 16, height / 16, width * 7 / 8, height * 7 / 8);
    init_zbuffer(width, height);
    TGAImage framebuffer(width, height, TGAImage::RGB, {177, 195, 209, 255});
    render_scene<TangentShader>(argc, argv, light, framebuffer);
    std::vector<double> camera_z = zbuffer;                        // 存下相机视角的深度
    mat<4,4> M = (Viewport * Perspective * ModelView).invert();    // 相机屏幕 → 物体坐标

    // ===== 第 2 遍：把相机放到光源处，只记录深度 =====
    lookat(light, center, up);
    init_perspective(norm(eye - center));
    init_viewport(shadow_size / 16, shadow_size / 16, shadow_size * 7 / 8, shadow_size * 7 / 8);
    init_zbuffer(shadow_size, shadow_size);
    TGAImage trash(shadow_size, shadow_size, TGAImage::GRAYSCALE);
    render_scene<DepthShader>(argc, argv, light, trash);
    mat<4,4> N = Viewport * Perspective * ModelView;               // 物体坐标 → 光源屏幕

    // ===== 第 3 步：逐像素判断“光能不能看见这个点” =====
    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            double z = camera_z[x + y * width];
            if (z < -100) continue;                                // 背景
            vec4 p_obj = M * vec4{static_cast<double>(x), static_cast<double>(y), z, 1.};
            vec4 q = N * p_obj;
            vec3 p = q.xyz() / q.w;                                // 在光源屏幕上的位置和深度
            if (p.x < 0 || p.y < 0 || p.x >= shadow_size || p.y >= shadow_size) continue;
            bool lit = p.z > zbuffer[int(p.x) + int(p.y) * shadow_size] - .03;  // .03 = 偏移量(bias)
            if (lit) continue;
            TGAColor c = framebuffer.get(x, y);
            for (int ch : {0, 1, 2}) c[ch] = c[ch] * .5;           // 在阴影里：变暗一半
            framebuffer.set(x, y, c);
        }
    }
    framebuffer.write_tga_file("shadow.tga", true, false);
}
