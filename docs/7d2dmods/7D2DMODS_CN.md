**简体中文** | [English](7D2DMODS_EN.md)

# 七日杀自定义背包容量工具

**工具版本：**v1.4.0 · **游戏版本：**V3.3 及以上 · **平台：**Windows 64 位 · **作者：**WangCAC

## 工具简介

制作适合自己玩法的背包模组。设置人物背包容量、初始免负重格数、实体背包容量与布局，提前预览效果，再安装或导出自己的配置。

这是一款 Windows 端的模组生成工具。需要换配置时，修改设置并重新生成即可，减少反复寻找固定容量背包模组的麻烦。

![英文主界面](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/main.png)

*上图为示例：人物背包 200 格、初始免负重 50 格，大型 6 级实体背包额外增加 200 格。你可以使用适合自己游戏的数值。*

## 主要功能

- **自定义容量**：分别设置人物背包容量和初始免负重格数。
- **兼容实体背包**：设置最大实体背包容量，小型、中型和其他品质会以大型 6 级背包为参考一起调整。
- **布局可调**：每行选择 8～20 格，背包宽度可从原版调整到最宽；安装和导出的模组都会使用当前布局。
- **一键自适应**：自动推荐每行格子数和宽度，同步更新两个滑动条与预览，然后继续按自己的喜好调整。
- **实时预览**：选择背包类型、品质和驮骡等级，在进入游戏前查看可用格数与负重区域。
- **两种模式**：游戏模式模拟游戏中的显示效果；预览模式标记实体背包增加的格子。
- **容量详情**：集中比较驮骡技能加成，以及小型、中型、大型背包各品质增加的格数。
- **便捷安装与分享**：直接安装到游戏的 `Mods` 文件夹，或导出 ZIP 用于备份、手动安装与分享。
- **可选清理旧模组**：安装新配置时，可以清理本工具生成的其他背包模组。
- **清晰的双语界面**：提供简体中文和英文，搭配功能图标与一致的按钮布局。

### 容量与布局

英文界面的 **Max backpack slots（最大背包容量）** 指大型 6 级实体背包额外提供的格数，与 **Character slots（人物背包容量）** 分开设置。

![容量设置与布局滑动条](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/settings.png)

**原版宽度：**

![原版宽度预览](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/layout-vanilla-width.png)

**相同每行格子数，调整为最宽：**

![最宽预览](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/layout-widest.png)

### 预览装备与技能

**预览模式**标记实体背包的格子：

![带标记的预览](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/preview-mode.png)

**游戏模式**模拟游戏中的显示效果：

![游戏模式预览](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/game-mode.png)

### 比较容量

![驮骡技能详情](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/details.png)

![各类型与品质背包增加的格数](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/backpack-details.png)

## 安装与使用

1. 安装或更换生成的模组前，先关闭游戏。
2. 下载并运行单文件 EXE。如果选择 ZIP 便携版，解压整个文件夹后运行 `7DaysBackpackTools.exe`。
3. 设置人物背包容量、初始免负重格数和最大背包容量。初始免负重格数不能超过人物背包容量。
4. 调整每行格子数和背包宽度，或点击“自适应”。查看预览，并按需要选择装备与驮骡选项。
5. 点击“扫描游戏”。如果未找到，点击“手动选择”选中游戏目录中的 `7DaysToDie.exe`。
6. 点击“一键安装模组”。工具会将模组安装到游戏的 `Mods` 文件夹；文件夹不存在时会自动创建。
7. 如果需要清理旧配置，在确认弹窗中保留勾选“删除本软件产生的其他模组，以防冲突”，然后点击“确定”。
8. 启动游戏，使用新的配置。

![游戏选择与安装](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/installation.png)

![安装确认与可选清理](https://raw.githubusercontent.com/WangCAC/7-Days-Backpack-Tools/v1.4.0/assets/screenshots/en/install-confirmation.png)

### 手动安装或分享

点击“导出模组”保存 ZIP。将其中的模组文件夹解压到游戏的 `Mods` 文件夹，保留模组文件夹内部的 `ModInfo.xml` 和 `Config`。更换配置后重新启动游戏。

## 使用要求

- 运行工具需要 Windows 64 位系统。
- 游戏版本为七日杀 V3.3 及以上。
- 生成背包模组无需安装其他模组。
- 更改容量前先备份存档；缩小容量前，先整理超出新容量的物品。
- 其他修改背包容量、负重或同一物品栏界面的模组可能出现冲突，请使用一套兼容的背包配置。

**默认设置：**人物背包 48 格、初始免负重 32 格、最大实体背包容量 48 格，每行 8 格，原版宽度。

## 下载与反馈

- [下载 v1.4.0：单文件 EXE 或 ZIP 便携版](https://github.com/WangCAC/7-Days-Backpack-Tools/releases/tag/v1.4.0)
- [项目源码](https://github.com/WangCAC/7-Days-Backpack-Tools)
- [反馈问题或提出建议](https://github.com/WangCAC/7-Days-Backpack-Tools/issues)
- [英文更新日志](https://github.com/WangCAC/7-Days-Backpack-Tools/blob/v1.4.0/CHANGELOG_EN.md)

反馈时请附上游戏版本、工具版本、复现步骤和问题截图。

## 致谢

由 **WangCAC** 制作。感谢参与配置测试并反馈问题的玩家。按钮图标来自 [Lucide](https://lucide.dev/)。项目源码按 [MIT 许可证](https://github.com/WangCAC/7-Days-Backpack-Tools/blob/v1.4.0/LICENSE) 公开。
