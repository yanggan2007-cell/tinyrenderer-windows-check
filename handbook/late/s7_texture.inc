struct TextureShader : IShader {          // 漫反射贴图 + 高光贴图 + 全局空间法线贴图
    const Model &model;
    vec3 l;
    vec2 varying_uv[3];
    mat<4,4> MVit;                        // ModelView 的逆转置，提前算好

    TextureShader(const vec3 light, const Model &m) : model(m) {
        l = normalized((ModelView * vec4{light.x, light.y, light.z, 0.}).xyz());
        MVit = ModelView.invert_transpose();
    }
    vec4 vertex(const int face, const int vert) {
        varying_uv[vert] = model.uv(face, vert);
        vec3 v = model.vert(face, vert);
        return Perspective * ModelView * vec4{v.x, v.y, v.z, 1.};
    }
    std::pair<bool, TGAColor> fragment(const vec3 bar) const override {
        vec2 uv = varying_uv[0] * bar[0] + varying_uv[1] * bar[1] + varying_uv[2] * bar[2]; // 插值 UV
        vec3 nm = model.normal(uv);                                    // 物体坐标下的法线（来自贴图）
        vec3 n = normalized((MVit * vec4{nm.x, nm.y, nm.z, 0.}).xyz());
        vec3 r = normalized(n * (n * l) * 2 - l);
        double ambient = .4, diffuse = std::max(0., n * l);
        // 高光贴图：这个位置有多“光滑”，越亮高光越强
        double spec_weight = .5 + 2. * sample2D(model.specular(), uv)[0] / 255.;
        double specular = spec_weight * std::pow(std::max(r.z, 0.), 35);
        TGAColor c = sample2D(model.diffuse(), uv);                    // 底色来自漫反射贴图
        for (int ch : {0, 1, 2})
            c[ch] = std::min(255., c[ch] * (ambient + diffuse + specular));
        return {false, c};
    }
};
