import std/exitprocs
import cppbridge, qt, messages, async, localize
import yandexMusicQmlModule, audio, qmlUtils

sourcesFromDir "src"
resourcesFromDir "."

{.emit: """#include "Translator.hpp"""".}

proc initializeDMusicQmlModule() {.importcpp: "initializeDMusicQmlModule()", header: "main.hpp".}
proc cppmain() {.importcpp: "cppmain()", header: "main.hpp".}

var infinityLoop = doAsync:
  while true: await sleepAsync(100)

proc dmusic: string =
  {.emit: "Translator::setApp(QApplication::instance());".}

  QApplication.appName = "DMusic"
  QApplication.organizationName = "DTeam"
  QApplication.organizationDomain = "zxx.ru"

  initializeDMusicQmlModule()
  cppmain()

  let engine = newQQmlApplicationEngine()
  {.emit: "Translator::setEngine(&`engine`);".}
  engine.load "qrc:/qml/main.qml"

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
