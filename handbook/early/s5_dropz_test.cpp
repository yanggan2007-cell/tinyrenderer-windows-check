#include <algorithm>
#include <limits>
#include <string>
#include <vector>
#include "tgaimage.h"
#include "s5_dropz.inc"
int main(){ std::vector<double> z(16, -1000.); z[5]=0.2; z[6]=0.7; drop_zbuffer("dz.tga", z, 4, 4); }
