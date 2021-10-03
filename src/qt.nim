{.used.}
import os, strformat, macros

func qso(module: string): string =
  when defined(windows): &"Qt5{module}.dll"
  elif defined(MacOsX): &"libQt5{module}.dylib"
  else: &"/usr/lib/libQt5{module}.so"

const qtpath {.strdefine.} = "/usr/include/qt"

macro qmo(module: static[string]) =
  let c = &"-I{qtpath}" / &"Qt{module}"
  let l = qso module
  quote do:
    {.passc: `c`.}
    {.passl: `l`.}

{.passc: &"-I{qtpath} -std=c++17 -fPIC".}
{.passl: "-lpthread".}
qmo"Core"
qmo"Gui"
qmo"Widgets"
qmo"Quick"
qmo"Qml"
qmo"Multimedia"
qmo"Network"
qmo"DBus"
qmo"QuickControls2"
qmo"Svg"


type
  QString* {.importcpp, header: "<QString>".} = object
  QUrl* {.importcpp, header: "<QUrl>".} = object

  QApplication* {.importcpp, header: "<QApplication>".} = object
  QTranslator* {.importcpp, header: "<QTranslator>".} = object
  
  QQmlApplicationEngine* {.importcpp, header: "<QQmlApplicationEngine>".} = object


converter toQString*(this: string): QString =
  proc impl(data: cstring, len: int): QString {.importcpp: "QString::fromUtf8(@)", header: "<QString>".}
  impl(this, this.len)

converter toString*(this: QString): string =
  proc impl(this: QString): cstring {.importcpp: "#.toUtf8().data()", header: "<QString>".}
  $impl(this)

converter toQUrl*(this: QString): QUrl =
  proc impl(this: QString): QUrl {.importcpp: "QUrl(@)", header: "<QUrl>".}
  impl(this)

converter toQUrl*(this: string): QUrl = this.toQString.toQUrl


var
  cmdCount* {.importc.}: cint
  cmdLine* {.importc.}: cstringArray

proc newQApplication*(argc = cmdCount, argv = cmdLine): QApplication {.importcpp: "QApplication(@)", header: "<QApplication>", constructor.}
proc exec*(this: QApplication): int32 {.importcpp: "#.exec()".}

proc `appName=`*(this: type QApplication, v: string) =
  proc impl(v: QString) {.importcpp: "QApplication::setApplicationName(@)", header: "<QApplication>".}
  impl(v)

proc `organizationName=`*(this: type QApplication, v: string) =
  proc impl(v: QString) {.importcpp: "QApplication::setOrganizationName(@)", header: "<QApplication>".}
  impl(v)

proc `organizationDomain=`*(this: type QApplication, v: string) =
  proc impl(v: QString) {.importcpp: "QApplication::setOrganizationDomain(@)", header: "<QApplication>".}
  impl(v)


proc newQTranslator*(): QTranslator {.importcpp: "QTranslator(@)", header: "<QTranslator>", constructor.}

proc load*(this: QTranslator, file: string) =
  proc impl(this: QTranslator, file: QString) {.importcpp: "#.load(@)", header: "<QTranslator>".}
  this.impl(file)

proc install*(this: type QApplication, translator: QTranslator) =
  proc impl(translator: ptr QTranslator) {.importcpp: "QApplication::installTranslator(@)", header: "<QApplication>".}
  impl(translator.unsafeAddr)

proc remove*(this: type QApplication, translator: QTranslator) =
  proc impl(translator: ptr QTranslator) {.importcpp: "QApplication::removeTranslator(@)", header: "<QApplication>".}
  impl(translator.unsafeAddr)


proc newQQmlApplicationEngine*(): QQmlApplicationEngine {.importcpp: "QQmlApplicationEngine(@)", header: "<QQmlApplicationEngine>", constructor.}

proc load*(this: QQmlApplicationEngine, file: QUrl) {.importcpp: "#.load(@)", header: "<QQmlApplicationEngine>".}

