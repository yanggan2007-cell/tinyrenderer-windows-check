// what does an out-of-range double -> unsigned char conversion give? (undefined behaviour)
#include <cstdio>
#include <cstdlib>
int main(int argc, char **argv) {
    double vals[] = {255.0, 257.0, 280.0, 300.5, -1.0};
    for (double d : vals) {
        double x = d + (argc > 5 ? std::atof(argv[1]) : 0.0);   // defeat constant folding
        unsigned char c = static_cast<unsigned char>(x);
        std::printf("%.1f -> %d\n", x, (int)c);
    }
    return 0;
}
