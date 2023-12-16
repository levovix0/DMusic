version       = "0.4.1"
author        = "DTeam"
description   = "Music player"
license       = "GPL"
srcDir        = "src"
bin           = @["dmusic"]
backend       = "cpp"

requires "nim == 1.6.16"
requires "fusion"
requires "cligen"
requires "https://github.com/levovix0/impl"
requires "discord_rpc"
requires "filetype"
requires "localize == 0.3.2"
requires "pixie"
requires "checksums"

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

task buildWindows, "cross-compile from Linux to Windows":
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
    
    # if not dirExists("Qt5.15.9-Windows-x86_64-MinGW8.1.0"):
    #   # exec "wget https://sourceforge.net/projects/fsu0413-qtbuilds/files/Qt5.15/Windows-x86_64/Qt5.15.9-Windows-x86_64-MinGW8.1.0-staticFull-20230602.7z/download"
    #   exec "wget https://sourceforge.net/projects/fsu0413-qtbuilds/files/Qt5.15/Windows-x86_64/Qt5.15.9-Windows-x86_64-MinGW8.1.0-20230530.7z/download"
    #   exec "7z x download"
    #   rmFile "download"

    # if not dirExists("cqtdeployer"):
    #   exec "wget https://github.com/QuasarApp/CQtDeployer/releases/download/v1.6.2285/CQtDeployer_1.6.2285.1507045_Linux_x86_64.zip"
    #   mkdir "cqtdeployer"
    #   exec "unzip CQtDeployer_1.6.2285.1507045_Linux_x86_64.zip -d cqtdeployer"
    #   rmFile "CQtDeployer_1.6.2285.1507045_Linux_x86_64.zip"
    #   exec "chmod +x cqtdeployer/bin/CQtDeployer"

    if not dirExists("dmusic-0.4"):
      exec "wget https://github.com/levovix0/DMusic/releases/download/0.4/DMusic-windows-updated.zip"
      mkdir "dmusic-0.4"
      exec "unzip DMusic-windows-updated.zip -d dmusic-0.4"
      rmFile "DMusic-windows-updated.zip"
    
    if not dirExists("nim-1.6.12"):
      exec "wget https://nim-lang.org/download/nim-1.6.12_x64.zip"
      exec "unzip nim-1.6.12_x64.zip"
      rmFile "nim-1.6.12_x64.zip"
    
    if not dirExists("mingw64"):
      exec "wget https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-win32/seh/x86_64-8.1.0-release-win32-seh-rt_v6-rev0.7z"
      exec "7z x x86_64-8.1.0-release-win32-seh-rt_v6-rev0.7z"
      rmFile "x86_64-8.1.0-release-win32-seh-rt_v6-rev0.7z"

  exec "nimble cpp --warnings:off -d:mingw -d:compiletimeOs:linux --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.cpp.exe:/usr/bin/x86_64-w64-mingw32-g++ --gcc.cpp.linkerexe:/usr/bin/x86_64-w64-mingw32-g++ -d:taglibLib:build-windows/taglib-1.12/build/taglib -d:qtLib:build-windows/dmusic-0.4/DMusic --passl:-Lbuild-windows/zlib-1.2.13/build -o:build-windows/dmusic.exe -d:danger --app:gui src/dmusic.nim"
  # exec "nimble cpp -d:mingw --d:compiletimeOs:linux --os:windows --cc:gcc --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.cpp.exe:/usr/bin/x86_64-w64-mingw32-g++ --gcc.cpp.linkerexe:/usr/bin/x86_64-w64-mingw32-g++ -o:build-windows/dmusic.exe src/dmusic.nim"

  withDir "build-windows":
    # exec "sh cqtdeployer/CQtDeployer.sh force-clear -qmlDir ../qml -bin dmusic.exe -platform win_x86_64 -qmake Qt5.15.9-Windows-x86_64-MinGW8.1.0/bin/qmake.exe"

    if dirExists("DMusic"):
      rmdir "DMusic"
    mkdir "DMusic"

    # proc splitPath(path: string): tuple[head, tail: string] =
    #   var sepPos = -1
    #   for i in countdown(len(path)-1, 0):
    #     if path[i] in {'/', '\\'}:
    #       sepPos = i
    #       break
    #   if sepPos >= 0:
    #     result.head = path[0 .. sepPos-1]
    #     result.tail = path[sepPos+1 .. ^1]
    #   else:
    #     result.head = ""
    #     result.tail = path
    
    # cpFile "DistributionKit/bin/dmusic.exe", "build/dmusic.exe"
    # for x in "DistributionKit/lib".listFiles:
    #   cpFile x, "build/" & x.splitPath.tail
    # for x in "DistributionKit/plugins".listDirs:
    #   cpDir x, "build/" & x.splitPath.tail
    # for x in "DistributionKit/qml".listDirs:
    #   cpDir x, "build/" & x.splitPath.tail

    cpFile "dmusic.exe", "DMusic/dmusic.exe"

    for d in ["audio", "mediaservice", "Qt", "styles", "bearer", "QtGraphicalEffects", "platforms", "QtQml", "iconengines", "platformthemes", "QtQuick", "imageformats", "playlistformats", "QtQuick.2"]:
      cpDir "dmusic-0.4/DMusic/" & d, "DMusic/" & d
    
    for f in ["Qt5Core.dll", "Qt5Gui.dll", "Qt5Multimedia.dll", "Qt5Network.dll", "Qt5Qml.dll", "Qt5QmlModels.dll", "Qt5QmlWorkerScript.dll", "Qt5QuickControls2.dll", "Qt5Quick.dll", "Qt5QuickShapes.dll", "Qt5QuickTemplates2.dll", "Qt5RemoteObjects.dll", "Qt5Svg.dll", "Qt5Widgets.dll"]:
      cpFile "dmusic-0.4/DMusic/" & f, "DMusic/" & f
    
    cpFile "mingw64/bin/libgcc_s_seh-1.dll", "DMusic/libgcc_s_seh-1.dll"
    cpFile "mingw64/bin/libstdc++-6.dll", "DMusic/libstdc++-6.dll"
    cpFile "mingw64/bin/libwinpthread-1.dll", "DMusic/libwinpthread-1.dll"
    cpFile "nim-1.6.12/bin/libcrypto-1_1-x64.dll", "DMusic/libcrypto-1_1-x64.dll"
    cpFile "nim-1.6.12/bin/libssl-1_1-x64.dll", "DMusic/libssl-1_1-x64.dll"
    cpFile "nim-1.6.12/bin/pcre64.dll", "DMusic/pcre64.dll"
    cpFile "nim-1.6.12/bin/cacert.pem", "DMusic/cacert.pem"

    exec "zip -r DMusic.zip DMusic"
