// Verifies every worked numeric example of the handbook (run on Windows by CI).
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <utility>
#include <iostream>
#include "tgaimage.h"
#include "geometry.h"
#include "s2_line_float.inc"
#include "s2_line_int.inc"
#include "s5_gl.inc"

static double area(double ax, double ay, double bx, double by, double cx, double cy) {
    return .5 * ((bx - ax) * (cy - ay) - (cx - ax) * (by - ay));
}
static double shoelace(double ax, double ay, double bx, double by, double cx, double cy) {
    return .5 * ((by - ay) * (bx + ax) + (cy - by) * (cx + bx) + (ay - cy) * (ax + cx));
}
static void bary(double ax, double ay, double bx, double by, double cx, double cy, double px, double py) {
    double s = area(ax, ay, bx, by, cx, cy);
    std::printf("  P=(%g,%g): alpha=%g beta=%g gamma=%g\n", px, py,
                area(px, py, bx, by, cx, cy) / s, area(px, py, cx, cy, ax, ay) / s, area(px, py, ax, ay, bx, by) / s);
}

int main() {
    {   // line_v1 samples: how many times does "for (t = 0; t <= 1; t += .02)" run?
        int n = 0; double t = 0.;
        for (; t <= 1.; t += .02) n++;
        std::printf("[2.2.2] t += .02 loop runs %d times, final t = %.17g\n", n, t);
    }
    std::printf("[2.2.4] float vs integer Bresenham, 20000 random lines in 64x64 (srand(1), rand()%%64)\n");
    std::srand(1);
    int lines_diff = 0, max_pos = 0, total_pos = 0;
    for (int k = 0; k < 20000; k++) {
        int p[4];
        for (int &q : p) q = std::rand() % 64;
        TGAImage f(64, 64, TGAImage::GRAYSCALE), g(64, 64, TGAImage::GRAYSCALE);
        line_float(p[0], p[1], p[2], p[3], f, {255});
        line(p[0], p[1], p[2], p[3], g, {255});
        int d = 0;
        for (int x = 0; x < 64; x++) for (int y = 0; y < 64; y++) if (f.get(x, y)[0] != g.get(x, y)[0]) d++;
        if (d) { lines_diff++; max_pos = std::max(max_pos, d / 2); total_pos += d / 2; }
    }
    std::printf("  lines that differ: %d of 20000 (%.1f%%); differing positions per such line: max %d, total %d\n",
                lines_diff, 100. * lines_diff / 20000, max_pos, total_pos);
    {   // the tie of slope 5/42 at step 21
        double error = 0, slope = 5 / 42.;
        int ierror = 0;
        for (int x = 1; x <= 21; x++) {
            error += slope; ierror += 2 * 5;
            if (x == 21) std::printf("  slope 5/42, after 21 additions: float error = %.17g, integer ierror = %d (dx = 42)\n", error, ierror);
            if (error > .5) error -= 1.;
            if (ierror > 42) ierror -= 2 * 42;
        }
    }

    std::printf("[3.2.4] signed areas\n");
    std::printf("  (0,0),(4,0),(0,3): %g   swapped B,C: %g\n", area(0, 0, 4, 0, 0, 3), area(0, 0, 0, 3, 4, 0));
    std::printf("  (16,0),(0,12),(0,0): cross form %g, shoelace form %g; reversed: %g, %g\n",
                area(16, 0, 0, 12, 0, 0), shoelace(16, 0, 0, 12, 0, 0), area(0, 0, 0, 12, 16, 0), shoelace(0, 0, 0, 12, 16, 0));
    std::printf("[3.2.5] barycentric coordinates\n");
    bary(16, 0, 0, 12, 0, 0, 4, 3);
    bary(0, 0, 10, 0, 0, 10, 2, 3);

    std::printf("[4.2.4] 8-bit depth step = 2/255 = %.4f\n", 2 / 255.);
    std::printf("[4.3.6] inverses\n");
    mat<2,2> M2 = {{{2, 1}, {1, 1}}}, N2 = {{{3, 1}, {2, 1}}};
    std::cout << "  inv [[2,1],[1,1]] =\n" << M2.invert() << "  inv [[3,1],[2,1]] =\n" << N2.invert();
    mat<3,3> A = {{{2, 0, 1}, {1, 3, 2}, {1, 1, 2}}};
    std::cout << "  det A = " << A.det() << ", 6*inv(A) =\n" << A.invert() * 6.;

    std::printf("[5.2.5] homogeneous translation\n");
    mat<4,4> T = {{{1, 0, 0, 1}, {0, 1, 0, 2}, {0, 0, 1, 3}, {0, 0, 0, 1}}};
    std::cout << "  point:     " << T * vec4{4, 5, 6, 1} << "\n  direction: " << T * vec4{4, 5, 6, 0} << "\n";
    std::printf("[5.2.6] perspective matrix, c = 3\n");
    init_perspective(3);
    vec4 q = Perspective * vec4{1, 1, 1, 1};
    std::cout << "  P*(1,1,1,1) = " << q << "  -> divided by w: " << q / q.w << "\n";
    std::printf("  self-test c=2, point (1,0,1): x' = %g\n", 1 / (1 - 1 / 2.));
    std::printf("[5.2.7] viewport 800x800: x0=y0=%d, w=h=%d\n", 800 / 16, 800 * 7 / 8);
    init_viewport(800 / 16, 800 / 16, 800 * 7 / 8, 800 * 7 / 8);
    std::cout << "  NDC x=-1 -> " << (Viewport * vec4{-1, 0, 0, 1}).x << ", x=1 -> " << (Viewport * vec4{1, 0, 0, 1}).x
              << ", (0.5,-1) -> " << (Viewport * vec4{.5, -1, 0, 1}).x << "," << (Viewport * vec4{.5, -1, 0, 1}).y << "\n";
    std::printf("[5.2.8] lookat, eye=(-1,0,2), center=(0,0,0), up=(0,1,0)\n");
    vec3 eye{-1, 0, 2}, center{0, 0, 0}, up{0, 1, 0};
    vec3 n = normalized(eye - center), l = normalized(cross(up, n)), m = normalized(cross(n, l));
    std::cout << "  n = " << n << "\n  l = " << l << "\n  m = " << m << "\n  l x m = " << cross(l, m) << "\n";
    lookat(eye, center, up);
    std::cout << "  ModelView * eye = " << ModelView * vec4{eye.x, eye.y, eye.z, 1} << "  (sqrt(5) = " << std::sqrt(5.) << ")\n";
    lookat({0, 0, 3}, {0, 0, 0}, {0, 1, 0});
    std::cout << "  sanity check, eye=(0,0,3): ModelView =\n" << ModelView;

    std::printf("[6.2.4] Phong example\n");
    vec3 nn{0, 0, 1}, ll{0, .6, .8};
    vec3 r = nn * (2. * (nn * ll)) - ll;
    std::cout << "  n.l = " << nn * ll << ", r = " << r << ", r.v = " << r.z << "\n";
    for (int e : {1, 5, 10, 35}) std::printf("  0.8^%d = %.4f\n", e, std::pow(.8, e));
    std::printf("  cos 60 deg = %.3f\n", std::cos(std::acos(-1.) / 3));
    std::printf("[6.2.6] normal transform under scale x by 2\n");
    mat<2,2> S = {{{2, 0}, {0, 1}}};
    vec2 nrm{1, 1}, tan{1, -1};
    vec2 Mn = S * nrm, Mt = S * tan, Nn = S.invert_transpose() * nrm;
    std::cout << "  M*n = " << Mn << ", (M^-1)^T*n = " << Nn << ", tangent M*t = " << Mt
              << "\n  (M*n).(M*t) = " << Mn * Mt << ", ((M^-1)^T*n).(M*t) = " << Nn * Mt << "\n";

    std::printf("[7.2.1] uv (0.25,0.5) on 1024x1024 -> pixel (%g,%g)\n", .25 * 1024, .5 * 1024);
    std::printf("[7.3.2] colour 128 decodes to %.4f, 255 decodes to %.4f\n", 128 * 2 / 255. - 1, 255 * 2 / 255. - 1);
    std::printf("[7.4.2] tangent / bitangent example\n");
    mat<2,3> E = {{{2, 0, 0}, {0, 0, -1}}};
    mat<2,2> U = {{{.5, 0}, {0, .25}}};
    mat<2,3> TB = U.invert() * E;
    std::cout << "  U^-1 E =\n" << TB << "  t = " << normalized(TB[0]) << ", b = " << normalized(TB[1]) << "\n";
    std::printf("[7.5] perspective-correct interpolation, 1D example\n");
    double xa = -1, za = -1, xb = 1, zb = -3;
    double sa = xa / -za, sb = xb / -zb, smid = (sa + sb) / 2;
    double t = (smid * -za - xa) / ((xb - xa) - smid * (-(zb - za)));  // solve (xa + t(xb-xa)) / -(za + t(zb-za)) = smid
    std::printf("  A projects to %g, B to %g, screen midpoint %g, 3D parameter t = %g\n", sa, sb, smid, t);
    double wa = 1, wb = 3, a = .5 / wa, b = .5 / wb;
    std::printf("  corrected weights: (%g, %g)\n", a / (a + b), b / (a + b));
    std::printf("[7.6.4] depth buffer memory: 8000^2*8 = %.0f bytes (%.0f MiB); 2048^2*8 = %.0f bytes (%.0f MiB); ratio %.1f\n",
                8000. * 8000 * 8, 8000. * 8000 * 8 / 1048576, 2048. * 2048 * 8, 2048. * 2048 * 8 / 1048576, 8000. * 8000 / (2048. * 2048));
    std::printf("all checks printed\n");
}
