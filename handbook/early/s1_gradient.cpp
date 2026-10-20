#include "tgaimage.h"

int main() {
    constexpr int width = 256, height = 256;
    TGAImage img(width, height, TGAImage::RGB);           // 新建一张全黑的 RGB 图
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            TGAColor c = {0, 0, 0, 255};                  // 注意顺序：B, G, R, A
            c[2] = x;                                     // R 随 x 增大：越往右越红
            c[1] = y;                                     // G 随 y 增大：越往上越绿（原点在左下）
            img.set(x, y, c);
        }
    }
    for (int i = 0; i < width; i++) {                     // 画一圈白色边框，检验边界坐标
        img.set(i, 0, {255, 255, 255, 255});
        img.set(i, height - 1, {255, 255, 255, 255});
        img.set(0, i, {255, 255, 255, 255});
        img.set(width - 1, i, {255, 255, 255, 255});
    }
    img.set(1000, 1000, {255, 255, 255, 255});            // 越界：TGAImage 会“默默忽略”，不报错！
    img.write_tga_file("gradient.tga", true, false);  // 第 3 个参数 false = 不用 RLE 压缩
    return 0;
}
