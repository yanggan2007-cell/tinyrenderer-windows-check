#include <cassert>
#include <cmath>
#include <iostream>
#include "geometry.h"

bool close(double a, double b) { return std::abs(a - b) < 1e-9; }

int main() {
    mat<3,3> A = {{{2, 0, 1}, {1, 3, 2}, {1, 1, 2}}};
    // 手算：2×(3×2−2×1) − 0 + 1×(1×1−3×1) = 6
    std::cout << "det(A) = " << A.det() << "\n";
    mat<3,3> I = A * A.invert();                                 // 应为单位矩阵
    for (int i = 0; i < 3; i++)
        for (int j = 0; j < 3; j++)
            assert(close(I[i][j], i == j ? 1. : 0.));
    vec3 x{1, 0, 0}, y{0, 1, 0};
    vec3 z = cross(x, y);
    assert(close(z.z, 1) && close(x * y, 0));
    std::cout << "A^-1 =\n" << A.invert() << "all tests passed\n";
}
