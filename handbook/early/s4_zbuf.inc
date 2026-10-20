// 和阶段 3 相比只多了三件事：顶点带 z、插值出 z、和 z-buffer 比较
void triangle(int ax, int ay, int az, int bx, int by, int bz, int cx, int cy, int cz,
              TGAImage &zbuffer, TGAImage &framebuffer, TGAColor color) {
    int bbminx = std::min({ax, bx, cx}), bbmaxx = std::max({ax, bx, cx});
    int bbminy = std::min({ay, by, cy}), bbmaxy = std::max({ay, by, cy});
    double total_area = signed_triangle_area(ax, ay, bx, by, cx, cy);
    if (total_area < 1) return;
    for (int x = bbminx; x <= bbmaxx; x++) {
        for (int y = bbminy; y <= bbmaxy; y++) {
            double alpha = signed_triangle_area(x, y, bx, by, cx, cy) / total_area;
            double beta  = signed_triangle_area(x, y, cx, cy, ax, ay) / total_area;
            double gamma = signed_triangle_area(x, y, ax, ay, bx, by) / total_area;
            if (alpha < 0 || beta < 0 || gamma < 0) continue;
            unsigned char z = static_cast<unsigned char>(alpha * az + beta * bz + gamma * cz);
            if (z <= zbuffer.get(x, y)[0]) continue;   // 这个像素上已经有更近的东西了 → 跳过
            zbuffer.set(x, y, {z});                     // 记录新的“最近深度”
            framebuffer.set(x, y, color);
        }
    }
}

// project 现在多返回一个 z：把 [-1,1] 映射到 [0,255]，数值越大越靠近观察者
std::tuple<int, int, int> project(vec3 v) {
    return { int((v.x + 1.) * width / 2), int((v.y + 1.) * height / 2), int((v.z + 1.) * 255. / 2) };
}
