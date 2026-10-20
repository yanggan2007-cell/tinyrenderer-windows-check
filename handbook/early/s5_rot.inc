vec3 rot(vec3 v) {                       // 绕 y 轴转 30°
    const double a = std::numbers::pi / 6;   // C++20 的 π（需要 #include <numbers>）；MSVC 默认没有 M_PI
    const mat<3,3> Ry = {{{std::cos(a), 0, std::sin(a)}, {0, 1, 0}, {-std::sin(a), 0, std::cos(a)}}};
    return Ry * v;
}

vec3 persp(vec3 v) {                     // 中心投影：相机在 (0,0,c)，屏幕是 z=0 平面
    constexpr double c = 3.;
    return v / (1 - v.z / c);
}
