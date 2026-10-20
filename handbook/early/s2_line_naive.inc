// 第 1 版：按参数 t 均匀采样（会出现“断点”）
void line_v1(int ax, int ay, int bx, int by, TGAImage &img, TGAColor color) {
    for (double t = 0.; t <= 1.; t += .02) {             // 只采 51 个点
        int x = std::round(ax + (bx - ax) * t);           // 线性插值：起点 + t × 位移
        int y = std::round(ay + (by - ay) * t);
        img.set(x, y, color);
    }
}
