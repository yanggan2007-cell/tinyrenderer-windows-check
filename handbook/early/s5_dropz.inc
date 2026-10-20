// 调试工具：把 double 型 z-buffer 归一化到 0~255，存成灰度图（越亮越近）
void drop_zbuffer(const std::string &filename, const std::vector<double> &zbuffer,
                  int width, int height) {
    double minz = std::numeric_limits<double>::max(), maxz = -minz;
    for (double z : zbuffer) {                        // 先找出“真正画过的像素”里的最小/最大深度
        if (z < -100) continue;                       // 背景（初始值）跳过
        minz = std::min(minz, z);
        maxz = std::max(maxz, z);
    }
    TGAImage img(width, height, TGAImage::GRAYSCALE);
    for (int x = 0; x < width; x++)
        for (int y = 0; y < height; y++) {
            double z = zbuffer[x + y * width];
            if (z < -100) continue;
            auto g = static_cast<std::uint8_t>(255 * (z - minz) / (maxz - minz));
            img.set(x, y, {g});
        }
    img.write_tga_file(filename, true, false);
}
