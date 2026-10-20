// M_PI is not standard C++: MSVC only defines it after _USE_MATH_DEFINES
#include <cmath>
#include <cstdio>
int main() { std::printf("%f\n", M_PI); }
