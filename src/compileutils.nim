import os

const compiletimeOs* {.strdefine.} =
  when defined(windows): "windows"
  elif defined(MacOsX):  "macos"
  else:                  "linux"

proc findExistant*(s: varargs[string]): string =
  result = s[0]
  for x in s:
    if dirExists x: return x
