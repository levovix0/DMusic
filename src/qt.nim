{.used.}
import utils
import os, strformat, macros, strutils, sequtils
import fusion/matching, fusion/astdsl

{.experimental: "caseStmtMacros".}

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

  QMetaObjectCall* {.importcpp: "QMetaObject::Call", header: "QObject", pure.} = enum
    invokeMetaMethod
    readProperty
    writeProperty
    resetProperty
    queryPropertyDesignable
    queryPropertyScriptable
    queryPropertyStored
    queryPropertyEditable
    queryPropertyUser
    createInstance
    indexOfMethod
    registerPropertyMetaType
    registerMethodArgumentMetaType

  QMetaType* {.size: uint32.sizeof, pure.} = enum
    bool = 1, int = 2, uint32 = 3
    longlong = 4, ulonglong = 5
    double = 6
    long = 32
    short = 33, char = 34
    ulong = 35, ushort = 36, uchar = 37
    float = 38, schar = 40, nullptr = 41
    void = 43

  QQuickItem* {.importcpp, header: "QQuickItem".} = object of QObject

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



#----------- tools -----------#
proc moc*(code: string): string {.compileTime.} =
  ## qt moc (meta-compiler) tool wrapper
  "moc".staticExec(code)

proc rcc*(file: string): string {.compileTime.} =
  ## qt rcc (resource-compiler) tool wrapper
  staticExec &"rcc {file.quoted}"



#----------- macros -----------#
macro qobject*(t, body) =
  ## export type to qt
  var t = t
  var parent = ident"QObject"
  if t.kind == nnkInfix:
    parent = t[2]
    t = t[1]
  
  proc qoClass(name: string, body: string, parent: string = "QObject"): seq[string] =
    @["/*TYPESECTION*/ class " & name & " : public " & parent & " {\nQ_OBJECT\npublic:\n  " &
    name & "(QObject* parent = nullptr): " & parent & "(parent) {}\n  ", body, "\n};"]

  proc toQtTypename(s: string): string =
    case s
    of "string": "QString"
    else: s

  proc toNimQtType(s: NimNode): NimNode =
    if s.kind == nnkEmpty: return bindSym"void"
    case $s
    of "string": ident "QString"
    of "int": ident "cint"
    else: s

  proc declslot(name: string, rettype: NimNode, args: seq[NimNode]): string =
    let argnames = args.mapit(it[0..^3]).concat.map(`$`)
    let argtypes = args.mapit(it[^2].repeat(it.len - 2)).concat.mapit(toQtTypename $it)
    let rettype = if rettype.kind != nnkEmpty: toQtTypename $rettype else: "void"
    &"public Q_SLOTS: {rettype} {name}(" & zip(argtypes, argnames).mapit(&"{it[0]} {it[1]}").join(", ") & ");"
  
  proc toNimQtVal[T](v: T): auto =
    when T is string: toQString v
    elif T is int: v.cint
    else: v

  proc fromNimQtVal[T](v: T): auto =
    when T is QString: toString v
    elif T is cint: v.int
    else: v
    
  proc implslot(name: string, alias: NimNode, rettype: NimNode, args: seq[NimNode]): NimNode =
    let tnqv = bindSym"toNimQtVal"
    let fnqv = bindSym"fromNimQtVal"

    buildAst(procDef):
      genSym nskProc
      empty()
      empty()
      formalParams:
        toNimQtType rettype
        for arg in args:
          var arg = arg
          arg[^2] = toNimQtType arg[^2]
          arg
      pragma:
        ident "exportc"
        exprColonExpr:
          ident "codegenDecl"
          let rt = if rettype.kind == nnkEmpty: "void" else: toQtTypename $rettype
          newLit &"{rt} {t}::{name}$3"
      empty()
      stmtList:
        varSection(identDefs(ident "this", ptrTy(t), empty()))
        pragma(exprColonExpr(ident "emit", bracket(ident"this", newLit " = &self;")))
        
        let a = buildAst:
          if args.len == 0:
            dotExpr(bracketExpr(ident "this"), alias)
          else:
            call:
              dotExpr(bracketExpr(ident "this"), alias)
              for arg in args.mapit(it[0..^3]).concat:
                call(fnqv, arg)
              
        if rettype.kind == nnkEmpty: a
        else: call(tnqv, a)

  var decl: seq[string]
  var impl = newStmtList()

  for x in body:
    case x
    of ProcDef[Ident(strVal: @name), Empty(), Empty(), FormalParams[@rettype, all @args], Empty(), Empty(), Empty()]:
      decl.add declslot(name, rettype, args)
      impl.add implslot(name, ident name, rettype, args)
    of ProcDef[Ident(strVal: @name), Empty(), Empty(), FormalParams[@rettype, all @args], Empty(), Empty(), StmtList[@alias is Ident()]]:
      decl.add declslot(name, rettype, args)
      impl.add implslot(name, alias, rettype, args)
    else: error("Unexpected syntax", x)

  let moc = moc qoClass($t, decl.join("\n"), $parent).join
  let toEmit = qoClass($t, decl.join("\n").indent(2), $parent)

  buildAst(stmtList):
    pragma(exprColonExpr(ident "emit", newLit &"/*INCLUDESECTION*/ #include <{parent}>"))
    pragma(exprColonExpr(ident "emit", bracket(newLit toEmit[0], t, newLit " self;\n", newLit toEmit[1], newLit toEmit[2])))
    pragma(exprColonExpr(ident "emit", bracket(newLit moc)))
    for x in impl: x


macro registerInQml*(t: typedesc, module: static string, verMajor, verMinor: static int) =
  ## export type to qml (must be exported to qt before)
  buildAst(stmtList):
    (quote do:
      block:
        proc x() {.importcpp: "(void)0", header: "qqml.h".} = discard
        x())
    pragma(exprColonExpr(
      ident "emit",
      bracket(
        newLit "qmlRegisterType<", newLit $t, newLit ">(", newLit module.quoted, newLit ", ",
        newLit $verMajor, newLit ", ", newLit $verMinor, newLit &", {quoted $t});"
      )
    ))


macro registerInQml*(t: typedesc, module: static string, verMajor, verMinor: static int; name: static string) =
  ## export type to qml (must be exported to qt before)
  buildAst(stmtList):
    (quote do:
      block:
        proc x() {.importcpp: "(void)0", header: "qqml.h".} = discard
        x())
    pragma(exprColonExpr(
      ident "emit",
      bracket(
        newLit "qmlRegisterType<", newLit $t, newLit ">(", newLit module.quoted, newLit ", ",
        newLit $verMajor, newLit ", ", newLit $verMinor, newLit &", {name.quoted});"
      )
    ))

