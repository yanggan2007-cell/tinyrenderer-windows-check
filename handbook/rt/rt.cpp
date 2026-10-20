// 迷你光线追踪：光线投射 + 硬阴影；比较“暴力求交”和“BVH 加速”
#include <vector>
#include <algorithm>
#include <chrono>
#include <limits>
#include <cstring>
#include "model2.h"                              // 阶段 6 写的模型读取器

struct Ray { vec3 o, d; };                       // 光线：起点 o + t × 方向 d
struct Tri { vec3 a, b, c; };
struct AABB {                                    // 轴对齐包围盒
    vec3 lo{ 1e30,  1e30,  1e30};
    vec3 hi{-1e30, -1e30, -1e30};
    void grow(const vec3 &p) {                   // 把点 p 包进盒子
        for (int i : {0, 1, 2}) { lo[i] = std::min(lo[i], p[i]); hi[i] = std::max(hi[i], p[i]); }
    }
};

// Möller–Trumbore：返回交点沿光线的距离 t；没有交点返回 -1
double intersect(const Ray &r, const Tri &t) {
    vec3 e1 = t.b - t.a, e2 = t.c - t.a;
    vec3 p = cross(r.d, e2);
    double det = e1 * p;
    if (std::abs(det) < 1e-12) return -1;        // 光线和三角形平行
    double inv = 1. / det;
    vec3 s = r.o - t.a;
    double u = (s * p) * inv;           if (u < 0 || u > 1)     return -1;
    vec3 q = cross(s, e1);
    double v = (r.d * q) * inv;         if (v < 0 || u + v > 1) return -1;   // (1-u-v, u, v) 就是重心坐标
    double dist = (e2 * q) * inv;
    return dist > 1e-6 ? dist : -1;
}

// slab 测试：光线在 tmax 之前是否穿过盒子
bool hit_box(const Ray &r, const vec3 &invd, const AABB &b, double tmax) {
    double t0 = 0, t1 = tmax;
    for (int i : {0, 1, 2}) {
        double ta = (b.lo[i] - r.o[i]) * invd[i];
        double tb = (b.hi[i] - r.o[i]) * invd[i];
        if (ta > tb) std::swap(ta, tb);
        t0 = std::max(t0, ta);                   // 最晚的“进入”
        t1 = std::min(t1, tb);                   // 最早的“离开”
        if (t0 > t1) return false;
    }
    return true;
}

bool naive_split = false;                        // [hide]
struct Node { AABB box; int left = -1, first = 0, count = 0; };   // count > 0 表示叶子

struct BVH {
    std::vector<Tri> &tris;
    std::vector<int> idx;                        // 三角形下标，建树时被重新排列
    std::vector<Node> nodes;
    BVH(std::vector<Tri> &t) : tris(t) {
        idx.resize(tris.size());
        for (int i = 0; i < (int)idx.size(); i++) idx[i] = i;
        nodes.push_back({});
        nodes[0].first = 0; nodes[0].count = tris.size();
        build(0);
    }
    vec3 centroid(int i) const { return (tris[i].a + tris[i].b + tris[i].c) / 3.; }
    void build(int n) {
        Node &node = nodes[n];
        for (int k = 0; k < node.count; k++) {
            const Tri &t = tris[idx[node.first + k]];
            node.box.grow(t.a); node.box.grow(t.b); node.box.grow(t.c);
        }
        if (node.count <= 2) return;             // 足够小：当叶子
        // 关键：用三角形“中心点”的包围盒来决定怎么分，而不是三角形本身的包围盒
        // （否则地板这种巨大三角形会让盒子缩不小，划分失败，见 A.5）
        AABB cb;
        for (int k = 0; k < node.count; k++) cb.grow(centroid(idx[node.first + k]));
        if (naive_split) cb = node.box;          // [hide]
        vec3 ext = cb.hi - cb.lo;                // 沿最长的轴，从中点一分为二
        int axis = ext.x > ext.y ? (ext.x > ext.z ? 0 : 2) : (ext.y > ext.z ? 1 : 2);
        double mid = cb.lo[axis] + ext[axis] / 2;
        int i = node.first, j = node.first + node.count - 1;   // 原地划分（类似快速排序）
        while (i <= j) {
            if (centroid(idx[i])[axis] < mid) i++;
            else std::swap(idx[i], idx[j--]);
        }
        int leftCount = i - node.first;
        if (leftCount == 0 || leftCount == node.count) return;  // 分不开：当叶子
        int l = nodes.size();
        nodes.push_back({}); nodes.push_back({}); // 注意：可能导致 vector 搬家，此后不能再用 node 这个引用
        nodes[l].first   = nodes[n].first; nodes[l].count   = leftCount;
        nodes[l+1].first = i;              nodes[l+1].count = nodes[n].count - leftCount;
        nodes[n].left = l; nodes[n].count = 0;
        build(l); build(l + 1);
    }
    void trace(const Ray &r, const vec3 &invd, int n, double &best, int &besti) const {
        const Node &node = nodes[n];
        if (!hit_box(r, invd, node.box, best)) return;     // 连盒子都没碰到：整棵子树跳过
        if (node.count > 0) {                              // 叶子：逐个测三角形
            for (int k = 0; k < node.count; k++) {
                int ti = idx[node.first + k];
                double d = intersect(r, tris[ti]);
                if (d > 0 && d < best) { best = d; besti = ti; }
            }
            return;
        }
        trace(r, invd, node.left, best, besti);
        trace(r, invd, node.left + 1, best, besti);
    }
};

