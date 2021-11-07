import std/exitprocs, os, times, strformat, macros, strutils
import qt, messages, async, localize, utils, configuration
import yandexMusicQmlModule, audio, qmlUtils


macro resourcesFromDir*(dir: static[string] = ".") =
  result = newStmtList()

  for k, file in dir.walkDir:
    if k notin {pcFile, pcLinkToFile}: continue
    if not file.endsWith(".qrc"): continue

    let qrc = rcc &"../{file}"
    let filename = "build" / &"qrc_{file.splitPath.tail}.cpp"
    writeFile filename, qrc
    result.add quote do:
      {.compile: `filename`.}

resourcesFromDir "."


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


proc dmusic: string =
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
    if not tr.isEmpty: QApplication.remove tr
    case config.language
    of Language.ru: tr.load ":translations/russian"; QApplication.install tr
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


when isMainModule:
  import cligen
  clcfg.version = "0.3"
  dispatch dmusic

  updateTranslations()
