**简体中文** | [English](README_EN.md)

<div align="center">
  <img src="https://i.postimg.cc/FrXKnPs2/20260929154612327.webp?dl=1" alt="七日杀自定义背包容量工具 Logo" width="112">


  <h1>七日杀自定义背包容量工具</h1>

  <p>按自己的玩法设置背包容量与初始免负重格数，预览效果，然后一键生成模组。</p>
  <p><strong>v1.0.0</strong> · Windows · 适配《七日杀》V3.3 及以上版本</p>

  <p>
    <a href="#项目介绍">项目介绍</a> ·
    <a href="#功能亮点">功能亮点</a> ·
    <a href="#快速开始">快速开始</a> ·
    <a href="#从源码构建">从源码构建</a> ·
    <a href="#反馈与贡献">反馈与贡献</a>
  </p>
</div>

![软件主界面](https://i.postimg.cc/cddrdkRr/20260929152945188.webp?dl=1)

## 项目介绍

背包模组几乎是许多《七日杀》玩家的必备项，但游戏更新后重新寻找、下载和安装合适的模组很费时间；现成模组的容量配置也未必符合每个人的需求。

这个工具把配置、预览和安装放在一起：输入想要的背包容量与初始免负重格数，程序会生成对应的背包布局、界面配置和「驮骡」技能加成。你可以通过程序一键式直接安装到游戏的 `Mods` 文件夹，也可以导出 ZIP 与朋友分享。

## 功能亮点

- **自由配置**：设置背包总容量和初始免负重格数，自动计算网格布局、界面尺寸与「驮骡」技能加成。
- **实时预览**：修改数值时立即查看背包网格效果，无需反复启动游戏。
- **定位游戏**：可以自动定位游戏本体，多个游戏路径会保存在下拉框中，供下次启动使用。
- **一键安装**：在选中游戏的主目录后可以一键式写入生成的模组。
- **导出分享**：将模组连同顶层模组文件夹导出为 ZIP，方便备份或分享。
- **双语界面**：提供简体中文和英语，初次启动时根据系统语言选择。

## 快速开始

### 获取程序

Windows 单文件版 `.exe` 可在项目的 [Releases 页面](https://github.com/WangCAC/7-Days-Backpack-Tools/releases)查看；

### 配置并安装

1. 输入**背包总容量**和**初始免负重格数**。左侧会实时显示布局预览；免负重格数不能大于总容量。

   ![设置背包容量与免负重格数](https://i.postimg.cc/x9jTwJQV/20260929153054067.webp?dl=1)

2. 点击**扫描游戏**。程序会自动扫描出游戏主目录。如果没能找到，也可以点击**手动选择**来进行手动导入

   ![扫描或手动选择游戏](https://i.postimg.cc/7qLwBF1w/20260929153221147.webp?dl=1)

3. 点击**一键安装模组**。程序会把生成的模组放到所选游戏目录的 `Mods` 文件夹；如果该文件夹不存在，会自动创建。你也可以点击 **Mods 文件夹**按钮查看安装位置。

想把配置分享给别人？点击**导出模组**保存 ZIP。接收者将 ZIP 中的模组文件夹解压到自己游戏目录的 `Mods` 文件夹即可。

## 从源码构建

项目使用 **C++、Qt 6（Qt Quick / QML）和 CMake**。需要 Qt 6.8 或更新版本，以及与 Qt 套件匹配的 C++ 编译器。

最简单的方式是在 Qt Creator 中打开 `CMakeLists.txt`，选择桌面 Qt 套件并构建 Release 版本。也可以在已配置 Qt 环境的终端中执行：

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=<Qt安装目录>
cmake --build build --config Release
```

直接构建得到的程序仍需随附 Qt 运行库；分发时可使用 Qt 的 `windeployqt` 收集依赖。

## 反馈与贡献

发现问题或有功能建议，欢迎在 [Issues](https://github.com/WangCAC/7-Days-Backpack-Tools/issues) 中说明游戏版本、操作步骤和现象；也欢迎提交 Pull Request。

## 许可与致谢

本项目由 [WangCAC](https://github.com/WangCAC) 开发，采用 [MIT 许可证](LICENSE)。README 的章节组织参考了 [Best-README-Template](https://github.com/othneildrew/Best-README-Template)。
