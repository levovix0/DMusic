import os, strformat, macros

{.experimental: "caseStmtMacros".}
{.experimental: "overloadableEnums".}

proc quoted(s: string): string =
  result.addQuoted s


when defined(windows):
  proc findExistant(s: varargs[string]): string =
    result = s[0]
    for x in s:
      if dirExists x: return x
  const qtPath {.strdefine.} = findExistant("C:/Qt/5.15.2/mingw81_64", "D:/Qt/5.15.2/mingw81_64")

const qtInclude {.strdefine.} =
  when defined(flatpak): "/usr/include"
  elif defined(linux): "/usr/include/qt"
  else:                qtPath / "include"
const qtBin {.strdefine.} =
  when defined(linux): "/usr/bin"
  else:                qtPath / "bin"
const qtLib {.strdefine.} =
  when defined(flatpak): "/usr/lib/x86_64-linux-gnu"
  elif defined(linux): "/usr/lib"
  else:                qtPath / "lib"

func qso(module: string): string =
  when defined(windows): qtBin / &"Qt5{module}.dll"
  elif defined(MacOsX):  qtLib / &"libQt5{module}.dylib"
  else:                  qtLib / &"libQt5{module}.so"

macro qtBuildModule*(module: static[string]) =
  let c = "-I" & (qtInclude / &"Qt{module}")
  let l = qso module
  quote do:
    {.passc: `c`.}
    {.passl: `l`.}

{.passc: &"-I{qtInclude} -fPIC".}
when defined(linux): {.passl: &"-lpthread".}



#----------- tools -----------#
proc moc*(code: string): string {.compileTime.} =
  ## qt moc (meta-compiler) tool wrapper
  when defined(windows): ((qtBin / "moc.exe") & " --no-warnings").staticExec(code)
  else:                  ((qtBin / "moc") & " --no-warnings").staticExec(code)

proc rccImpl(file, fileRoot: string): string {.compileTime.} =
  when defined(windows): staticExec (qtBin / "rcc.exe") & " " & quoted(fileRoot.splitPath.head/file)
  else:                  staticExec (qtBin / "rcc") & " " & quoted(fileRoot.splitPath.head/file)

template rcc*(file: string): string =
  ## qt rcc (resource-compiler) tool wrapper
  bind rccImpl
  rccImpl(file, instantiationInfo(index=0, fullPaths=true).filename)
