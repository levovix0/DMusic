<img alt="DMusic" align="left" width="110" src="https://github.com/levovix0/DMusic/blob/master/resources/app.svg">
<p>
  <h3>DMusic: open source Yandex.Music client / music player</h3>
  Uses <a href="https://github.com/MarshalX/yandex-music-api">unoffical Yandex.Music Api</a> translated from Python to Nim
</p>

![Screenshot](https://ia.wampi.ru/2021/09/23/85.png)  
<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/Version-0.4-x.svg?style=flat-square&logoColor=white&color=blue">
  <img alt="Stable" src="https://img.shields.io/badge/Stable-0.3-x.svg?style=flat-square&logoColor=white&color=blue">
  &nbsp;&nbsp;
  <img alt="Nim" src="https://img.shields.io/badge/Nim-Nim.svg?style=flat-square&logo=nim&logoColor=white&color=cb9e50">
  <img alt="QML" src="https://img.shields.io/badge/QML-QML.svg?style=flat-square&logo=qt&logoColor=white&color=3db069">
  &nbsp;&nbsp;
  <img alt="Code size" src="https://img.shields.io/github/languages/code-size/levovix0/DMusic?style=flat-square">
  <img alt="Total lines" src="https://img.shields.io/tokei/lines/github/levovix0/DMusic?color=purple&style=flat-square">
</p>

## Installation
* See [releases](https://github.com/levovix0/DMusic/releases)

* Flatpak (from source code)
  ```sh
  git clone https://github.com/levovix0/DMusic
  cd DMusic
  flatpak-builder --user --install --force-clean build-flatpak org.DTeam.DMusic.yml
  ```

* AUR (from source code), see [package](https://aur.archlinux.org/packages/dmusic)
  ```sh
  yay -S dmusic
  ```

* Compile for Linux (from source code)
  ```sh
  yay -S nim  # or use other way to install nim in your linux distribution
  git clone https://github.com/levovix0/DMusic
  cd DMusic
  nimble install  # result will be ~/.nimble/bin/dmusic
  ```
  add nimble dir to path (bash):
  ```bash
  echo "export PATH='\$PATH:~/.nimble/bin/dmusic'" >> ~/.bashrc
  ```
  add nimble dir to path (fish):
  ```fish
  fish_add_path ~/.nimble/bin/dmusic
  ```

<details><summary>Compile flags</summary><p>
  <code>-d:debugRequests</code> - print all requested urls to stdout
  
  <code>-d:yandexMusic_oneRequestAtOnce</code> - make only one request to yandex music at once

  <code>-d:debugYandexMusicBehaviour</code> - debug Yandex.Music service and api behaviour
</p></details>

## Dependencies (excluding nim libraries)
* Nim 1.6.6
* Qt 5.15 (declarative, imageformats, graphicaleffects, multimedia, quickcontrols, quickcontrols2, svg)
* TagLib
