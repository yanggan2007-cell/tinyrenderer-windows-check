// narrowing inside braces: aggregate initialization vs. assignment from a braced list
struct vec4 { double x, y, z, w; };
int main(int argc, char **) {
    int x = argc;
    vec4 a{x, 2., 3., 1.};     // aggregate initialization
    vec4 b;
    b = {x, 2., 3., 1.};       // assignment from a braced list
    return (int)(a.x + b.x);
}
