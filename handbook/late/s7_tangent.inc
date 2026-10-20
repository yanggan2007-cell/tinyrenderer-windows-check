struct TangentShader : IShader {          // 切线空间法线贴图
    const Model &model;
    vec3 l;
    vec2 varying_uv[3];
    vec3 varying_nrm[3];                  // 顶点法线（相机坐标）
    vec3 tri[3];                          // 顶点位置（相机坐标）
    mat<4,4> MVit;                        // ModelView 的逆转置，只算一次

    TangentShader(const vec3 light, const Model &m) : model(m) {
        l = normalized((ModelView * vec4{light.x, light.y, light.z, 0.}).xyz());
        MVit = ModelView.invert_transpose();
    }
    vec4 vertex(const int face, const int vert) {
        varying_uv[vert] = model.uv(face, vert);
        vec3 n = model.normal(face, vert);
        varying_nrm[vert] = (MVit * vec4{n.x, n.y, n.z, 0.}).xyz();
        vec3 v = model.vert(face, vert);
        vec4 gl_Position = ModelView * vec4{v.x, v.y, v.z, 1.};
        tri[vert] = gl_Position.xyz();
        return Perspective * gl_Position;
    }
    std::pair<bool, TGAColor> fragment(const vec3 bar) const override {
        // ① 两条边 E（3D）与对应的 UV 差 U（2D）
        mat<2,3> E = {{ tri[1] - tri[0], tri[2] - tri[0] }};
        mat<2,2> U = {{ varying_uv[1] - varying_uv[0], varying_uv[2] - varying_uv[0] }};
        // ② 解方程 E = U · [t; b]  →  [t; b] = U⁻¹ · E
        mat<2,3> T = U.invert() * E;
        vec3 n = normalized(varying_nrm[0] * bar[0] +
                            varying_nrm[1] * bar[1] +
                            varying_nrm[2] * bar[2]);
        mat<3,3> D = {{ normalized(T[0]), normalized(T[1]), n }};     // 三行：t, b, n
        vec2 uv = varying_uv[0] * bar[0] + varying_uv[1] * bar[1] + varying_uv[2] * bar[2];
        // ③ 贴图里存的是 (x,y,z) = x·t + y·b + z·n，用 Dᵀ 把它换回相机坐标
        vec3 nn = normalized(D.transpose() * model.normal(uv));
        vec3 r = normalized(nn * (nn * l) * 2 - l);
        double ambient = .4, diffuse = std::max(0., nn * l);
        double spec_weight = .5 + 2. * sample2D(model.specular(), uv)[0] / 255.;
        double specular = spec_weight * std::pow(std::max(r.z, 0.), 35);
        TGAColor c = sample2D(model.diffuse(), uv);
        for (int ch : {0, 1, 2})
            c[ch] = std::min(255., c[ch] * (ambient + diffuse + specular));
        return {false, c};
    }
};
