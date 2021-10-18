{.used.}
import os, strformat, macros, strutils, sequtils, tables
import fusion/matching, fusion/astdsl
import utils

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

  QVariant* {.importcpp, header: "QVariant".} = object

  QModelIndex* {.importcpp, header: "QModelIndex".} = object
  
  QHash*[K, V] {.importcpp, header: "QHash".} = object

  QByteArray* {.importcpp, header: "QByteArray".} = object

  QObject* {.importcpp, header: "QObject", inheritable.} = object

  QByteArrayData* {.importcpp: "QByteArrayData", header: "QArrayData".} = object

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

  QAbstractListModel* {.importcpp: "QAbstractListModel", header: "QAbstractListModel".} = object of QObject

  QQuickItem* {.importcpp, header: "QQuickItem".} = object of QObject

  QApplication* {.importcpp, header: "QApplication".} = object
  
  QTranslator* {.importcpp, header: "QTranslator".} = object
  
  QQmlApplicationEngine* {.importcpp, header: "QQmlApplicationEngine".} = object



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



#----------- QVariant -----------#
converter toQVariant*[T](v: T): QVariant =
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

proc bindingStorage*(this: QObject): ptr QBindingStorage {.importcpp: "#.bindingStorage()".}
proc isWidget*(this: QObject): bool {.importcpp: "#.isWidgetType()".}
proc isWindow*(this: QObject): bool {.importcpp: "#.isWindowType()".}
proc signalsBlocked*(this: QObject): bool {.importcpp: "#.signalsBlocked()".}



#----------- QAbstractListModel -----------#
proc layoutChanged*(this: ptr QAbstractListModel) =
  if this != nil:
    {.emit: "emit `this`->layoutChanged();".}



#----------- QApplication -----------#
var
  cmdCount* {.importc.}: cint
  cmdLine* {.importc.}: cstringArray

proc newQApplication*(argc = cmdCount, argv = cmdLine): QApplication {.importcpp: "QApplication(@)", header: "QApplication", constructor.}
proc exec*(this: QApplication): int32 {.importcpp: "#.exec()".}
  ## executes main loop and returns allication return code
proc processEvents*(this: QApplication) {.importcpp: "#.processEvents()".}
  ## do main loop step, can be called without anything instead of exec

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
template l(s: string{lit}): NimNode = newLit s
template i(s: string{lit}): NimNode = ident s
template s(s: string{lit}): NimNode = bindSym s

proc toQtVal[T](v: T): auto =
  when T is string: toQString v
  elif T is int: v.cint
  else: v

proc fromQtVal[T](v: T): auto =
  when T is QString: $v
  elif T is cint: v.int
  else: v

proc toQtTypename(s: string): string =
  case s
  of "string": "QString"
  else: s

proc argNames(args: NimNode|seq[NimNode]): seq[NimNode] =
  args.mapit(it[0..^3]).concat

proc implslot(t, ct: NimNode, name: string, rettype: NimNode, args: seq[NimNode], body: NimNode): NimNode =
  let tqv = s"toQtVal"

  proc toNimQtType(s: NimNode): NimNode =
    if s.kind == nnkEmpty: return s"void"
    case $s
    of "string": i"QString"
    of "int": i"cint"
    else: s

  buildAst(procDef):
    gensym nskProc
    empty()
    empty()
    formalParams:
      toNimQtType rettype
      for arg in args:
        var arg = arg
        arg[^2] = toNimQtType arg[^2]
        arg
    pragma:
      i"exportc"
      exprColonExpr:
        i"codegenDecl"
        newLit &"$1 {t}::{name}$3"
    empty()
    stmtList:
      varSection: identDefs(i"this", ptrTy ct, empty())
      pragma: exprColonExpr(i"emit", bracket(i"this", l" = this;"))
      
      if rettype.kind == nnkEmpty: body
      else: call(tqv, body)

proc qoClass(name: string, body: string, parent: string = "QObject"): array[3, string] =
  ["/*TYPESECTION*/ class " & name & " : public " & parent & " {\nQ_OBJECT\npublic:\n  " &
  name & "(QObject* parent = nullptr);\n  ", body, "\n};"]


