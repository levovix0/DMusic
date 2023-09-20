version       = "0.4.1"
author        = "DTeam"
description   = "Music player from streaming services like Yandex Music"
license       = "MIT"
srcDir        = "src"
bin           = @["dmusic"]
backend       = "cpp"  # taglib requires c++
# backend       = "c"

requires "nim >= 2.0"
requires "fusion"  # to write macros using pattern matching
requires "cligen"  # to parse command line arguments
requires "https://github.com/levovix0/impl"  # used in taglib wrapper # todo: remove
requires "filetype"  # to detect file type?
requires "localize >= 0.3.2"  # to translate app into many languages
requires "checksums"  # ???
requires "sigui >= 0.1"  # to make gui
requires "imageman"  # to decode png
requires "bumpy"  # for rects
requires "opengl"  # for graphics
requires "shady"  # for writing shaders in Nim istead of GLSL
requires "https://github.com/beef331/miniaudio"  # for audio output # todo: replace with siaud
requires "tinyfiledialogs"  # for file dialogs


# note: build is broken
# note: not completely, but broken
mkdir "build"


task installFlatpak, "build and install flatpak package":
  exec "flatpak-builder --user --install --force-clean build-flatpak org.DTeam.DMusic.yml"


proc buildWindows(release: bool) =
  template cmake(args, body) =
    if not dirExists("build"):
      mkdir "build"
      withDir "build":
        exec "cmake -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_FIND_ROOT_PATH=/usr/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY " & args & " .."
        exec "make"
        body

  if not dirExists("build-windows"):
    mkdir "build-windows"

  withDir "build-windows":
    if not dirExists("taglib-1.12"):
      exec "wget https://taglib.org/releases/taglib-1.12.tar.gz"
      exec "tar -xf taglib-1.12.tar.gz"
      rmFile "taglib-1.12.tar.gz"
    
    withDir "taglib-1.12":
      cmake "":
        discard
    
    if not dirExists("zlib-1.2.13"):
      exec "wget https://zlib.net/zlib-1.2.13.tar.gz"
      exec "tar -xf zlib-1.2.13.tar.gz"
      rmFile "zlib-1.2.13.tar.gz"

    withDir "zlib-1.2.13":
      cmake "":
        cpFile "libzlibstatic.a", "libz.a"

  exec "nimble cpp -d:mingw -d:compiletimeOs:linux --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.cpp.exe:/usr/bin/x86_64-w64-mingw32-g++ --gcc.cpp.linkerexe:/usr/bin/x86_64-w64-mingw32-g++ -d:taglibLib:build-windows/taglib-1.12/build/taglib --passl:-Lbuild-windows/zlib-1.2.13/build --passl:-static -o:build-windows/dmusic.exe " & (if release: "-d:danger --app:gui" else: "") & " src/dmusic.nim"
  # exec "nimble c -d:mingw -d:compiletimeOs:linux --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --passl:-static -o:build-windows/dmusic.exe " & (if release: "-d:danger --app:gui" else: "") & " src/dmusic.nim"


task buildWindows, "cross-compile from Linux to Windows":
  buildWindows(release=true)

task buildWindowsDebug, "cross-compile from Linux to Windows":
  buildWindows(release=false)
