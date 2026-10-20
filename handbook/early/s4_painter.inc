    // 画家算法：先把三角形按“最远处的 z”从远到近排序，再依次画（后画的盖住先画的）
    std::vector<int> order(model.nfaces());
    for (int i = 0; i < model.nfaces(); i++) order[i] = i;              // order = {0, 1, 2, ...}
    auto minz = [&model](int f) {                                       // lambda：就地写的小函数
        return std::min({model.vert(f, 0).z, model.vert(f, 1).z, model.vert(f, 2).z});
    };
    std::sort(order.begin(), order.end(),
              [&](int a, int b) { return minz(a) < minz(b); });        // z 越小越远，排在前面
    for (int f : order) {                                               // 按排好的顺序画
        auto [ax, ay] = project(model.vert(f, 0));
        auto [bx, by] = project(model.vert(f, 1));
        auto [cx, cy] = project(model.vert(f, 2));
        TGAColor rnd;
        for (int c = 0; c < 3; c++) rnd[c] = std::rand() % 255;
        triangle(ax, ay, bx, by, cx, cy, framebuffer, rnd);
    }
