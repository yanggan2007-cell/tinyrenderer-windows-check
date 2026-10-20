// 第 4 版（浮点误差版）：理解 Bresenham 的跳板
void line_float(int ax, int ay, int bx, int by, TGAImage &img, TGAColor color) {
    bool steep = std::abs(ax - bx) < std::abs(ay - by);   // |dy| > |dx|：线“太陡”
    if (steep) { std::swap(ax, ay); std::swap(bx, by); }  // 转置：把陡线变成缓线
    if (ax > bx) { std::swap(ax, bx); std::swap(ay, by); }// 保证从左往右画
    int y = ay;
    double error = 0;                                     // 真实 y 与当前整数 y 的差
    double slope = std::abs(by - ay) / double(bx - ax);   // 每走 1 格 x，真实 y 增加多少
    for (int x = ax; x <= bx; x++) {
        if (steep) img.set(y, x, color);                  // 画的时候再“转置回去”
        else       img.set(x, y, color);
        error += slope;
        if (error > .5) {                                 // 误差超过半格：y 该走一步了
            y += (by > ay ? 1 : -1);
            error -= 1.;
        }
    }
}
