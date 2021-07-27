version       = "0.3"
author        = "DTeam"
description   = "Music player"
license       = "MIT"
srcDir        = "src"
bin           = @["DMusic"]
backend       = "cpp"

requires "nim >= 1.4.4"
requires "fusion"

task codegen, "Generate additional C++ code":
  withDir "src":
    exec "nim c -r config.nim"
    when defined(windows):
      exec "rm config.exe"
    else:
      exec "rm config"
