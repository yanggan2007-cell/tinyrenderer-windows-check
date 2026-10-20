// the pattern used in tinyrenderer's rasterize(): structured bindings used as OpenMP loop bounds
#include <algorithm>
#include <cstdio>
int main() {
    double xs[3] = {1.5, 7.2, 3.3};
    auto [lo, hi] = std::minmax({xs[0], xs[1], xs[2]});
    int sum = 0;
#pragma omp parallel for reduction(+:sum)
    for (int x = std::max<int>(lo, 0); x <= std::min<int>(hi, 100); x++) sum += x;
    std::printf("%d\n", sum);
    return 0;
}
