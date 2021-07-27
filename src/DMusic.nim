import os, strformat, macros, strutils

{.passc: "-Dbuild_using_nim=1".}

func qso(module: string): string =
  when defined(windows): &"Qt5{module}.dll"
  elif defined(MacOsX): &"libQt5{module}.dylib"
  else: &"/usr/lib/libQt5{module}.so"

const qtpath {.strdefine.} = "/usr/include/qt"

macro qmo(module: static[string]) =
  let c = &"-I{qtpath}" / &"Qt{module}"
  let l = qso module
  quote do:
    {.passc: `c`.}
    {.passl: `l`.}

{.passc: &"-I{qtpath} -std=c++17 -fPIC".}
{.passl: "-lpthread".}
qmo"Core"
qmo"Gui"
qmo"Widgets"
qmo"Quick"
qmo"Qml"
qmo"Multimedia"
qmo"Network"
qmo"DBus"
qmo"QuickControls2"
qmo"Svg"

when defined(unix):
  const pythonVersion = "3.9"
  {.passc: "-I/usr/include/python" & pythonVersion.}
  {.passl: "-L/usr/local/lib/python" & pythonVersion & " -lpython" & pythonVersion.}

macro sourcesFromDir(dir: static[string] = ".") =
  result = newStmtList()
  for file in dir.walkDirRec:
    if not file.endsWith(".cpp"): continue
    let cpp = readFile(file)
    result.add quote do:
      {.emit: `cpp`.}
  
  for file in dir.walkDirRec:
    if not file.endsWith(".hpp") and not file.endsWith(".h"): continue
    if "Q_OBJECT" notin readFile(file): continue
    let moc = staticExec &"moc ../{file}"
    result.add quote do:
      {.emit: `moc`.}

  for file in dir.walkDirRec:
    if not file.endsWith(".qrc"): continue
    let qrc = staticExec &"rcc ../{file}"
    result.add quote do:
      {.emit: `qrc`.}

sourcesFromDir()

proc main(argc: cint, argv: cstringArray): cint {.importcpp: "cppmain(@)".}

var
  cmdCount {.importc: "cmdCount".}: cint
  cmdLine {.importc: "cmdLine".}: cstringArray
discard main(cmdCount, cmdLine)
