import times, std/exitprocs
import gui/[qt, messages, configuration]
import gui/[yandexMusicQmlModule, audio, qmlUtils, playlist, remotePlayer]
import gui/components/[page, searchPage]
import async, utils

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


proc gui*: string =
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
    except CatchableError:
      echo getCurrentExceptionMsg()
      sendError tr"Error during async operation", getCurrentExceptionMsg()
    except Defect:
      echo getCurrentExceptionMsg()
      sendError tr"Defect during async operation", getCurrentExceptionMsg()

  setProgramResult QApplication.exec

  complete infinityLoop
