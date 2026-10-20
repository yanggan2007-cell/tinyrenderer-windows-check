#pragma once
#include <utility>
#include <vector>
#include "tgaimage.h"
#include "geometry.h"

void lookat(const vec3 eye, const vec3 center, const vec3 up);
void init_perspective(const double f);
void init_viewport(const int x, const int y, const int w, const int h);
void init_zbuffer(const int width, const int height);

struct IShader {                                   // “着色器接口”：渲染器只认识这个
    static TGAColor sample2D(const TGAImage &img, const vec2 &uv) {   // 最近邻采样
        return img.get(uv[0] * img.width(), uv[1] * img.height());
    }
    virtual std::pair<bool, TGAColor> fragment(const vec3 bar) const = 0;  // 纯虚函数：子类必须实现
    virtual ~IShader() = default;
};

typedef vec4 Triangle[3];                          // 一个三角形 = 3 个裁剪坐标下的顶点
void rasterize(const Triangle &clip, const IShader &shader, TGAImage &framebuffer);
