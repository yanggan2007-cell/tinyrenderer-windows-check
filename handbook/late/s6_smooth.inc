struct SmoothShader : IShader {
    const Model &model;
    vec3 l;
    vec3 varying_nrm[3];    // “varying”：每个顶点一个，光栅化时被插值
    mat<4,4> MVit;          // ModelView 的逆转置：4×4 求逆很贵，只在构造时算一次

    SmoothShader(const vec3 light, const Model &m) : model(m) {
        l = normalized((ModelView * vec4{light.x, light.y, light.z, 0.}).xyz());
        MVit = ModelView.invert_transpose();
    }
    vec4 vertex(const int face, const int vert) {
        vec3 n = model.normal(face, vert);                                         // 来自 "vn"
        varying_nrm[vert] = (MVit * vec4{n.x, n.y, n.z, 0.}).xyz();   // 法线用逆转置变换！
        vec3 v = model.vert(face, vert);
        return Perspective * ModelView * vec4{v.x, v.y, v.z, 1.};
    }
    std::pair<bool, TGAColor> fragment(const vec3 bar) const override {
        vec3 n = normalized(varying_nrm[0] * bar[0] +
                            varying_nrm[1] * bar[1] +
                            varying_nrm[2] * bar[2]);
        vec3 r = normalized(n * (n * l) * 2 - l);
        double ambient = .3, diffuse = std::max(0., n * l), specular = std::pow(std::max(r.z, 0.), 35);
        TGAColor c = {255, 255, 255, 255};
        for (int ch : {0, 1, 2})
            c[ch] = std::min(255., c[ch] * (ambient + .4 * diffuse + .9 * specular));
        return {false, c};
    }
};
