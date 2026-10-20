// 第 5 版：全整数 Bresenham —— 把上一版所有量乘以 2*(bx-ax)
void line(int ax, int ay, int bx, int by, TGAImage &img, TGAColor color) {
    bool steep = std::abs(ax - bx) < std::abs(ay - by);
    if (steep) { std::swap(ax, ay); std::swap(bx, by); }
    if (ax > bx) { std::swap(ax, bx); std::swap(ay, by); }
    int y = ay;
    int ierror = 0;                                       // = error × 2dx
    for (int x = ax; x <= bx; x++) {
        if (steep) img.set(y, x, color);
        else       img.set(x, y, color);
        ierror += 2 * std::abs(by - ay);                  // slope × 2dx = 2dy
        if (ierror > bx - ax) {                           // 0.5 × 2dx = dx
            y += (by > ay ? 1 : -1);
            ierror -= 2 * (bx - ax);                      // 1 × 2dx
        }
    }
}
