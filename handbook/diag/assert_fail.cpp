// what does a failing assert() look like in a Debug build?
#include <cassert>
#include <cstdio>
int main(int argc, char **) {
    int i = 2 + argc;          // 3 when run without arguments
    std::printf("checking index %d\n", i);
    std::fflush(stdout);
    assert(i >= 0 && i < 3);   // fails
    std::printf("not reached in Debug\n");
    return 0;
}
