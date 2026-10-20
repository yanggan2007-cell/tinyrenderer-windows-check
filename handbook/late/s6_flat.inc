struct FlatShader : IShader {
    const Model &model;
    vec3 l;                 // 光的方向（已变换到相机坐标）
    vec3 tri[3];            // 三角形三个顶点（相机坐标）：vertex() 写，fragment() 读

    FlatShader(const vec3 light, const Model &m) : model(m) {
        l = normalized((ModelView * vec4{light.x, light.y, light.z, 0.}).xyz());  // 方向：w = 0
    }
    vec4 vertex(const int face, const int vert) {
        vec3 v = model.vert(face, vert);
        vec4 gl_Position = ModelView * vec4{v.x, v.y, v.z, 1.};                  // 点：w = 1
        tri[vert] = gl_Position.xyz();
        return Perspective * gl_Position;                                       // 返回裁剪坐标
    }
    std::pair<bool, TGAColor> fragment(const vec3 bar) const override {
        vec3 n = normalized(cross(tri[1] - tri[0], tri[2] - tri[0]));  // 整个三角形共用一个法线
        vec3 r = normalized(n * (n * l) * 2 - l);                     // 反射方向
        double ambient = .3;
        double diffuse = std::max(0., n * l);
        double specular = std::pow(std::max(r.z, 0.), 35);            // 相机在 +z 方向：r·(0,0,1) = r.z
        TGAColor c = {255, 255, 255, 255};
        for (int ch : {0, 1, 2})
            c[ch] = std::min(255., c[ch] * (ambient + .4 * diffuse + .9 * specular));
        return {false, c};                                            // false = 不丢弃这个片元
    }
};
