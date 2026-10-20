#include <algorithm>
#include <cmath>
#include "tgaimage.h"
#include "s3_triangle.inc"
#include "s3_color.inc"
int main(){ TGAImage img(128,128,TGAImage::RGB);
 triangle_rgb(10,10,{0,0,255,255}, 118,30,{0,255,0,255}, 50,118,{255,0,0,255}, img);
 img.write_tga_file("tri_rgb.tga", true, false); }
