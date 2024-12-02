<img alt="DMusic" align="left" width="110" src="https://github.com/levovix0/DMusic/blob/master/resources/app.svg">
<p>
  <h3>DMusic: open source Yandex.Music client / music player</h3>
  Uses <a href="https://github.com/MarshalX/yandex-music-api">unoffical Yandex.Music Api</a> translated from Python to Nim
</p>

![Screenshot](https://i.imgur.com/zjiXeOh.png)  
<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/Version-0.4.1-x.svg?style=flat-square&logoColor=white&color=blue">
  &nbsp;&nbsp;
  <img alt="Nim" src="https://img.shields.io/badge/Nim-Nim.svg?style=flat-square&logo=nim&logoColor=white&color=cb9e50">
  <img alt="QML" src="https://img.shields.io/badge/QML-QML.svg?style=flat-square&logo=qt&logoColor=white&color=3db069">
  &nbsp;&nbsp;
  <img alt="Code size" src="https://img.shields.io/github/languages/code-size/levovix0/DMusic?style=flat-square">
</p>

## Installation
* See [releases](https://github.com/levovix0/DMusic/releases)

* ### Compile for Linux (from source code)

  Install [Nim](https://nim-lang.org)
  ```sh
  yay -S choosenim-bin
  choosenim stable
  ```
  
  Download and compile DMusic
  ```sh
  git clone https://github.com/levovix0/DMusic
  cd DMusic
  nimble install  # result will be ~/.nimble/bin/dmusic
  ```

  If you have Qt in non-standard location, specify `-d:qtInclude:path/to/qt/include`, `-d:qtLib:path/to/qt/lib` and `-d:qtBin:path/to/qt/bin` in `nimble install` BEFORE word "install"
  
  Add nimble dir to path (bash):
  ```bash
  echo "export PATH='\$PATH:~/.nimble/bin/dmusic'" >> ~/.bashrc
  ```
  
  Add nimble dir to path (fish):
  ```fish
  fish_add_path ~/.nimble/bin/dmusic
  ```

* ### AUR (from source code), see [package](https://aur.archlinux.org/packages/dmusic)
  ```sh
  yay -S dmusic
  ```

* ### Cross-compile to Windows (requires Linux)
  
  Install all from "Compile from source code" and download DMusic sources, then
  ```sh
  nimble buildWindows
  ```
  all sholud prombably myabe work automatically...
  
  result will be in `build-windows/DMusic` and `build-windows/DMusic.zip`

* ### (**NOT WORK NOW**) Flatpak (from source code)
  ```sh
  git clone https://github.com/levovix0/DMusic
  cd DMusic
  flatpak install org.kde.Sdk/x86_64/5.15-23.08
  flatpak install org.kde.Platform/x86_64/5.15-23.08
  flatpak-builder --user --install --force-clean build-flatpak org.DTeam.DMusic.yml
  ```

* ### (**DEPRECATED**) Compile for source code on Windows
  <details>
  see [wiki](https://github.com/levovix0/DMusic/wiki/Building-on-Windows)
  </details>

<details><summary>Compile flags</summary><p>
  <code>-d:debugRequests</code> - print all requested urls to stdout
  
  <code>-d:yandexMusic_oneRequestAtOnce</code> - make only one request to yandex music at once

  <code>-d:debugYandexMusicBehaviour</code> - debug Yandex.Music service and api behaviour
</p></details>

## Dependencies (excluding nim libraries)
* Nim >= 2.0.0
* Qt == 5.15.2 (declarative, imageformats, graphicaleffects, multimedia, quickcontrols, quickcontrols2, svg)
* TagLib

## Contributions
If you want to support this project, here is some tasks to do:
* See [issues](https://github.com/levovix0/DMusic/issues)
* Any bugfixes is always accepted, just describe somewhere what you fixed
* Refactoring (my code is bad, i know it)
  * if you doing big refactoring, first create issue to ask is all your changes needed, and if it is, refactor
* Add/fix translations (see `translations` directory, translations is made via [localize](https://github.com/levovix0/localize))
  * *note: currently, there is no much text to translate there, because most of UI is translated via qt translator, but i want to migrate to localize*
* Documentation
* Optimization
  * Force Qml to compile to C++ at compile time instead of be interpreted like js in runtime
* Add integrations to other music streaming platforms (for example, soundcloud, spotify, etc)
* Design (pin figma project to issue or something like it)
  * original design [document](https://www.figma.com/file/1AKzO6gCKcZDQuvVvdpJnu/DMusic?type=design&node-id=0%3A1&t=2griF3xoo4AxuTSx-1)
* Make better Qt wrapper (see [my wrapper](https://github.com/levovix0/DMusic/blob/master/src/gui/qt.nim))
* Create simpler way to build DMusic on Windows
* Port DMusic on other platforms
* Create any Qt infrastructure replacement (this includes: easy 2d gpu rendering, components, markup language/macros, audio output, etc)  
  *Qt is not made for Nim*  
  * note: i already made [windowing library](https://github.com/levovix0/siwin), and i am trying to make [audio output library](https://github.com/levovix0/siaud)
* Make cool site that adverts DMusic
* Make DMusic **legal**?

Just fork levovix0/DMusic to your account, make changes and submit a pull request.  
*Or if it requires new repository to be created, create it and add an "change dependency" issue.*
