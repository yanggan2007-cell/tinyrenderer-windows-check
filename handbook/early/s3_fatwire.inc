// 作业 2：不调用 line() 画“粗线框”——只保留离某条边很近的像素
// 离边 BC 近 ⇔ alpha 接近 0；离 CA 近 ⇔ beta 接近 0；离 AB 近 ⇔ gamma 接近 0
            if (alpha < 0 || beta < 0 || gamma < 0) continue;
            if (std::min({alpha, beta, gamma}) > .1) continue;   // 三个都不小 → 在三角形“内部”，不画
            img.set(x, y, color);
