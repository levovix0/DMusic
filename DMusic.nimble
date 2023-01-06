version       = "0.4"
author        = "DTeam"
description   = "Music player"
license       = "GPL"
srcDir        = "src"
bin           = @["dmusic"]
backend       = "cpp"

requires "nim >= 1.6.6"
requires "fusion"
requires "cligen"
requires "https://github.com/levovix0/impl"
requires "discord_rpc"
requires "filetype"
requires "localize >= 0.2"
requires "pixie"

mkdir "build"

when defined(nimdistros):
  import distros
  if detectOs(Manjaro) or detectOS(ArchLinux):
    foreignDep "qt5-base"
    foreignDep "qt5-declarative"
    foreignDep "qt5-graphicaleffects"
    foreignDep "qt5-multimedia"
    foreignDep "qt5-quickcontrols"
    foreignDep "qt5-quickcontrols2"
    foreignDep "taglib"


task translate, "generate translations":
  exec "lrelease translations/russian.ts -qm translations/russian.qm"


task installFlatpak, "build and install flatpak package":
  exec "flatpak-builder --user --install --force-clean build-flatpak org.DTeam.DMusic.yml"
