import os, strformat, macros, strutils, std/exitprocs
import qt

when defined(unix):
  const pythonVersion = "3.9"
  {.passc: "-I/usr/include/python" & pythonVersion.}
  {.passl: "-L/usr/local/lib/python" & pythonVersion & " -lpython" & pythonVersion.}

  {.passc: "-I/usr/include/taglib".}
  {.passl: "-ltag".}

macro sourcesFromDir(dir: static string = ".") =
  result = newStmtList()

  for k, file in dir.walkDir:
    if k notin {pcFile, pcLinkToFile}: continue
    if not file.endsWith(".cpp"): continue
    result.add quote do:
      {.compile: `file`.}
  
  for k, file in dir.walkDir:
    if k notin {pcFile, pcLinkToFile}: continue
    if not file.endsWith(".hpp") and not file.endsWith(".h"): continue
    if "Q_OBJECT" notin readFile(file): continue

    let moc = staticExec &"moc ../{file}"
    let filename = "build" / &"moc_{file.splitPath.tail}.cpp"
    writeFile filename, moc
    result.add quote do:
      {.compile: `filename`.}

macro resourcesFromDir(dir: static[string] = ".") =
  result = newStmtList()

  for k, file in dir.walkDir:
    if k notin {pcFile, pcLinkToFile}: continue
    if not file.endsWith(".qrc"): continue

    let qrc = staticExec &"rcc ../{file}"
    let filename = "build" / &"qrc_{file.splitPath.tail}.cpp"
    writeFile filename, qrc
    result.add quote do:
      {.compile: `filename`.}

sourcesFromDir "src"
resourcesFromDir "."


const cacheDir =
  when defined(windows): "?"
  else: getHomeDir() / ".cache/nim"

macro exportModuleToCpp(name: static string) =
  let nameIdent = ident name
  var toIncludeDir: string
  
  if defined(release):
    echo staticExec &"nim cpp --hints:off -d:release --noMain --noLinking --header:nim_{name}.h {name}"
    toIncludeDir = cacheDir / &"{name}_r"
  else:
    echo staticExec &"nim cpp --hints:off --noMain --noLinking --header:nim_{name}.h {name}"
    toIncludeDir = cacheDir / &"{name}_d"
  
  let toInclude = &"-I{toIncludeDir}"

  quote do:
    import `nameIdent`
    {.passc: `toInclude`.}

exportModuleToCpp "search"


{.emit: "#undef slots".}
{.emit: "#include <Python.h>".}
{.emit: "#define slots Q_SLOTS".}

{.emit: """#include "Translator.hpp"""".}

proc main =
  {.emit: "Py_Initialize();".}

  let app = newQApplication()
  {.emit: "Translator::setApp(&`app`);".}

  QApplication.appName = "DMusic"
  QApplication.organizationName = "DTeam"
  QApplication.organizationDomain = "zxx.ru"

  proc main() {.importcpp: "cppmain()", header: "main.hpp".}
  main()

  let engine = newQQmlApplicationEngine()
  {.emit: "Translator::setEngine(&`engine`);".}
  engine.load "qrc:/qml/main.qml"
  
  setProgramResult app.exec
  
  {.emit: "Py_Finalize();".}

when isMainModule:
  main()
