import os
mode = ScriptMode.Silent

exec "nimble build"
# exec "nimble build --app:gui"
cpFile "DMusic.exe", "build/DMusic.exe"
cpDir "resources", "build/resources"

for file in walkDirRec(".", followFilter={}):
  if file.splitFile.ext == ".qml":
    cpFile file, "./build"/file.splitPath.tail