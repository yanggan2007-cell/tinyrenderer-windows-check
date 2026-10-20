#pragma once
#include <string>
#include <vector>
#include "geometry.h"

class Model {
    std::vector<vec3> verts;      // 所有顶点坐标，来自 "v x y z" 行
    std::vector<int>  facet_vrt;  // 每个三角形 3 个顶点下标（已转成从 0 开始），平铺存放
public:
    explicit Model(const std::string &filename);
    int nverts() const { return verts.size(); }
    int nfaces() const { return facet_vrt.size() / 3; }
    vec3 vert(int i) const { return verts[i]; }                       // 第 i 个顶点
    // 第 iface 个三角形的第 nth 个角（nth = 0, 1, 2）
    vec3 vert(int iface, int nth) const { return verts[facet_vrt[iface * 3 + nth]]; }
};
