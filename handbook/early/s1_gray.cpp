#include <iostream>
#include "tgaimage.h"

int main() {
    TGAImage tex;                                          // 空图，等待读入
    if (!tex.read_tga_file("obj/african_head/african_head_diffuse.tga")) {
        // 失败最常见的原因：工作目录不对（相对路径是相对“运行时的当前目录”）
        std::cerr << "cannot read the texture: check the working directory\n";
        return 1;
    }
    TGAImage gray(tex.width(), tex.height(), TGAImage::GRAYSCALE);
    for (int y = 0; y < tex.height(); y++)
        for (int x = 0; x < tex.width(); x++) {
            TGAColor c = tex.get(x, y);                    // c[0]=B, c[1]=G, c[2]=R
            int lum = (c[2] * 299 + c[1] * 587 + c[0] * 114) / 1000; // 人眼对绿色最敏感
            gray.set(x, y, {static_cast<std::uint8_t>(lum)});  // 灰度图只用第 0 个字节
        }
    // 注意第二个参数是 false：读进来的图，内存第 0 行是“画面最上面一行”（见 1.2.7 末尾的提醒）
    gray.write_tga_file("gray.tga", false, false);
    return 0;
}