proc qobjectCasesImpl(t, body, ct: NimNode, x: NimNode, decl: var seq[string], impl: var NimNode) =
  proc declslot(name: string, rettype: NimNode, args: seq[NimNode]): string =
    let argnames = args.mapit(it[0..^3]).concat.map(`$`)
    let argtypes = args.mapit(it[^2].repeat(it.len - 2)).concat.mapit(toQtTypename $it)
    let rettype = if rettype.kind != nnkEmpty: toQtTypename $rettype else: "void"
    &"public Q_SLOTS: {rettype} {name}(" & zip(argtypes, argnames).mapit(&"{it[0]} {it[1]}").join(", ") & ");"
    
  proc implslot(name: string, alias: NimNode, rettype: NimNode, args: seq[NimNode]): NimNode =
    let fqv = s"fromQtVal"

    qt.implslot t, ct, name, rettype, args, buildAst do:
      if args.len == 0:
        dotExpr(dotExpr(bracketExpr(i"this"), i"self"), alias)
      else:
        call dotExpr(dotExpr(bracketExpr(i"this"), i"self"), alias):
          for arg in args.argNames:
            call(fqv, arg)

  case x
  of ProcDef[Ident(strVal: @name), Empty(), Empty(), FormalParams[@rettype, all @args], Empty(), Empty(), Empty()]:
    decl.add declslot(name, rettype, args)
    impl.add implslot(name, ident name, rettype, args)
  
  of ProcDef[Ident(strVal: @name), Empty(), Empty(), FormalParams[@rettype, all @args], Empty(), Empty(), StmtList[@alias is Ident()]]:
    decl.add declslot(name, rettype, args)
    impl.add implslot(name, alias, rettype, args)
  
  of ProcDef[Ident(strVal: @name), Empty(), Empty(), FormalParams[@rettype, all @args], Empty(), Empty(), StmtList[all @body]]:
    decl.add declslot(name, rettype, args)
    
    let fqv = s"fromQtVal"
    impl.add: qt.implslot t, ct, name, rettype, args, buildAst stmtList do:
      letSection:
        for arg in args.argNames:
          identDefs(arg, empty(), call(fqv, arg))
      for x in body: x
  
  # of ProcDef[Ident(strVal: @name), Empty(), Empty(), FormalParams[@rettype, all @args], Pragma[Ident(strVal: "async")], Empty(), StmtList[all @body]]:
  #   discard
  
  of ProcDef[AccQuoted[Ident(strVal: "="), Ident(strVal: "new")], Empty(), Empty(), FormalParams[Empty(), all @args], Empty(), Empty(), @body]:
    impl.add: buildAst procDef:
      accQuoted(i"=", i"new")
      empty()
      empty()
      formalParams:
        empty()
        identDefs(i"this", varTy t, empty())
        for arg in args: arg
      empty()
      empty()
      if body.kind == nnkEmpty: discardStmt empty() else: body
    impl.add: buildAst procDef:
      i"qnew"
      empty()
      empty()
      formalParams:
        ptrTy ct
        identDefs(gensym nskParam, command(i"type", t), empty())
        for arg in args: arg
      empty()
      empty()
      stmtList:
        pragma: exprColonExpr(i"emit", bracket(i"result", newLit &" = new {t};"))
        call accQuoted(i"=", i"new"):
          bracketExpr dotExpr(bracketExpr i"result", i"self")
          for arg in args.argNames: arg
  
  else: error("Unexpected syntax", x)


macro qobject*(t, body) =
  ## export type to qt
  var t = t
  var parent = i"QObject"
  if t.kind == nnkInfix:
    parent = t[2]
    t = t[1]

  var decl: seq[string]
  var impl = newStmtList()

  let ct = gensym nskType
  impl.add: buildAst typeSection:
    typeDef:
      pragmaExpr(ct, pragma exprColonExpr(i"importcpp", newLit $t))
      empty()
      objectTy:
        empty()
        ofInherit(parent)
        recList:
          identDefs(i"self", t, empty())

  for x in body:
    qobjectCasesImpl t, body, ct, x, decl, impl

  let moc = moc qoClass($t, decl.join("\n"), $parent).join
  let toEmit = qoClass($t, decl.join("\n").indent(2), $parent)

  buildAst(stmtList):
    pragma: exprColonExpr i"emit": newLit &"/*INCLUDESECTION*/ #include <{parent}>"
    pragma: exprColonExpr i"emit": bracket(newLit toEmit[0], t, " self;\n".l, newLit toEmit[1], newLit toEmit[2])
    pragma: exprColonExpr i"emit": bracket(newLit moc)
    pragma: exprColonExpr i"emit":
      newLit &"/*VARSECTION*/ {t}::{t}(QObject* parent): {parent}(parent) " &
      "{\n  nimZeroMem((void*)(&self), sizeof(decltype(self)));\n}"
    for x in impl: x


