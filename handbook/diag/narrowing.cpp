#include <cstdint>
struct vec4 { double x, y, z, w; };
struct Color { std::uint8_t bgra[4]; };
int main(int argc, char **) {
    int x = argc;
    vec4 v{x, 2., 3., 1.};                 // int -> double inside braces
    double z = 1.5 * argc;
    Color c{{z, 255, 255, 255}};          // double -> uint8_t inside braces
    return (int)v.x + c.bgra[1];
}
