# 单文件启动器

发布 EXE 使用轻量的原生 Windows 启动器，内部包含压缩后的 Qt 程序及必要运行库。

- 首次启动将运行文件释放至 `%LOCALAPPDATA%\wangcac\BackpackTools\runtime\<版本号-包内容哈希>`。
- 同一版本后续启动直接运行缓存中的程序，不再反复解压。
- 发布包内容变化会生成不同的缓存目录，避免新旧运行库混用。
- 启动前检查运行文件是否齐全及大小；缺失时重新解压。
- 同时打开多个 EXE 时，使用互斥锁避免并发解压。
- 用户可以在工具关闭后删除该缓存目录；下次启动会自动重新生成。

`Launcher.cpp` 仅依赖 Windows API，以 Release 模式静态链接编译器运行库。
发布时生成 `runtime_manifest.h`（包内容标识和文件清单）及资源文件（程序图标、版本信息、压缩包）。这些中间文件放在 `build/LeanRelease`，不提交到仓库。

Qt 界面固定使用 `QtQuick.Controls.Basic` 作为自定义组件基类，不再部署可切换的多套控件主题。项目中的 QML 仍由 Qt 的编译缓存工具预编译，最终界面配色由 `ui/Theme.js` 控制。

本次发布手动编译和打包，不调用旧的 `build-single-file` 脚本。
