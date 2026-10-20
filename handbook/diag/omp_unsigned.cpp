// OpenMP 2.0 (MSVC /openmp) requires a signed loop index
#include <cstdio>
#include <vector>
int main() {
    std::vector<double> v(1000, 1.);
    double sum = 0;
#pragma omp parallel for reduction(+:sum)
    for (size_t i = 0; i < v.size(); i++) sum += v[i];
    std::printf("%g\n", sum);
    return 0;
}
