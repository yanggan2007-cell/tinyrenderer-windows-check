// the starter TGAImage has no "initial colour" constructor parameter
#include "../early/tgaimage.h"
int main() { TGAImage img(64, 64, TGAImage::RGB, {177, 195, 209, 255}); return img.width() == 64 ? 0 : 1; }
