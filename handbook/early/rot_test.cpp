#include <cmath>
#include <numbers>
#include "geometry.h"
#include "s5_rot.inc"
int main(){ std::cout << rot(vec3{1,0,0}) << "\n" << persp(vec3{1,1,1}) << "\n" << persp(vec3{1,1,-1}) << "\n"; }
