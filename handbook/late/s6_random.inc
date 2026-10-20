struct RandomShader : IShader {           // 重构后的第一个着色器：效果和阶段 5 完全一样
    const Model &model;
    TGAColor color = {};                  // 由 main 在画每个三角形前设置

    RandomShader(const vec3, const Model &m) : model(m) {}   // 光照方向暂时用不到
    vec4 vertex(const int face, const int vert) {
        vec3 v = model.vert(face, vert);
        return Perspective * ModelView * vec4{v.x, v.y, v.z, 1.};
    }
    std::pair<bool, TGAColor> fragment(const vec3 bar) const override {
        return {false, color};            // 整个三角形一个颜色；false = 不丢弃
    }
};
