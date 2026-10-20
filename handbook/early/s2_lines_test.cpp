#include <cmath>
#include <utility>
#include "tgaimage.h"
#include "s2_line_naive.inc"
#include "s2_line_float.inc"
#include "s2_line_int.inc"
int main() {
    constexpr TGAColor white={255,255,255,255}, green={0,255,0,255}, red={0,0,255,255}, blue={255,128,64,255}, yellow={0,200,255,255};
    TGAImage a(64,64,TGAImage::RGB), b(64,64,TGAImage::RGB);
    int ax=7, ay=3, bx=12, by=37, cx=62, cy=53;
    line_v1(ax,ay,bx,by,a,blue); line_v1(cx,cy,bx,by,a,green); line_v1(cx,cy,ax,ay,a,yellow); line_v1(ax,ay,cx,cy,a,red);
    line(ax,ay,bx,by,b,blue); line(cx,cy,bx,by,b,green); line(cx,cy,ax,ay,b,yellow); line(ax,ay,cx,cy,b,red);
    a.set(ax,ay,white); a.set(bx,by,white); a.set(cx,cy,white);
    b.set(ax,ay,white); b.set(bx,by,white); b.set(cx,cy,white);
    a.write_tga_file("lines_v1.tga", true, false); b.write_tga_file("lines_int.tga", true, false);
    // float vs int must agree
    TGAImage f(64,64,TGAImage::RGB), g(64,64,TGAImage::RGB);
    srand(1); int diff=0;
    for (int k=0;k<20000;k++){ int p[4]; for(int&q:p) q=rand()%64; TGAImage f1(64,64,1), g1(64,64,1);
        line_float(p[0],p[1],p[2],p[3],f1,{255}); line(p[0],p[1],p[2],p[3],g1,{255});
        for(int x=0;x<64;x++)for(int y=0;y<64;y++) if(f1.get(x,y)[0]!=g1.get(x,y)[0]) diff++; }
    printf("float-vs-int mismatched pixels: %d\n", diff);
}
