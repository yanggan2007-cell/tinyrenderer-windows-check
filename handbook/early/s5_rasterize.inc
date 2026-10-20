void rasterize(const vec4 clip[3], std::vector<double> &zbuffer,
               TGAImage &framebuffer, const TGAColor color) {
    vec4 ndc[3]    = { clip[0] / clip[0].w, clip[1] / clip[1].w, clip[2] / clip[2].w };  // 透视除法
    vec2 screen[3] = { (Viewport * ndc[0]).xy(), (Viewport * ndc[1]).xy(), (Viewport * ndc[2]).xy() };
    mat<3,3> ABC = {{ {screen[0].x, screen[0].y, 1.},
                      {screen[1].x, screen[1].y, 1.},
                      {screen[2].x, screen[2].y, 1.} }};
    if (ABC.det() < 1) return;                       // det = 2 × 有向面积：背面剔除
    mat<3,3> ABC_invT = ABC.invert_transpose();      // 每个三角形只求一次逆
    auto [bbminx, bbmaxx] = std::minmax({screen[0].x, screen[1].x, screen[2].x});
    auto [bbminy, bbmaxy] = std::minmax({screen[0].y, screen[1].y, screen[2].y});
    for (int x = std::max<int>(bbminx, 0);
             x <= std::min<int>(bbmaxx, framebuffer.width() - 1); x++) {
        for (int y = std::max<int>(bbminy, 0);
                 y <= std::min<int>(bbmaxy, framebuffer.height() - 1); y++) {
            vec3 bc = ABC_invT * vec3{static_cast<double>(x), static_cast<double>(y), 1.}; // 重心坐标
            if (bc.x < 0 || bc.y < 0 || bc.z < 0) continue;
            double z = bc * vec3{ndc[0].z, ndc[1].z, ndc[2].z};
            if (z <= zbuffer[x + y * framebuffer.width()]) continue;
            zbuffer[x + y * framebuffer.width()] = z;
            framebuffer.set(x, y, color);
        }
    }
}
