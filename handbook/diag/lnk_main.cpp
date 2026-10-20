// uses TGAImage but the build "forgets" tgaimage.cpp -> linker error
#include "../early/tgaimage.h"
int main() {
    TGAImage img(64, 64, TGAImage::RGB);
    img.set(1, 1, {255, 255, 255, 255});
    return img.write_tga_file("x.tga") ? 0 : 1;
}
