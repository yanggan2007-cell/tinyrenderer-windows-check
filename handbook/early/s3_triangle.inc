// 有向面积：逆时针 (A→B→C) 为正，顺时针为负
double signed_triangle_area(int ax, int ay, int bx, int by, int cx, int cy) {
    return .5 * ((bx - ax) * (cy - ay) - (cx - ax) * (by - ay));   // 叉积的 z 分量 / 2
}

void triangle(int ax, int ay, int bx, int by, int cx, int cy, TGAImage &img, TGAColor color) {
    int bbminx = std::min({ax, bx, cx}), bbmaxx = std::max({ax, bx, cx}); // 包围盒
    int bbminy = std::min({ay, by, cy}), bbmaxy = std::max({ay, by, cy});
    double total_area = signed_triangle_area(ax, ay, bx, by, cx, cy);
    if (std::abs(total_area) < 1) return;  // 第 1 步：只防止“除以 0”（三个测试三角形恰好都是顺时针）
 // if (total_area < 1) return;            // 第 2 步渲染模型时换成这行：背面剔除
    for (int x = bbminx; x <= bbmaxx; x++) {
        for (int y = bbminy; y <= bbmaxy; y++) {
            double alpha = signed_triangle_area(x, y, bx, by, cx, cy) / total_area; // S(PBC)/S(ABC)
            double beta  = signed_triangle_area(x, y, cx, cy, ax, ay) / total_area; // S(PCA)/S(ABC)
            double gamma = signed_triangle_area(x, y, ax, ay, bx, by) / total_area; // S(PAB)/S(ABC)
            if (alpha < 0 || beta < 0 || gamma < 0) continue;  // 有负数 → 点在三角形外
            img.set(x, y, color);
        }
    }
}
