mat<4,4> ModelView, Viewport, Perspective;          // 三个全局“状态矩阵”，模仿 OpenGL

void lookat(const vec3 eye, const vec3 center, const vec3 up) {
    vec3 n = normalized(eye - center);               // 相机的“后方”（相机看向 -n）
    vec3 l = normalized(cross(up, n));               // 相机的“右方”
    vec3 m = normalized(cross(n, l));                // 相机的“上方”（重新正交化后的 up）
    // ① 右边的矩阵先作用：平移，把 center 移到原点
    // ② 左边的矩阵后作用：三行分别是 l、m、n，用点积求出在相机坐标轴上的坐标
    ModelView = mat<4,4>{{{l.x,l.y,l.z,0}, {m.x,m.y,m.z,0}, {n.x,n.y,n.z,0}, {0,0,0,1}}}
              * mat<4,4>{{{1,0,0,-center.x}, {0,1,0,-center.y}, {0,0,1,-center.z}, {0,0,0,1}}};
}

void init_perspective(const double f) {             // 相机放在 (0,0,f)，看向原点
    Perspective = {{{1,0,0,0}, {0,1,0,0}, {0,0,1,0}, {0,0,-1/f,1}}};
}

// 把 [-1,1]² 映射到屏幕上的矩形 [x, x+w] × [y, y+h]
void init_viewport(const int x, const int y, const int w, const int h) {
    Viewport = {{{w/2., 0, 0, x+w/2.}, {0, h/2., 0, y+h/2.}, {0,0,1,0}, {0,0,0,1}}};
}
