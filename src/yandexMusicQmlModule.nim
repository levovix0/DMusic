import qt, yandexMusic

{.emit: """/*INCLUDESECTION*/ #include "Translator.hpp"""".}
{.emit: """/*INCLUDESECTION*/ #include <QQuickItem>""".}

declareQtObjectSubtype "YandexMusicTrack", """
  `Track` track;
""", "QQuickItem"

type YandexMusicTrack* {.importcpp.} = object of QObject
  track: Track

proc id*(this: YandexMusicTrack): int = this.track.id

makeStaticMetaObject YandexMusicTrack, @[
  "YandexMusic",
  "strid",
], @[
  8, 0, 0, 0, 1, 14, 0, 0, 0, 0, 0, 0, 0, 0,

  # slots
  1, 0, 19, 2, 0x0a, # proc id(): int

  # slots: parameters
  QMetaType.int.ord,
]

proc `[]`[T](a: ptr T, i: int): var T =
  cast[ptr T](cast[int](a) + i * T.sizeof)[]

proc YandexMusicTrack_qt_static_metacall*(o: ptr QObject, c: QMetaObjectCall, id: cint, a: ptr pointer) =
  var isInvokeMethod: bool
  {.emit: "`isInvokeMethod` = `c` == QMetaObject::InvokeMetaMethod;".}
  if isInvokeMethod:
    var this: ptr YandexMusicTrack
    {.emit: "`this` = static_cast<YandexMusicTrack*>(`o`);".}
    template par[T](i: int): var T = cast[ptr int](a[i])[]

    case id
    of 0:
      if a[0] != nil: par[int](0) = this[].id()
      else:           discard this[].id()
    else: discard

type CharConstPtr {.importcpp: "char const*".} = cstring

proc qtMetaCast*(classname: CharConstPtr): pointer {.exportc, codegenDecl: "void* YandexMusicTrack::qt_metacast$3".} =
  proc QObject_qtMetaCast(classname: CharConstPtr): pointer {.importcpp: "QObject::qt_metacast(@)".}
  var this: ptr YandexMusicTrack
  {.emit: "`this` = this;".}

  if classname.isNil: nil
  elif $classname != "YandexMusicTrack": this.pointer
  else: QObject_qtMetaCast(classname)

proc qtMetaCall(c: QMetaObjectCall, id: cint, a: ptr pointer): cint
  {.exportc, codegenDecl: "int YandexMusicTrack::qt_metacall$3".} =
  var this: ptr YandexMusicTrack
  {.emit: "`this` = this;".}

  proc parentMetaCall(c: QMetaObjectCall, id: cint, a: ptr pointer): cint
    {.importcpp: "QObject::qt_metacall(@)".}
  var id = parentMetaCall(c, id, a)
  if id < 0: return id
  
  var isInvokeMethod: bool
  {.emit: "`isInvokeMethod` = `c` == QMetaObject::InvokeMetaMethod;".}
  var isRegisterMethodArgument: bool
  {.emit: "`isRegisterMethodArgument` = `c` == QMetaObject::RegisterMethodArgumentMetaType;".}

  if isInvokeMethod:
    if id < 1: this.YandexMusicTrack_qt_static_metacall(c, id, a)
    dec id
  elif isRegisterMethodArgument:
    if id < 1: cast[ptr cint](a[0])[] = -1
    dec id
  return id

proc registerYandexMusicTrackInQml* =
  {.emit: """qmlRegisterType<`YandexMusicTrack`>("DMusic", 1, 0, "YandexMusicTrack");""".}
