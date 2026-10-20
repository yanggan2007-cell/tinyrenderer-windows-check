// save_png.cpp —— 整个项目里只有这一个 .cpp 写下面这个 #define
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
#include "tgaimage.h"

bool save_png(const TGAImage &img, const char *filename) {
    int w = img.width(), h = img.height();
    std::vector<unsigned char> rgb(w * h * 3);
    for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {
            TGAColor c = img.get(x, y);
            int row = h - 1 - y;                          // PNG 第 0 行在最上面；我们的 y=0 在最下面
            unsigned char *p = &rgb[(x + row * w) * 3];
            p[0] = c[2]; p[1] = c[1]; p[2] = c[0];        // BGR → RGB
            if (c.bytespp == 1) p[0] = p[1] = p[2] = c[0];  // 灰度图
        }
    return stbi_write_png(filename, w, h, 3, rgb.data(), w * 3) != 0;
}
