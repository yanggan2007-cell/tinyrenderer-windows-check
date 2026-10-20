cmake_minimum_required(VERSION 3.21)

# 单配置生成器（Ninja，VS 打开文件夹时默认用它）下，没指定构建类型就默认 Release
get_property(is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(NOT is_multi_config AND NOT (CMAKE_BUILD_TYPE OR DEFINED ENV{CMAKE_BUILD_TYPE}))
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Release default")
endif()

project(tinyrenderer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)                                      # cl.exe 和 clang-cl.exe 都会进入这个分支
  add_compile_options(/utf-8)                 # 源文件按 UTF-8 读：中文注释不再触发 C4819
  add_compile_definitions(_USE_MATH_DEFINES)  # 让 <cmath> 提供 M_PI（作者有几个 commit 用到）
else()
  add_compile_options(-Wall)
endif()

find_package(OpenMP COMPONENTS CXX)           # 找到就启用多线程，找不到也能编译

set(SOURCES main.cpp tgaimage.cpp)            # 以后新增 .cpp 文件，都要加在这里
add_executable(${PROJECT_NAME} ${SOURCES})
target_link_libraries(${PROJECT_NAME} PRIVATE $<$<BOOL:${OpenMP_CXX_FOUND}>:OpenMP::OpenMP_CXX>)
file(GENERATE OUTPUT .gitignore CONTENT "*")  # 让 Git 忽略整个构建目录
