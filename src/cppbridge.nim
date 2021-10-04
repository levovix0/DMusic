import os, strformat, macros, strutils

macro sourcesFromDir*(dir: static string = ".") =
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

macro resourcesFromDir*(dir: static[string] = ".") =
  result = newStmtList()

  for k, file in dir.walkDir:
    if k notin {pcFile, pcLinkToFile}: continue
    if not file.endsWith(".qrc"): continue

    let qrc = staticExec &"rcc ../{file}"
    let filename = "build" / &"qrc_{file.splitPath.tail}.cpp"
    writeFile filename, qrc
    result.add quote do:
      {.compile: `filename`.}

const cacheDir =
  when defined(windows): "?"
  else: getHomeDir() / ".cache/nim"

macro exportModuleToCpp*(name: static string) =
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

