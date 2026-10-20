# tinyrenderer-windows-check

《tinyrenderer 学习路径与执行手册（Windows 版）》的验证仓库：用 GitHub Actions 的 `windows-latest` 虚拟机
（Windows Server 2025 + Visual Studio 2026，MSVC 19.51 / clang-cl 22 / VS 自带的 CMake 4.3 和 Ninja），
把手册里的代码、命令和作者 [ssloy/tinyrenderer](https://github.com/ssloy/tinyrenderer) 的 45 个 commit 都实际编译、运行一遍。

## 目录

- `handbook/`：手册里的全部参考代码（`early/` 阶段 1–5，`late/` 阶段 6–7，`rt/` 附录 A 的光线追踪，
  `diag/` 各种报错和诊断的小程序，`student/` 推荐的 `CMakeLists.txt` 和 `CMakePresets.json`）。
- `ci/`：测试脚本。`run.ps1 -part <名字>` 选择要跑的部分：

| part | 内容 |
|---|---|
| `authors-msvc` / `authors-clang` / `authors-clang-noomp` / `authors-extra` | 作者的 commit 用 MSVC、clang-cl（开 / 关 OpenMP）编译运行（附录 F） |
| `flow` | 照抄 README、VS 默认设置、Debug / Release 计时、Bresenham 计时 |
| `handbook` | 手册全部代码、预设、编码、Sanitizer、PowerShell 5.1、Git 等检查 |
| `probe` / `arch` / `arch2` / `arch3` / `arch4` | 开发者 PowerShell 的 PATH 和 32/64 位环境、Restricted 执行策略下的完整命令行流程 |
| `ao-small` / `ao-full` | 作者的暴力环境光遮蔽（n = 100 约 7 分钟，n = 1000 约 65 分钟） |

## 结果

每次运行的结果（日志、CSV、渲染出的 PNG）推送到 `results-<运行编号>-<part>` 分支。
手册引用的数据来自 results-2 到 results-15 这些分支。

工作流只能手动触发（Actions → windows-check → Run workflow），因为完整跑一遍要用掉不少 Windows 运行时间。
