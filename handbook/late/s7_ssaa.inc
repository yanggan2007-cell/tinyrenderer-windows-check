// 超采样抗锯齿 (SSAA)：先按 k 倍分辨率渲染，再把每 k×k 个像素取平均
TGAImage downsample(const TGAImage &big, int k) {
    TGAImage small(big.width() / k, big.height() / k, TGAImage::RGB);
    for (int x = 0; x < small.width(); x++)
        for (int y = 0; y < small.height(); y++) {
            int sum[3] = {0, 0, 0};
            for (int i = 0; i < k; i++)
                for (int j = 0; j < k; j++) {
                    TGAColor c = big.get(x * k + i, y * k + j);
                    for (int ch : {0, 1, 2}) sum[ch] += c[ch];
                }
            TGAColor avg = {0, 0, 0, 255};
            for (int ch : {0, 1, 2}) avg[ch] = sum[ch] / (k * k);
            small.set(x, y, avg);
        }
    return small;
}
