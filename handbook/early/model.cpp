#include <fstream>
#include <sstream>
#include <iostream>
#include "model.h"

Model::Model(const std::string &filename) {
    std::ifstream in(filename);                       // 相当于 C 的 fopen(filename, "r")
    if (!in) { std::cerr << "cannot open " << filename << "\n"; return; }   // 控制台消息用英文，避免乱码
    std::string line;
    while (std::getline(in, line)) {                  // 每次读一整行，读到文件尾就停
        std::istringstream iss(line);                 // 把这一行当成一个“小输入流”
        std::string tag;
        iss >> tag;                                   // 取出行首的标记：v / vt / vn / f / # ...
        if (tag == "v") {                             // 顶点：v 0.608654 -0.568839 -0.416318
            vec3 v;
            iss >> v.x >> v.y >> v.z;
            verts.push_back(v);
        } else if (tag == "f") {                      // 面：f 24/1/24 25/2/25 26/3/26
            std::string corner;
            int cnt = 0;
            while (iss >> corner) {                   // corner 依次是 "24/1/24" 等
                int idx = std::stoi(corner);          // stoi 读到第一个 '/' 就停 → 24
                facet_vrt.push_back(idx - 1);         // OBJ 下标从 1 开始，C++ 从 0 开始！
                cnt++;
            }
            if (cnt != 3) std::cerr << "warning: a face is not a triangle\n";
        }                                             // 其他行（vt、vn、注释）暂时忽略
    }
    std::cerr << "vertices: " << nverts() << ", triangles: " << nfaces() << "\n";
}
