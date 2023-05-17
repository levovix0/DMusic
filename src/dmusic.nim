import std/exitprocs, os, times, strformat, macros, strutils, sequtils
import gui/[qt, messages, configuration]
import gui/[yandexMusicQmlModule, audio, qmlUtils, remoteAudio, playlist]
import gui/components/[page, searchPage]
import async, utils, yandexMusic

macro resourcesFromDir*(dir: static[string] = ".") =
  result = newStmtList()

  for k, file in dir.walkDir:
    if k notin {pcFile, pcLinkToFile}: continue
    if not file.endsWith(".qrc"): continue

    let qrc = rcc ".."/file
    let filename = "build" / &"qrc_{file.splitPath.tail}.cpp"
    writeFile filename, qrc
    result.add quote do:
      {.compile: `filename`.}

resourcesFromDir "."

when defined(windows):
  static:
    echo staticExec "windres ../dmusic.rc ../build/dmusic.o"
  {.link: "build/dmusic.o".}


var infinityLoop = doAsync:
  var darkTime = config.darkTheme

  while true:
    await sleepAsync(1000)

    if config.themeByTime:
      if now().hour in 7..18:
        if darkTime: config.darkTheme = false
        darkTime = false
      else:
        if not darkTime: config.darkTheme = true
        darkTime = true


proc gui: string =
  QApplication.appName = "DMusic"
  QApplication.organizationName = "DTeam"
  QApplication.organizationDomain = "zxx.ru"

  {.emit: """
  qmlRegisterSingletonType(QUrl("qrc:/qml/StyleSingleton.qml"), "DMusic", 1, 0, "Style");
  """.}

  let engine = newQQmlApplicationEngine()
  engine.load "qrc:/qml/main.qml"

  var tr = newQTranslator()

  notifyLanguageChanged &= proc() =
    globalLocale = (($config.language, ""), LocaleTable.default)
    if not tr.isEmpty: qApplicationRemove tr
    case config.language
    of Language.ru: tr.load ":translations/russian"; qApplicationInstall tr
    else: discard
    retranslate engine
  
  notifyCsdChanged &= proc() =
    when defined(windows): QApplication.icon = ":resources/app.svg"
    else: QApplication.icon = ":resources/app-papirus.svg"

  notifyLanguageChanged()
  notifyCsdChanged()

  onMainLoop:
    try: async.poll(5)
    except:
      echo getCurrentExceptionMsg()
      sendError tr"Exception during async operation", getCurrentExceptionMsg()

  setProgramResult QApplication.exec

  complete infinityLoop

proc download(tracks: seq[string], file: string = "") =
  if tracks.len == 0:
    echo tr"No tracks specified"
    return
  
  if file != "" and tracks.len != 1:
    echo tr"Can't download multiple tracks to same file"
    return

  for i, track in tracks:
    let id = try: parseInt track
    except:
      let (path, name) = track.splitPath
      if not path.endsWith "track/": 0
      else:
        try: parseInt name except: 0
    
    if id in 1..int.high:
      let track = yandexMusic.TrackId(id: id).fetch.waitFor[0]
      let file =
        if file == "": track.artists.mapit(it.name).join(", ") & " - " & track.title & ".mp3"
        else: file
      writeFile file, request(track.audioUrl.waitFor).waitFor
    else:
      let track = yandexMusic.search(track).waitFor.tracks[0]
      let file =
        if file == "": track.artists.mapit(it.name).join(", ") & " - " & track.title & ".mp3"
        else: file
      writeFile file, request(track.audioUrl.waitFor).waitFor

proc getRadioTracks*(station: string) =
  for i, track in RadioStation(id: station).getTracks.waitFor.tracks:
    echo i+1, ". [", track.id, "] ", track.title, (if track.comment != "": " (" & track.comment & ")" else: ""), " - ", track.artists.mapit(it.name).join(", ")

when isMainModule:
  import cligen
  clcfg.version = "0.4"
  if paramCount() == 0:
    dispatch gui
  else:
    dispatchMulti(
      [gui],
      [download, short={"file": 'o'}],
      [getRadioTracks, help={"station": "for stations based on track, use `track:TRACK_ID`"}]
    )

  updateTranslations()
