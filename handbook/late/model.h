#pragma once
#include <string>
#include <vector>
#include "geometry.h"
#include "tgaimage.h"

class Model {
    std::vector<vec3> verts, norms;                 // "v" 和 "vn"
    std::vector<vec2> tex;                          // "vt"
    std::vector<int> facet_vrt, facet_tex, facet_nrm; // 每个角的三个下标：v/vt/vn
    TGAImage diffusemap, normalmap, specularmap;
public:
    explicit Model(const std::string &filename, const std::string &nm_suffix = "_nm_tangent.tga");
    int nfaces() const { return facet_vrt.size() / 3; }
    vec3 vert(int f, int k)   const { return verts[facet_vrt[f * 3 + k]]; }
    vec3 normal(int f, int k) const { return norms[facet_nrm[f * 3 + k]]; }
    vec2 uv(int f, int k)     const { return tex[facet_tex[f * 3 + k]]; }
    vec3 normal(const vec2 &uv) const;              // 从法线贴图读出法线
    const TGAImage &diffuse()  const { return diffusemap; }
    const TGAImage &specular() const { return specularmap; }
};
