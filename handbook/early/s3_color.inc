// 作业 1：三个顶点各有一种颜色，用重心坐标对每个通道做加权平均
void triangle_rgb(int ax, int ay, TGAColor ca, int bx, int by, TGAColor cb,
                  int cx, int cy, TGAColor cc, TGAImage &img) {
    int bbminx = std::min({ax, bx, cx}), bbmaxx = std::max({ax, bx, cx});
    int bbminy = std::min({ay, by, cy}), bbmaxy = std::max({ay, by, cy});
    double total_area = signed_triangle_area(ax, ay, bx, by, cx, cy);
    if (std::abs(total_area) < 1) return;                 // 这里不剔除背面，只防止除以 0
    for (int x = bbminx; x <= bbmaxx; x++)
        for (int y = bbminy; y <= bbmaxy; y++) {
            double alpha = signed_triangle_area(x, y, bx, by, cx, cy) / total_area;
            double beta  = signed_triangle_area(x, y, cx, cy, ax, ay) / total_area;
            double gamma = signed_triangle_area(x, y, ax, ay, bx, by) / total_area;
            if (alpha < 0 || beta < 0 || gamma < 0) continue;
            TGAColor c;                                   // 默认 bytespp = 4
            for (int ch = 0; ch < 3; ch++)                // B、G、R 三个通道分别插值
                c[ch] = static_cast<std::uint8_t>(alpha * ca[ch] + beta * cb[ch] + gamma * cc[ch]);
            c[3] = 255;
            img.set(x, y, c);
        }
}
