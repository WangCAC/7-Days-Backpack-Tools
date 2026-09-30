[简体中文](README.md) | **English**

<div align="center">
  <img src="https://i.postimg.cc/FrXKnPs2/20260929154612327.webp?dl=1" alt="7 Days to Die Custom Backpack Capacity Tool logo" width="112">


  <h1>7 Days to Die Custom Backpack Capacity Tool</h1>

  <p>Set the backpack capacity and starting unencumbered slots to suit your playstyle, preview the result, and generate the mod in one click.</p>
  <p><strong>v1.0.5</strong> · Windows · Supports 7 Days to Die V3.3 and later</p>

  <p>
    <a href="#about-the-project">About</a> ·
    <a href="#features">Features</a> ·
    <a href="#quick-start">Quick Start</a> ·
    <a href="#building-from-source">Build from Source</a> ·
    <a href="#feedback-and-contributions">Feedback & Contributions</a>
  </p>
</div>

![Main application window](https://i.postimg.cc/cddrdkRr/20260929152945188.webp?dl=1)

## About the Project

Backpack mods are practically essential for many 7 Days to Die players. But after a game update, finding, downloading, and installing a suitable mod again takes time. Ready-made mods may not offer the capacity settings every player wants.

This tool brings configuration, preview, and installation together. Enter your desired backpack capacity and starting unencumbered slots, and it generates the corresponding backpack layout, interface configuration, and Pack Mule skill bonuses. You can install the mod directly into the game's `Mods` folder with one click or export a ZIP to share with friends.

## Features

- **Flexible configuration**: Set the total number of backpack slots and starting unencumbered slots. The tool calculates the grid layout, interface dimensions, and Pack Mule skill bonuses.
- **Live preview**: See the backpack grid update as you change the values, without repeatedly launching the game.
- **Find the game**: Automatically locate the game installation. Multiple game paths are saved in the drop-down list for future sessions.
- **One-click installation**: Select a game installation and write the generated mod to it with one click.
- **Export and share**: Export the mod, including its top-level mod folder, as a ZIP for backup or sharing.
- **Bilingual interface**: Simplified Chinese and English are available. The initial language follows your system language.

## Quick Start

### Get the App

The Windows single-file `.exe` is available from the project's [Releases page](https://github.com/WangCAC/7-Days-Backpack-Tools/releases).

### Configure and Install

1. Enter the **total backpack slots** and **starting unencumbered slots**. The preview on the left updates immediately. Starting unencumbered slots cannot exceed the total.

   ![Set backpack capacity and starting unencumbered slots](https://i.postimg.cc/x9jTwJQV/20260929153054067.webp?dl=1)

2. Click **Scan for game** to locate the game directory automatically. If it is not found, click **Browse…** to select it manually.

   ![Scan for or manually select the game](https://i.postimg.cc/7qLwBF1w/20260929153221147.webp?dl=1)

3. Click **Install mod**. The generated mod is placed in the selected game's `Mods` folder, which is created if necessary. You can also click **Mods folder** to open the installation location.

Want to share your configuration? Click **Export mod** to save a ZIP. The recipient can extract the mod folder from the ZIP into the `Mods` folder of their own game installation.

## Building from Source

The project uses **C++, Qt 6 (Qt Quick / QML), and CMake**. You need Qt 6.8 or later and a C++ compiler compatible with your Qt kit.

The simplest way is to open `CMakeLists.txt` in Qt Creator, choose a desktop Qt kit, and build the Release configuration. You can also run the following in a terminal with Qt configured:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=<Qt-installation-directory>
cmake --build build --config Release
```

The executable produced directly by the build still requires Qt runtime libraries. Use Qt's `windeployqt` to collect the dependencies before distribution.

## Feedback and Contributions

If you find a problem or have a feature suggestion, please open an [Issue](https://github.com/WangCAC/7-Days-Backpack-Tools/issues) with your game version, steps to reproduce, and what happened. Pull Requests are also welcome.

## License and Acknowledgments

Developed by [WangCAC](https://github.com/WangCAC) and licensed under the [MIT License](LICENSE). The README section structure was inspired by [Best-README-Template](https://github.com/othneildrew/Best-README-Template).
