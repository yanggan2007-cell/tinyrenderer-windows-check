#include <algorithm>
#include <cmath>
#include "tgaimage.h"
double signed_triangle_area(int ax, int ay, int bx, int by, int cx, int cy) {
    return .5 * ((bx - ax) * (cy - ay) - (cx - ax) * (by - ay)); }
void triangle(int ax, int ay, int bx, int by, int cx, int cy, TGAImage &img, TGAColor color) {
    int bbminx = std::min({ax, bx, cx}), bbmaxx = std::max({ax, bx, cx});
    int bbminy = std::min({ay, by, cy}), bbmaxy = std::max({ay, by, cy});
    double total_area = signed_triangle_area(ax, ay, bx, by, cx, cy);
    if (std::abs(total_area) < 1) return;
    for (int x = bbminx; x <= bbmaxx; x++)
        for (int y = bbminy; y <= bbmaxy; y++) {
            double alpha = signed_triangle_area(x, y, bx, by, cx, cy) / total_area;
            double beta  = signed_triangle_area(x, y, cx, cy, ax, ay) / total_area;
            double gamma = signed_triangle_area(x, y, ax, ay, bx, by) / total_area;
#include "s3_fatwire.inc"
        }
}
int main(){ TGAImage img(128,128,TGAImage::RGB);
 triangle(  7, 45, 35, 100, 45,  60, img, {0, 0, 255, 255});
 triangle(120, 35, 90,   5, 45, 110, img, {255, 255, 255, 255});
 triangle(115, 83, 80,  90, 85, 120, img, {0, 255, 0, 255});
 img.write_tga_file("fat.tga", true, false); }
