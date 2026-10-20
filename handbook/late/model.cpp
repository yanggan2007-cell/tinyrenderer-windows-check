#include <fstream>
#include <iostream>
#include <sstream>
#include "model.h"

Model::Model(const std::string &filename, const std::string &nm_suffix) {
    std::ifstream in(filename);
    std::string line;
    while (std::getline(in, line)) {
        std::istringstream iss(line);
        std::string tag;
        iss >> tag;
        if (tag == "v") {
            vec3 v; iss >> v.x >> v.y >> v.z; verts.push_back(v);
        } else if (tag == "vn") {
            vec3 n; iss >> n.x >> n.y >> n.z; norms.push_back(normalized(n));
        } else if (tag == "vt") {
            vec2 uv; iss >> uv.x >> uv.y;
            tex.push_back({uv.x, 1 - uv.y});        // 翻转 v：读入的贴图第 0 行在最上面（见正文）
        } else if (tag == "f") {
            int v, t, n; char slash;
            for (int k = 0; k < 3; k++) {           // 每个角形如 24/1/24
                iss >> v >> slash >> t >> slash >> n;
                facet_vrt.push_back(v - 1); facet_tex.push_back(t - 1); facet_nrm.push_back(n - 1);
            }
        }
    }
    // 控制台消息用英文：中文在 Windows 控制台里很容易显示成乱码（见 1.2.9）
    std::cerr << filename << ": " << verts.size() << " vertices, " << nfaces() << " triangles\n";
    auto load = [&filename](const std::string &suffix, TGAImage &img) {   // lambda：就地定义的小函数
        std::string texfile = filename.substr(0, filename.find_last_of('.')) + suffix;
        std::cerr << "  texture " << texfile << (img.read_tga_file(texfile) ? " ok\n" : " FAILED\n");
    };
    load("_diffuse.tga", diffusemap);
    load(nm_suffix, normalmap);         // 7B 用 "_nm.tga"（全局），7C 用 "_nm_tangent.tga"
    load("_spec.tga", specularmap);
}

vec3 Model::normal(const vec2 &uv) const {
    TGAColor c = normalmap.get(uv[0] * normalmap.width(), uv[1] * normalmap.height());
    // 注意 BGRA：c[2] 是 R → x，c[1] 是 G → y，c[0] 是 B → z；[0,255] → [-1,1]
    return normalized(vec3{c[2] * 2. / 255 - 1, c[1] * 2. / 255 - 1, c[0] * 2. / 255 - 1});
}
