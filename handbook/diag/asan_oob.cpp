// reads one element past the end of a std::vector
#include <cstdio>
#include <vector>
int main(int argc, char **) {
    std::vector<int> v(3, 7);
    int i = 2 + argc;               // = 3 when run without arguments: out of range
    std::printf("v[%d] = %d\n", i, v[i]);
    return 0;
}
