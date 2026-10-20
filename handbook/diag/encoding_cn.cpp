// 中文注释：这一行是 UTF-8（无 BOM）编码的中文
#include <cstdio>
int main() {
    const char *s = "顶点数";      // 3 个汉字
    const char *t = "读取失败了";  // 5 个汉字
    std::printf("%s %s\n", s, t);   // 打印中文
    return 0;
}
