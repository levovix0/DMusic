{.used.}
import os, strformat, macros, strutils

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
  QString* {.importcpp, header: "QString".} = object
  
  QUrl* {.importcpp, header: "QUrl".} = object

  QList*[T] {.importcpp, header: "QList".} = object

  QByteArrayData* {.importcpp: "QByteArrayData", header: "QArrayData".} = object

  QObject* {.importcpp, header: "QObject", inheritable.} = object

  QBindingStorage* {.importcpp, header: "QObject".} = object
  
  QMetaObject* {.importcpp, header: "QObject".} = object
    d: QMetaObjectData

  QMetaObjectSuperData* {.importcpp: "QMetaObject::SuperData", header: "QObject".} = object
    direct*: ptr QMetaObject
    indirect*: proc(): ptr QMetaObject {.cdecl.}

  QMetaObjectData* {.importcpp: "QMetaObject::Data", header: "QObject".} = object
    superdata*: QMetaObjectSuperData
    stringdata*: ptr QByteArrayData
    data*: ptr cuint
    extradata: pointer

  QMetaObjectCall* {.importcpp: "QMetaObject::Call", header: "QObject".} = object

  QMetaType* {.size: uint32.sizeof, pure.} = enum
    bool = 1, int = 2, uint32 = 3
    longlong = 4, ulonglong = 5
    double = 6
    long = 32
    short = 33, char = 34
    ulong = 35, ushort = 36, uchar = 37
    float = 38, schar = 40, nullptr = 41
    void = 43

  QApplication* {.importcpp, header: "QApplication".} = object
  
  QTranslator* {.importcpp, header: "QTranslator".} = object
  
  QQmlApplicationEngine* {.importcpp, header: "QQmlApplicationEngine".} = object



#----------- QString -----------#
converter toQString*(this: string): QString =
  proc impl(data: cstring, len: int): QString {.importcpp: "QString::fromUtf8(@)", header: "QString".}
  impl(this, this.len)

converter toString*(this: QString): string =
  proc impl(this: QString): cstring {.importcpp: "#.toUtf8().data()", header: "QString".}
  $impl(this)



#----------- QUrl -----------#
converter toQUrl*(this: QString): QUrl =
  proc impl(this: QString): QUrl {.importcpp: "QUrl(@)", header: "QUrl".}
  impl(this)

converter toQUrl*(this: string): QUrl = this.toQString.toQUrl



#----------- QList -----------#
converter toQList*[T](this: seq[T]): QList[T] =
  proc ctor(len: int): QList {.importcpp: "QList(@)", header: "QList", constructor.}
  proc `[]`(this: QList, i: int): var T {.importcpp: "#[#]", header: "QList".}
  result = ctor(this.len)
  for i, v in this:
    result[i] = v

converter toSeq*[T](this: QList[T]): seq[T] =
  proc len(this: QList): int {.importcpp: "#.size()", header: "QList".}
  proc `[]`(this: QList, i: int): var T {.importcpp: "#[#]", header: "QList".}
  result.setLen this.len
  for i, v in result.mitems:
    v = this[i]



#----------- QObject -----------#
proc parent*(this: QObject): ptr QObject {.importcpp: "#.parent()".}

proc bindingStorage*(this: QObject): ptr QBindingStorage {.importcpp: "#.bindingStorage()".}
proc isWidget*(this: QObject): bool {.importcpp: "#.isWidgetType()".}
proc isWindow*(this: QObject): bool {.importcpp: "#.isWindowType()".}
proc signalsBlocked*(this: QObject): bool {.importcpp: "#.signalsBlocked()".}



#----------- QApplication -----------#
var
  cmdCount* {.importc.}: cint
  cmdLine* {.importc.}: cstringArray

proc newQApplication*(argc = cmdCount, argv = cmdLine): QApplication {.importcpp: "QApplication(@)", header: "QApplication", constructor.}
proc exec*(this: QApplication): int32 {.importcpp: "#.exec()".}

proc `appName=`*(this: type QApplication, v: string) =
  proc impl(v: QString) {.importcpp: "QApplication::setApplicationName(@)", header: "QApplication".}
  impl(v)

