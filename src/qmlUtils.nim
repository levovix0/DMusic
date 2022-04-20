{.used.}
import strutils, sequtils, re, os
import pixie
import qt, configuration, async, audio, api, utils

when defined(windows):
  import osproc


type Clipboard = object

qobject Clipboard:
  property string text:
    set: QApplication.clipboard.text = value

  proc copyCurrentTrackPicture =
    asyncCheck: do_async:
      let cover = current_track.coverImage.await.decodeImage
      let font = readFont(config_dir/"font.ttf")
      font.size = 16
      font.paint.color = color(1, 1, 1, 1)
      let tts = font.typeset(current_track.title)
      font.paint.color = color(0.6, 0.6, 0.6, 1)
      let cts = font.typeset(current_track.comment)
      font.size = 14
      font.paint.color = color(0.85, 0.85, 0.85, 1)
      let ats = font.typeset(current_track.artists)
      let image = newImage(
        70 + max(font.layoutBounds(current_track.title).x + (if current_track.comment != "": 10 else: 0) +
          font.layoutBounds(current_track.comment).x, font.layoutBounds(current_track.artists).x).ceil.int,
        50
      )
      image.fill color(0.15, 0.15, 0.15, 1)
      let r = image.newContext
      r.drawImage cover, rect(0, 0, 50, 50)
      font.size = 16
      font.paint.color = color(1, 1, 1, 1)
      image.fillText tts, translate vec2(60, 7)
      font.paint.color = color(0.6, 0.6, 0.6, 1)
      image.fillText cts, translate vec2(60 + font.layoutBounds(current_track.title).x + 10, 7)
      font.size = 14
      font.paint.color = color(0.85, 0.85, 0.85, 1)
      image.fillText ats, translate vec2(60, 6 + 14 + 7)
      image.writeFile(data_dir/"img.png")
      QApplication.clipboard.image = qimageFromFile((data_dir/"img.png").cstring)[]

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
  
  proc showInExplorer(path: string) =
    let file = if path.startsWith("file:"): path[5..^1] else: path
    
    when defined(linux):
      # try to open dolphin
      if execShellCmd("dolphin --select " & file.quoted) == 0: return

      # use qt to open directory in default app
      let dir = file.splitPath.head
      openUrlInDefaultApplication("file:" & dir)
    
    elif defined(windows):
      # open explorer
      discard startProcess("explorer.exe", "", ["/select,", file.absolutePath]) 

    else:
      # use qt to open directory in default app
      let dir = file.splitPath.head
      openUrlInDefaultApplication("file:" & dir)

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
