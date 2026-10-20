// same out-of-range access, but the Debug CRT is told to print its report to stderr instead of a dialog box
#include <crtdbg.h>
#include <cstdio>
#include <vector>
int main(int argc, char **) {
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
    _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ERROR, _CRTDBG_FILE_STDERR);
    std::vector<int> v(3, 7);
    int i = 2 + argc;
    std::printf("v[%d] = %d\n", i, v[i]);
    return 0;
}
