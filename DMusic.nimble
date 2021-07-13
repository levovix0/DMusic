version       = "0.1.0"
author        = "DTeam"
description   = "Music player"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.4.4"
requires "fusion"

task codegen, "Generate additional C++ code":
  exec "cd src/"
  exec "nim c -r config.nim"
  when defined(windows):
    exec "rm config.exe"
  else:
    exec "rm config"
