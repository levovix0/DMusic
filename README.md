<img alt="DMusic" align="left" width="110" src="https://github.com/levovix0/DMusic/blob/master/resources/app.svg">
<p>
  <h3>DMusic: open source Yandex.Music client / music player</h3>
  Uses <a href="https://github.com/MarshalX/yandex-music-api">unoffical Yandex.Music Api</a> translated from Python to Nim
</p>

![Screenshot](https://ia.wampi.ru/2021/09/23/85.png)  
<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/Version-0.3-x.svg?style=flat-square&logoColor=white&color=blue">
  &nbsp;&nbsp;
  <img alt="Nim" src="https://img.shields.io/badge/Nim-Nim.svg?style=flat-square&logo=nim&logoColor=white&color=cb9e50">
  <img alt="QML" src="https://img.shields.io/badge/QML-QML.svg?style=flat-square&logo=qt&logoColor=white&color=3db069">
  &nbsp;&nbsp;
  <img alt="Code size" src="https://img.shields.io/github/languages/code-size/levovix0/DMusic?style=flat-square">
  <img alt="Total lines" src="https://img.shields.io/tokei/lines/github/levovix0/DMusic?color=purple&style=flat-square">
</p>

## Installation
See [releases](https://github.com/levovix0/DMusic/releases) or use nimble
```sh
nimble install https://github.com/levovix0/DMusic  # (linux-only)
```
<details><summary>Compile flags</summary><p>
  <code>-d:debugRequests</code> - print all requested urls to stdout
  
  <code>-d:yandexMusic_oneRequestAtOnce</code> - make only one request to yandex music at once (may fix infinity wait time from y.m. server)
  
  <code>-d:dmusic_useTaglib</code> - use taglib to parse id3v2 tags (added for compatibility, will be removed)
</p></details>

## Dependencies
* Nim 1.4.4
* Qt 6.2 (declarative, imageformats, graphicaleffects, multimedia, quickcontrols, quickcontrols2)
* TagLib
