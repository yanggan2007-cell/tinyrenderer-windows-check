#include <cmath>
#include <iostream>

struct Vec3 { double x = 0, y = 0, z = 0; };

// 运算符重载：本质就是“名字叫 operator+ 的普通函数”
Vec3 operator+(const Vec3 &a, const Vec3 &b) { return {a.x + b.x, a.y + b.y, a.z + b.z}; }
Vec3 operator-(const Vec3 &a, const Vec3 &b) { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
Vec3 operator*(const Vec3 &a, double k)      { return {a.x * k, a.y * k, a.z * k}; }      // 数乘
double operator*(const Vec3 &a, const Vec3 &b) { return a.x * b.x + a.y * b.y + a.z * b.z; } // 点积
Vec3 cross(const Vec3 &a, const Vec3 &b) {
    return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}
double norm(const Vec3 &v) { return std::sqrt(v * v); }
std::ostream &operator<<(std::ostream &out, const Vec3 &v) {   // 让 std::cout << v 能用
    return out << v.x << " " << v.y << " " << v.z;
}

int main() {
    Vec3 a{1, 0, 0}, b{0, 1, 0};
    std::cout << a + b << "\n";          // 编译器把它翻译成 operator+(a, b)  → 1 1 0
    std::cout << a * b << "\n";          // 点积 → 0（互相垂直）
    std::cout << cross(a, b) << "\n";    // x × y = z → 0 0 1
    std::cout << norm(a * 3.) << "\n";   // → 3
}