int main(int argc, char **argv) {
    bool use_bvh = argc > 1 && !strcmp(argv[1], "bvh");
    if (argc > 1 && !strcmp(argv[1], "bvhnaive")) use_bvh = naive_split = true;  // [hide]
    std::vector<Tri> tris;
    for (const char *f : {"obj/diablo3_pose/diablo3_pose.obj", "obj/floor.obj"}) {
        Model m(f);
        for (int i = 0; i < m.nfaces(); i++)
            tris.push_back({m.vert(i, 0), m.vert(i, 1), m.vert(i, 2)});
    }
    const int W = 400, H = 400;
    vec3 eye{-1, 0, 2}, center{0, 0, 0}, up{0, 1, 0}, light = normalized(vec3{1, 1, 1});
    vec3 n = normalized(eye - center), l = normalized(cross(up, n)), m = normalized(cross(n, l));
    auto t0 = std::chrono::steady_clock::now();
    BVH *bvh = use_bvh ? new BVH(tris) : nullptr;
    auto t1 = std::chrono::steady_clock::now();
    auto closest = [&](const Ray &r, int &hit) {           // 找光线碰到的最近三角形
        double best = std::numeric_limits<double>::max(); hit = -1;
        if (bvh) {
            vec3 invd{1. / r.d.x, 1. / r.d.y, 1. / r.d.z};
            bvh->trace(r, invd, 0, best, hit);
        } else {                                            // 暴力：和所有三角形求交
            for (int i = 0; i < (int)tris.size(); i++) {
                double d = intersect(r, tris[i]);
                if (d > 0 && d < best) { best = d; hit = i; }
            }
        }
        return best;
    };
    TGAImage img(W, H, TGAImage::RGB, {177, 195, 209, 255});
    for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
        double sx = (x + .5) / W - .5, sy = (y + .5) / H - .5;  // 像素中心在虚拟屏幕上的位置
        Ray r{eye, normalized(l * sx * 1.2 + m * sy * 1.2 - n)};  // 相机看向 -n
        int hit; double d = closest(r, hit);
        if (hit < 0) continue;
        const Tri &t = tris[hit];
        vec3 nrm = normalized(cross(t.b - t.a, t.c - t.a));
        if (nrm * r.d > 0) nrm = nrm * -1.;                  // 让法线朝向相机
        vec3 p = r.o + r.d * d;                              // 交点
        int shadow_hit; closest({p + nrm * 1e-4, light}, shadow_hit);  // 阴影光线：射向光源
        double diffuse = shadow_hit < 0 ? std::max(0., nrm * light) : 0.;
        unsigned char c = std::min(255., 255 * (.25 + .75 * diffuse));
        img.set(x, y, {c, c, c, 255});
    }
    auto t2 = std::chrono::steady_clock::now();
    double build_ms  = std::chrono::duration<double, std::milli>(t1 - t0).count();
    double render_ms = std::chrono::duration<double, std::milli>(t2 - t1).count();
    std::cerr << (use_bvh ? "BVH" : "brute force") << ": " << tris.size() << " triangles, "
              << (bvh ? bvh->nodes.size() : 0) << " nodes, build " << build_ms << " ms, "
              << "render " << render_ms << " ms\n";
    img.write_tga_file(use_bvh ? "rt_bvh.tga" : "rt_brute.tga", true, false);
}
