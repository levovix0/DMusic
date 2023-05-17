import modules, smartptrs

qtBuildModule "Core"

type
  QString* {.importcpp, header: "QString".} = object
  QUrl* {.importcpp, header: "QUrl".} = object
  QList*[T] {.importcpp, header: "QList".} = object
  QVariant* {.importcpp, header: "QVariant".} = object
  QModelIndex* {.importcpp, header: "QModelIndex".} = object
  QHash*[K, V] {.importcpp, header: "QHash".} = object
  QByteArray* {.importcpp, header: "QByteArray".} = object
  QByteArrayData* {.importcpp: "QByteArrayData", header: "QArrayData".} = object

  QObject* {.importcpp, header: "QObject", inheritable.} = object

  QAbstractListModel* {.importcpp: "QAbstractListModel", header: "QAbstractListModel".} = object of QObject
  
  QTranslator* {.importcpp, header: "QTranslator".} = object

#----------- QString -----------#
converter toQString*(this: string): QString =
  proc impl(data: cstring, len: int): QString {.importcpp: "QString::fromUtf8(@)", header: "QString".}
  impl(this, this.len)

converter `$`*(this: QString): string =
  proc impl(this: QString): cstring {.importcpp: "#.toUtf8().data()", header: "QString".}
  $impl(this)



#----------- QUrl -----------#
converter toQUrl*(this: QString): QUrl =
  proc impl(this: QString): QUrl {.importcpp: "QUrl(@)", header: "QUrl".}
  impl(this)

converter toQUrl*(this: string): QUrl = this.toQString.toQUrl

proc path*(this: QUrl): string =
  proc impl(this: QUrl): QString {.importcpp: "#.path()", header: "QUrl".}
  impl(this)

converter `$`*(this: QUrl): string =
  proc impl(this: QUrl): QString {.importcpp: "#.toString()", header: "QUrl".}
  impl(this)



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
  for i, v in result.mpairs:
    v = this[i]



#----------- QVariant -----------#
converter toQVariant*[T: bool|SomeInteger|QString|SomeFloat](v: T): QVariant =
  proc ctor(): QVariant {.importcpp: "QVariant(@)", header: "QVariant", constructor.}
  proc setValue(this: QVariant, v: T){.importcpp: "#.setValue(@)", header: "QVariant".}
  result = ctor()
  result.setValue v



#----------- QByteArray -----------#
converter toQByteArray*(this: string): QByteArray =
  proc impl(data: cstring, len: int): QByteArray {.importcpp: "QByteArray(@)", header: "QByteArray".}
  impl(this, this.len)



#----------- QHash -----------#
converter toQHash*(v: openarray[(int, string)]): QHash[cint, QByteArray] =
  proc ctor(): QHash[cint, QByteArray] {.importcpp: "QHash<int, QByteArray>(@)", header: "QHash".}
  proc `[]=`(this: QHash[cint, QByteArray], k: cint, v: QByteArray){.importcpp: "#[#] = #", header: "QHash".}
  result = ctor()
  for (k, v) in v:
    result[k.cint] = v.toQByteArray



#----------- QModelIndex -----------#
proc row*(this: QModelIndex): int =
  proc impl(this: QModelIndex): int {.importcpp: "#.row(@)", header: "QModelIndex".}
  this.impl

proc column*(this: QModelIndex): int =
  proc impl(this: QModelIndex): int {.importcpp: "#.column(@)", header: "QModelIndex".}
  this.impl



#----------- QObject -----------#
proc parent*(this: QObject): ptr QObject {.importcpp: "#.parent()".}

proc isWidget*(this: QObject): bool {.importcpp: "#.isWidgetType()".}
proc isWindow*(this: QObject): bool {.importcpp: "#.isWindowType()".}
proc signalsBlocked*(this: QObject): bool {.importcpp: "#.signalsBlocked()".}

proc dynamicCast*(this: ptr QObject, t: type): ptr t {.importcpp: "dynamic_cast<'0>(#)".}

proc connect*(a: QObject, signal: static string, b: QObject, slot: static string) =
  {.emit: [a, "->connect(", a, ", SIGNAL(" & signal & "), ", b, ", SLOT(" & slot & "));"].}



#----------- QAbstractListModel -----------#
proc layoutChanged*(this: ptr QAbstractListModel) =
  if this != nil:
    {.emit: "emit `this`->layoutChanged();".}



#----------- QTranslator -----------#
proc newQTranslator*: Ref[QTranslator] =
  proc impl: ptr QTranslator {.importcpp: "new QTranslator(@)", header: "QTranslator", constructor.}
  impl().toRef

proc load*(this: Ref[QTranslator], file: string) =
  proc impl(this: ptr QTranslator, file: QString) {.importcpp: "#->load(@)", header: "QTranslator".}
  this.raw.impl(file)

proc isEmpty*(this: Ref[QTranslator]): bool =
  proc impl(this: ptr QTranslator): bool {.importcpp: "#->isEmpty(@)", header: "QTranslator".}
  this.raw.impl
