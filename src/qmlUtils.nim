{.used.}
import strutils, sequtils, re
import qt, configuration

type Clipboard = object

qobject Clipboard:
  property string text:
    set: QApplication.clipboard.text = value

registerSingletonInQml Clipboard, "DMusic", 1, 0



proc matchFilter(file: string, filter: string): bool =
  try:
    for x in filter.split("|").mapit(it[it.find("(")+1 .. it.find(")")-1].split(" ")).concat:
      if file.match(re("^" & x.replace(".", "\\.").replace("*", ".*").replace("?", ".") & "$")):
        return true
  except: discard

type FileDialogs = object

qobject FileDialogs:
  proc openFile(filter: string): string =
    var d = newQFileDialog()
    d.title = tr"Open file"
    d.filter = filter.replace("|", "\n")
    d.acceptMode = damOpen
    d.fileMode = dfmExistingFile
    if exec d: d.selectedUrls[0] else: ""
  
  proc checkFilter(file: string, filter: string): bool =
    matchFilter(file, filter)

registerSingletonInQml FileDialogs, "DMusic", 1, 0


type GlobalFocus = object
  item: string

qobject GlobalFocus:
  property string item:
    get: self.item
    set:
      if self.item == value: return
      self.item = value
      this.itemChanged
    notify

registerSingletonInQml GlobalFocus, "DMusic", 1, 0
