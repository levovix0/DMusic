version       = "0.3"
author        = "DTeam"
description   = "Music player"
license       = "MIT"
srcDir        = "src"
bin           = @["dmusic"]
backend       = "cpp"

requires "nim >= 1.4.4"
requires "fusion"
requires "cligen"
requires "https://github.com/levovix0/impl"
requires "discord_rpc"
requires "parasound"
requires "filetype"

when defined(nimdistros):
  import distros
  if detectOs(Manjaro) or detectOS(ArchLinux):
    foreignDep "qt5-base"
    foreignDep "qt5-declarative"
    foreignDep "qt5-graphicaleffects"
    foreignDep "qt5-quickcontrols"
    foreignDep "qt5-quickcontrols2"
    foreignDep "python"
    foreignDep "taglib"

task codegen, "Generate additional C++ code":
  withDir "src":
    exec "nim c -r config.nim"
    when defined(windows):
      exec "rm config.exe"
    else:
      exec "rm config"
