version       = "0.4"
author        = "DTeam"
description   = "Music player"
license       = "GPL"
srcDir        = "src"
bin           = @["dmusic"]
backend       = "cpp"

requires "nim >= 1.4.4"
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