proc `organizationName=`*(this: type QApplication, v: string) =
  proc impl(v: QString) {.importcpp: "QApplication::setOrganizationName(@)", header: "QApplication".}
  impl(v)

proc `organizationDomain=`*(this: type QApplication, v: string) =
  proc impl(v: QString) {.importcpp: "QApplication::setOrganizationDomain(@)", header: "QApplication".}
  impl(v)



#----------- QTranslator -----------#
proc newQTranslator*(): QTranslator {.importcpp: "QTranslator(@)", header: "QTranslator", constructor.}

proc load*(this: QTranslator, file: string) =
  proc impl(this: QTranslator, file: QString) {.importcpp: "#.load(@)", header: "QTranslator".}
  this.impl(file)

proc install*(this: type QApplication, translator: QTranslator) =
  proc impl(translator: ptr QTranslator) {.importcpp: "QApplication::installTranslator(@)", header: "QApplication".}
  impl(translator.unsafeAddr)

proc remove*(this: type QApplication, translator: QTranslator) =
  proc impl(translator: ptr QTranslator) {.importcpp: "QApplication::removeTranslator(@)", header: "QApplication".}
  impl(translator.unsafeAddr)



#----------- QQmlApplicationEngine -----------#
proc newQQmlApplicationEngine*(): QQmlApplicationEngine {.importcpp: "QQmlApplicationEngine(@)", header: "QQmlApplicationEngine", constructor.}

proc load*(this: QQmlApplicationEngine, file: QUrl) {.importcpp: "#.load(@)", header: "QQmlApplicationEngine".}



#----------- macros -----------#
proc makeMetaObjectProc(t: NimNode, o: NimNode): NimNode =
  let decl = &"QMetaObject const* {t}::metaObject$3 const"
  let name = genSym(nskProc)
  quote do:
    proc `name`(): ptr QMetaObject {.exportc, codegenDecl: `decl`.} =
      let o {.inject.} = `o`.unsafeaddr
      {.emit: "`result` = QObject::d_ptr->metaObject? QObject::d_ptr->dynamicMetaObject() : `o`;".}

macro declareQtObjectSubtype*(name: static string, body: static string, parent: static string = "QObject") =
  let toEmit = "/*TYPESECTION*/ class " & name & " : public " & parent & """ {
public:
  const QMetaObject* metaObject() const override;
  void* qt_metacast(char const*) override;
  int qt_metacall(QMetaObject::Call, int, void**) override;
  """ & name & "(QObject* parent = nullptr): " & parent & "(parent) {}\n" & body & "};"
  quote do: {.emit: `toEmit`.}

macro makeStaticMetaObject*(t: typedesc, strings: static seq[string], metadata: static seq[int]) =
  proc linkProc(): QMetaObjectSuperData {.importcpp: "QMetaObject::SuperData::link<QObject::staticMetaObject>()", header: "QObject".}
  let link = bindSym"linkProc"

  let litsd = block:
    var res = nnkBracket.newTree
    var o = 0
    for i, s in strings:
      let size = s.len
      let offset = (s.len - i) * (int32, int32, uint32, int).sizeof + o
      res.add (quote do: (-1.int32, `size`.int32, 0.uint32, `offset`))
      o += s.len
    res

  let stringsd = block:
    var res = nnkBracket.newTree
    for c in strings.join("\0") & "\0":
      res.add newLit c
    res

  let stringdata = quote do: (`litsd`, `stringsd`)

  let cmetadata = block:
    var res = nnkBracket.newTree
    for x in metadata:
      res.add newLit x.uint32
    res.add newLit 0.uint32
    res
  
  let mo = genSym(nskVar)
  let sd = genSym(nskVar)
  let md = genSym(nskVar)

  let moProc = makeMetaObjectProc(t, mo)

  quote do:
    var `mo`: QMetaObject
    `mo`.d.superdata = `link`()
    var `sd` = `stringdata`
    `mo`.d.stringdata = cast[ptr QByteArrayData](`sd`.addr)
    var `md` = `cmetadata`
    `mo`.d.data = cast[ptr cuint](`md`.addr)
    
    `moProc`

