version       = "0.1.0"
author        = "DTeam"
description   = "Music player"
license       = "MIT"

requires "nim >= 1.4.4"
requires "fusion"

task codegen, "Generate additional C++ code":
  exec "nim c -r config"
  exec "rm config"
