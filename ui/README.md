# 蓝色桌面 UI

界面组件与游戏模组生成逻辑分开维护。主窗口保留原来的布局、控件位置和容量计算，统一使用这里的组件。

## 设计参考

- [Material 3 组件规范](https://m3.material.io/components)
- [Ant Design 圆角与边框规范](https://ant.design/docs/react/customize-theme/)
- [Ant Design 蓝色与中性色应用](https://ant.design/docs/spec/colors/)
- [Tailwind 蓝色阶参考](https://v3.tailwindcss.com/docs/customizing-colors)
- [官方 Material Web 配色角色](https://material-web.dev/theming/color/)
- [官方按钮规范](https://material-web.dev/components/button/)
- [官方输入框规范](https://material-web.dev/components/text-field/)
- [官方动效曲线](https://github.com/material-components/material-web/blob/main/internal/motion/animation.ts)

`Theme.js` 集中管理蓝白配色、预览区深蓝灰配色及组件圆角。主色为 `#2563EB`，常规按钮和输入框圆角为 6px，边框用浅灰蓝。主操作使用实心按钮，次要操作使用浅蓝填充或描边按钮。保持文字对比度，悬浮与点击加深主按钮颜色。

按钮加入裁剪到圆角内部的点击波纹；勾选框有状态过渡，菜单与弹窗使用淡入和轻微缩放。输入框失去焦点后恢复正常边框，滚动条只有内容超出可视区域时才出现。

预览区右下方提供两种显示方式，默认使用预览模式。两种模式都以“初始免负重格数 + 驮骡技能累计”为统一额度，按格子顺序解锁；装备实体背包只增加可见容量，不改变技能额度。预览模式用红绿图形与呼吸效果标记实体背包提供的格子；游戏模式显示普通免负重与负重格子。问号位于模式按钮左侧，独立打开说明弹窗，支持中英文。当前选项用青色边条标记；顶部状态显示当前模式，圆点缓慢明暗循环。旧的分区解锁方案保存在 [算法归档](../docs/背包分区解锁算法归档.md)。

问号、语言、箭头、关闭、勾选、负重及像素背包等界面图形统一使用 `assets/*.svg`。`SvgIcon.qml` 按显示缩放渲染并由 Qt 原生组件着色；像素图形保持原有像素造型。点击波纹属于动效，继续由 Canvas 绘制。

## 本地交互预览

双击 `preview/start-preview.cmd` 打开预览。它读取当前 QML 源文件，可直接体验组件和动效。预览使用示例游戏路径，安装、删除和导出按钮不会修改游戏文件。

开发预览依赖本机 Qt 6.9.3。预览运行文件与截图在 `build/UiPreview`，不属于发布包。正式软件继续使用原来的容量生成、安装和清理逻辑。