macro qmodel*(t, body) =
  ## export model type to qt
  var t = t
  var parent = i"QAbstractListModel"
  if t.kind == nnkInfix:
    parent = t[2]
    t = t[1]

  var decl: seq[string]
  var impl = newStmtList()
  var dataImpl: Table[string, NimNode]

  let ct = gensym nskType
  impl.add: buildAst typeSection:
    typeDef:
      pragmaExpr(ct, pragma exprColonExpr(i"importcpp", newLit $t))
      empty()
      objectTy:
        empty()
        ofInherit(parent)
        recList:
          identDefs(i"self", t, empty())

  for x in body:
    case x
    of Call[Ident(strVal: "rows"), @body is StmtList()]:
      decl.add "int rowCount(QModelIndex const& parent) const override;"
      impl.add: buildAst(procDef):
        gensym nskProc
        empty()
        empty()
        formalParams:
          s"cint"
          newIdentDefs(gensym nskParam, s"QModelIndex")
        pragma:
          i"exportc"
          exprColonExpr:
            i"codegenDecl"
            newLit &"int {t}::rowCount(QModelIndex const& parent) const"
        empty()
        stmtList:
          varSection: identDefs(i"this", ptrTy t, empty())
          pragma: exprColonExpr(i"emit", bracket(i"this", l" = &self;"))
          call(s"cint", body)

    of Command[Ident(strVal: "get"), Ident(strVal: @valname), @body is StmtList()]:
      if dataImpl.len == 0:
        decl.add "QVariant data(QModelIndex const& index, int role) const override;"
        decl.add "QHash<int, QByteArray> roleNames() const override;"
      dataImpl[valname] = body

    else: qobjectCasesImpl t, body, ct, x, decl, impl
  
  impl.add:
    let i = nskParam.gensym "index"
    let role = nskParam.gensym "role"

    buildAst(procDef):
      gensym nskProc
      empty()
      empty()
      formalParams:
        s"QVariant"
        newIdentDefs(i, s"QModelIndex")
        newIdentDefs(role, s"cint")
      pragma:
        i"exportc"
        exprColonExpr:
          i"codegenDecl"
          newLit &"QVariant {t}::data(QModelIndex const& index, int role) const"
      empty()
      stmtList:
        varSection: identDefs(i"this", ptrTy t, empty())
        pragma: exprColonExpr(i"emit", bracket(i"this", l" = &self;"))
        varSection:
          identDefs(pragmaExpr(i"i", pragma(i"used")), empty(), call(s"int", dotExpr(i, s"row")))
          identDefs(pragmaExpr(i"j", pragma(i"used")), empty(), call(s"int", dotExpr(i, s"column")))
        caseStmt role:
          var ri = 0x0100
          for _, v in dataImpl:
            inc ri
            ofBranch(newLit ri):
              call(s"toQVariant", v)
          Else: call(s"toQVariant", newLit 0)

  impl.add:
    var li = nnkTableConstr.newTree
    var ri2 = 0x0100
    for k, _ in dataImpl:
      inc ri2
      li.add nnkExprColonExpr.newTree(newLit ri2, newLit k)

    buildAst(procDef):
      gensym nskProc
      empty()
      empty()
      formalParams:
        quote do: QHash[cint, QByteArray]
      pragma:
        i"exportc"
        exprColonExpr:
          i"codegenDecl"
          newLit &"QHash<int, QByteArray> {t}::roleNames() const"
      empty()
      call(s"toQHash", li)

  let moc = moc qoClass($t, decl.join("\n"), $parent).join
  let toEmit = qoClass($t, decl.join("\n").indent(2), $parent)

  buildAst(stmtList):
    pragma: exprColonExpr i"emit": newLit &"/*INCLUDESECTION*/ #include <{parent}>"
    pragma: exprColonExpr i"emit": bracket(newLit toEmit[0], t, " self;\n".l, newLit toEmit[1], newLit toEmit[2])
    pragma: exprColonExpr i"emit": bracket(newLit moc)
    pragma: exprColonExpr i"emit":
      newLit &"/*VARSECTION*/ {t}::{t}(QObject* parent): {parent}(parent) " &
      "{\n  nimZeroMem((void*)(&self), sizeof(decltype(self)));\n}"
    for x in impl: x


macro registerInQml*(t: typedesc, module: static string, verMajor, verMinor: static int) =
  ## export type to qml (must be exported to qt before)
  buildAst(stmtList):
    quote do:
      block:
        proc x() {.importcpp: "(void)0", header: "qqml.h".} = discard
        x()
    pragma: exprColonExpr i"emit":
      bracket(
        l"qmlRegisterType<", newLit $t, l">(", newLit module.quoted, l", ",
        newLit $verMajor, l", ", newLit $verMinor, newLit &", {quoted $t});"
      )


macro registerInQml*(t: typedesc, module: static string, verMajor, verMinor: static int; name: static string) =
  ## export type to qml (must be exported to qt before)
  buildAst(stmtList):
    quote do:
      block:
        proc x() {.importcpp: "(void)0", header: "qqml.h".} = discard
        x()
    pragma: exprColonExpr i"emit":
      bracket(
        l"qmlRegisterType<", newLit $t, l">(", newLit module.quoted, l", ",
        newLit $verMajor, l", ", newLit $verMinor, newLit &", {name.quoted});"
      )

