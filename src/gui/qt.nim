import os, strformat, macros, strutils, sequtils, tables, unicode
import fusion/matching, fusion/astdsl
import qt/[modules, smartptrs, core]
export modules, smartptrs, core

{.experimental: "caseStmtMacros".}
{.experimental: "overloadableEnums".}

proc quoted(s: string): string =
  result.addQuoted s

proc capitalizeFirst(s: string): string =
  if s.len == 0: return
  $s.runeAt(0).toUpper & s[1..^1]

qtBuildModule "Gui"
qtBuildModule "Widgets"
qtBuildModule "Quick"
qtBuildModule "Qml"
qtBuildModule "Multimedia"
qtBuildModule "QuickControls2"
qtBuildModule "Svg"
qtBuildModule "DBus"



{.emit: """#include <QTimer>""".}

type
  QJsValue* {.importcpp: "QJSValue", header: "QJSValue", bycopy.} = object

  QDBusAbstractAdaptor* {.importcpp: "QDBusAbstractAdaptor", header: "QDBusAbstractAdaptor".} = object of QObject
  QQuickItem* {.importcpp, header: "QQuickItem".} = object of QObject

  QQuickItemFlag* = enum
    clipsChildrenToShape
    acceptsInputMethod
    isFocusScope
    hasContents
    acceptsDrops

  QQuickImplicitSizeItem* {.importcpp, header: "QQuickImplicitSizeItem".} = object of QQuickItem
  QQuickText* {.importcpp, header: "QQuickText".} = object of QQuickImplicitSizeItem

  QApplication* {.importcpp, header: "QApplication".} = object
  QQmlApplicationEngine* {.importcpp, header: "QQmlApplicationEngine".} = object
  
  QClipboard* {.importcpp, header: "QClipboard".} = object
  QImage* {.importcpp, header: "QImage".} = object

  QFileDialog* {.importcpp, byref, header: "QFileDialog".} = object
  DialogAcceptMode* = enum
    damOpen, damSave
  DialogFileMode* = enum
    dfmAnyFile, dfmExistingFile, dfmDirectory, dfmExistingFiles



#----------- QQuickItem -----------#
proc clip*(this: QQuickItem): bool {.importcpp: "#.clip(@)", header: "QQuickItem".}
proc `clip=`*(this: QQuickItem, v: bool) {.importcpp: "#.setClip(@)", header: "QQuickItem".}

proc width*(this: QQuickItem): float {.importcpp: "#.width(@)", header: "QQuickItem".}
proc height*(this: QQuickItem): float {.importcpp: "#.height(@)", header: "QQuickItem".}

proc `width=`*(this: QQuickItem, v: float) {.importcpp: "#.setWidth(@)", header: "QQuickItem".}
proc `height=`*(this: QQuickItem, v: float) {.importcpp: "#.setHeight(@)", header: "QQuickItem".}

proc `[]=`*(this: QQuickItem, flag: QQuickItemFlag, v: bool) {.importcpp: "#.setFlag(@)", header: "QQuickItem".}



#----------- QApplication -----------#
var
  cmdCount* {.importc.}: cint
  cmdLine* {.importc.}: cstringArray

proc init(app: ptr QApplication, argc = cmdCount, argv = cmdLine)
  {.importcpp: "new (#) QApplication(@)", header: "QApplication".}

proc destroy(app: QApplication)
  {.importcpp: "#.~QApplication()", header: "QApplication".}

var app: ref QApplication
new app, (proc(_: ref QApplication) = destroy app[])
init cast[ptr QApplication](app)


proc exec*(this: type QApplication): int32 {.importcpp: "QApplication::exec()".}
  ## executes main loop and returns allication return code
proc processEvents*(this: type QApplication) {.importcpp: "QApplication::processEvents()".}
  ## do main loop step, can be called without anything instead of exec

proc `appName=`*(this: type QApplication, v: string) =
  proc impl(v: QString) {.importcpp: "QApplication::setApplicationName(@)", header: "QApplication".}
  impl(v)

proc `icon=`*(this: type QApplication, v: string) =
  type QIcon {.importcpp: "QIcon", header: "QIcon".} = object
  proc icon(v: QString): QIcon {.importcpp: "QIcon(@)", header: "QIcon".}
  proc impl(v: QIcon) {.importcpp: "QApplication::setWindowIcon(@)", header: "QApplication".}
  impl(icon v)

proc `organizationName=`*(this: type QApplication, v: string) =
  proc impl(v: QString) {.importcpp: "QApplication::setOrganizationName(@)", header: "QApplication".}
  impl(v)

proc `organizationDomain=`*(this: type QApplication, v: string) =
  proc impl(v: QString) {.importcpp: "QApplication::setOrganizationDomain(@)", header: "QApplication".}
  impl(v)

var mainLoopCallbacks*: seq[proc()]
proc onMainLoopProc {.exportc.} =
  for cb in mainLoopCallbacks: cb()

proc onMain =
  {.emit: """
  auto timer = new QTimer;
  QObject::connect(timer, &QTimer::timeout, []{ onMainLoopProc(); });
  timer->start(10);
  """.}
onMain()

template onMainLoop*(body) =
  mainLoopCallbacks.add (proc() = body)

proc clipboard*(this: type QApplication): ptr QClipboard
  {.importcpp: "QApplication::clipboard()", header: "QApplication".}



#----------- QApplication + QTranslator -----------#
proc qApplicationInstall*(translator: Ref[QTranslator]) =
  proc impl(translator: ptr QTranslator) {.importcpp: "QApplication::installTranslator(@)", header: "QApplication".}
  impl(translator.raw)

proc qApplicationRemove*(translator: Ref[QTranslator]) =
  proc impl(translator: ptr QTranslator) {.importcpp: "QApplication::removeTranslator(@)", header: "QApplication".}
  impl(translator.raw)



#----------- QQmlApplicationEngine -----------#
proc newQQmlApplicationEngine*(): ptr QQmlApplicationEngine
  {.importcpp: "new QQmlApplicationEngine(@)", header: "QQmlApplicationEngine", constructor.}

proc load*(this: ptr QQmlApplicationEngine, file: QUrl)
  {.importcpp: "#->load(@)", header: "QQmlApplicationEngine".}

proc retranslate*(this: ptr QQmlApplicationEngine)
  {.importcpp: "#->retranslate(@)", header: "QQmlApplicationEngine".}



#----------- QClipboard -----------#
proc `text=`*(this: ptr QClipboard, text: string) =
  proc impl(this: ptr QClipboard, text: QString) {.importcpp: "#->setText(@)", header: "QClipboard".}
  impl(this, text)

proc `image=`*(this: ptr QClipboard, v: QImage) =
  proc impl(this: ptr QClipboard, text: QImage) {.importcpp: "#->setImage(@, QClipboard::Clipboard)", header: "QClipboard".}
  impl(this, v)



#----------- QImage -----------#
proc qimageFromFile*(filename: cstring): ptr QImage
  {.importcpp: "new QImage(@)", header: "QImage", constructor.}



#----------- QFileDialog -----------#
proc newQFileDialog*: QFileDialog {.importcpp: "QFileDialog", header: "QFileDialog", constructor.}
proc exec*(this: QFileDialog): bool {.importcpp: "#.exec(@)", header: "QFileDialog".}

proc selectedUrls*(this: QFileDialog): seq[string] =
  proc impl(this: QFileDialog): QList[QUrl] {.importcpp: "#.selectedUrls()", header: "QFileDialog".}
  for x in this.impl.toSeq:
    result.add $x

proc `filter=`*(this: QFileDialog, v: string) =
  proc impl(this: QFileDialog, v: QString) {.importcpp: "#.setNameFilter(@)", header: "QFileDialog".}
  impl(this, v)

proc `title=`*(this: QFileDialog, v: string) =
  proc impl(this: QFileDialog, v: QString) {.importcpp: "#.setWindowTitle(@)", header: "QFileDialog".}
  impl(this, v)

proc `acceptMode=`*(this: QFileDialog, v: DialogAcceptMode) {.importcpp: "#.setAcceptMode(@)", header: "QFileDialog".}
proc `fileMode=`*(this: QFileDialog, v: DialogFileMode) {.importcpp: "#.setFileMode(@)", header: "QFileDialog".}



#----------- QDesktopServices -----------#
proc openUrlInDefaultApplication*(path: string) =
  proc impl(v: QString) {.importcpp: "QDesktopServices::openUrl(@)", header: "QDesktopServices".}
  impl(path)



#----------- macros -----------#
template l(s: string{lit}): NimNode = newLit s
template i(s: string{lit}): NimNode = ident s
template s(s: string{lit}): NimNode = bindSym s

proc toQtVal[T](v: T): auto =
  when T is string: toQString v
  elif T is int: v.cint
  elif T is float: v.cfloat
  else: v

proc fromQtVal[T](v: T): auto =
  when T is QString: $v
  elif T is cint: v.int
  elif T is cfloat: v.float
  else: v

proc toQtTypename(s: string): string =
  ## todo: use types instead of strings
  case s
  of "string": "QString"
  of "QJsValue": "QJSValue"
  else: s

proc argNames(args: NimNode|seq[NimNode]): seq[NimNode] =
  args.mapit(it[0..^3]).concat

proc implslot(t, ct: NimNode, name: string, rettype: NimNode, args: seq[NimNode], pragma: seq[NimNode], body: NimNode): NimNode =
  let tqv = s"toQtVal"

  proc toNimQtType(s: NimNode): NimNode =
    if s.kind == nnkEmpty: return s
    case $s
    of "string": i"QString"
    of "int": i"cint"
    of "float": i"cfloat"
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
      for x in pragma: x
    empty()
    stmtList:
      varSection: identDefs(pragmaExpr(i"this", pragma(i"used")), ptrTy ct, empty())
      pragma: exprColonExpr(i"emit", bracket(i"this", l" = this;"))
      quote do:
        template self(): var `t` {.used.} = this[].self
      
      if rettype.kind == nnkEmpty: body
      else: call(tqv, body)

proc qoClass(name: string, body: string, parent: string): array[3, string] =
  [
    &"""/*TYPESECTION*/ class {name} : public {parent} {{
  Q_OBJECT
  public: {name}(QObject* parent = nullptr);
  """,
    body,
    "\n};"
  ]


proc qobjectCasesImpl(t, parent, body, ct: NimNode, x: NimNode, decl: var seq[string], impl: var NimNode, constructor: var NimNode, signalNames: var seq[string]) =
  proc declaringArgs(args: seq[NimNode]): string =
    zip(
      args.mapit(it[^2].repeat(it.len - 2)).concat.mapit(it.`$`.toQtTypename),
      args.mapit(it[0..^3]).concat.map(`$`)
    ).mapit(&"{it[0]} {it[1]}").join(", ")

  proc declproc(name: string, rettype: NimNode, args: seq[NimNode]): string =
    let rettype = if rettype.kind in {nnkIdent, nnkSym}: toQtTypename $rettype else: "void"
    &"public: {rettype} {name}(" & args.declaringArgs & ");"

  proc declslot(name: string, rettype: NimNode, args: seq[NimNode]): string =
    let rettype = if rettype.kind in {nnkIdent, nnkSym}: toQtTypename $rettype else: "void"
    &"public Q_SLOTS: {rettype} {name}(" & args.declaringArgs & ");"

  proc declsignal(name: string, rettype: NimNode, args: seq[NimNode]): string =
    let rettype = if rettype.kind in {nnkIdent, nnkSym}: toQtTypename $rettype else: "void"
    &"Q_SIGNALS: {rettype} {name}(" & args.declaringArgs & ");"
  
  proc newSignal(name: NimNode, rettype: NimNode, args: seq[NimNode], decl: var seq[string], impl: var NimNode, signalNames: var seq[string]) =
    signalNames.add $name
    decl.add declsignal($name, rettype, args)
    
    impl.add: buildAst procDef:
      name
      empty()
      empty()
      formalParams:
        i"auto"
        identDefs(i"this", ptrTy ct, empty())
        for arg in args: arg
      empty()
      empty()
      stmtList:
        if args.argNames.len > 0:
          letSection: varTuple:
            for arg in args.argNames: arg
            empty()
            tupleConstr:
              for arg in args.argNames: call(s"toQtVal", arg)
        pragma: exprColonExpr i"emit": bracket:
          l"emit "
          i"this"; l"->"; newLit $name
          l"("
          if args.argNames.len > 0:
            for arg in args.argNames.mapit(@[it, l", "]).concat[0..^2]: arg
          l");"

  case x  
  of ProcDef[Ident(strVal: @name), Empty(), Empty(), FormalParams[@rettype, all @args], Empty(), Empty(), StmtList[all @body]]:
    decl.add declslot(name, rettype, args)
    
    impl.add: implslot t, ct, name, rettype, args, @[], buildAst(stmtList) do:
      letSection:
        for arg in args.argNames:
          identDefs(arg, empty(), call(s"fromQtVal", arg))
      for x in body: x

  of ProcDef[@name is Ident(), Empty(), Empty(), FormalParams[@rettype, all @args], Pragma[Ident(strVal: "signal")], Empty(), Empty()]:
    newSignal name, rettype, args, decl, impl, signalNames
      
  of ProcDef[Ident(strVal: @name), Empty(), Empty(), FormalParams[@rettype, all @args], Pragma[all @pragma], Empty(), StmtList[all @body]]:
    decl.add declslot(name, rettype, args)
    
    impl.add: implslot t, ct, name, rettype, args, pragma, buildAst(stmtList) do:
      letSection:
        for arg in args.argNames:
          identDefs(arg, empty(), call(s"fromQtVal", arg))
      for x in body: x
  
  of ProcDef[@name is AccQuoted[Ident(strVal: "="), Ident(strVal: "new")], Empty(), Empty(), FormalParams[Empty()], Empty(), Empty(), @body]:
    constructor.body = buildAst stmtList:
      quote do:
        template self(): var `t` {.used.} = this[].self
      call s"wasMoved", i"self"
      body
  
  of Command[Ident(strVal: "property"), Command[@propType, Ident(strVal: @name)], @body is StmtList()]:
    var getter: NimNode
    var setter: NimNode
    var notify: NimNode
    
    for x in body:
      case x
      of Ident(strVal: "auto"):
        if getter == nil:
          getter = buildAst:
            dotExpr:
              ident "self"
              ident name
        if notify == nil:
          notify = ident &"{name}Changed"
          copyLineInfo notify, x
          newSignal notify, newEmptyNode(), @[], decl, impl, signalNames
        if setter == nil:
          setter = buildAst(stmtList):
            asgn:
              dotExpr:
                ident "self"
                ident name
              ident "value"
            call:
              notify
              ident "this"


      of Call[Ident(strVal: "get"), @body]:
        if getter != nil: error("getter is already declared", x)
        getter = body

      of Call[Ident(strVal: "set"), @body]:
        if setter != nil: error("setter is already declared", x)
        setter = body

      of Command[Ident(strVal: "notify"), @name is Ident()]:
        if notify != nil: error("notify is already declared", x)
        notify = name
        if $name notin signalNames:
          newSignal notify, newEmptyNode(), @[], decl, impl, signalNames

      of Ident(strVal: "notify"):
        if notify != nil: error("notify already declared", x)
        notify = ident &"{name}Changed"
        copyLineInfo notify, x
        newSignal notify, newEmptyNode(), @[], decl, impl, signalNames
      
      else: error("Unexpected syntax", x)
    
    if getter == nil and notify != nil:
      warning("Property with notify has no getter", body)
    
    decl.add "public: Q_PROPERTY(" & toQtTypename($propType) & " " & name & " " &
      (if getter != nil: &"READ {name} " else: "") &
      (if setter != nil: &"WRITE set{name.capitalizeFirst} " else: "") &
      (if notify != nil: &"NOTIFY {notify}" else: "") &
      ")"
    
    if getter != nil:
      decl.add declproc(name, propType, @[])
      
      impl.add: implslot t, ct, name, propType, @[], @[], getter
    
    if setter != nil:
      decl.add declproc("set" & name.capitalizeFirst, newEmptyNode(), @[newIdentDefs(i"value", propType)])
      
      let v = i"value"
      copyLineInfo(v, setter)

      impl.add: implslot t, ct, "set" & name.capitalizeFirst, newEmptyNode(), @[newIdentDefs(i"value", propType)], @[], buildAst(stmtList) do:
        letSection:
          identDefs(v, empty(), call(s"fromQtVal", i"value"))
        setter
  
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
  var signalNames: seq[string]

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

  let ctorSym = nskProc.gensym "constructor"
  var constructor = buildAst procDef:
    ctorSym
    empty()
    empty()
    formalParams:
      empty()
      identDefs i"this", ptrTy ct, empty()
    empty()
    empty()
    stmtList:
      quote do:
        template self(): var `t` {.used.} = this[].self
      call s"wasMoved", i"self"

  for x in body:
    qobjectCasesImpl t, parent, body, ct, x, decl, impl, constructor, signalNames

  let moc = moc qoClass($t, decl.join("\n"), $parent).join
  let toEmit = qoClass($t, decl.join("\n").indent(2), $parent)

  let cts = ident"Ct"
  copyLineInfo(cts, body)

  buildAst(stmtList):
    pragma: exprColonExpr i"emit": newLit &"/*INCLUDESECTION*/ #include <{parent}>"
    pragma: exprColonExpr i"emit": bracket(newLit toEmit[0], t, " self;\n".l, newLit toEmit[1], newLit toEmit[2])
    pragma: exprColonExpr i"emit": bracket(newLit moc)
    templateDef:
      postfix:
        ident"*"
        cts
      empty()
      empty()
      formalParams:
        i"type"
        identDefs:
          gensym nskParam
          command i"type", t
          empty()
      empty()
      empty()
      ct
    for x in impl: x
    constructor
    pragma:
      exprColonExpr i"emit":
        bracket:
          newLit fmt "{t}::{t}(QObject* parent): {parent}(parent) {{ "
          ctorSym
          l"(this); }"


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
  var rowsImpl: NimNode
  var signalNames: seq[string]

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

  let ctorSym = nskProc.gensym "constructor"
  var constructor = buildAst procDef:
    ctorSym
    empty()
    empty()
    formalParams:
      empty()
      identDefs i"this", ptrTy ct, empty()
    empty()
    empty()
    stmtList:
      quote do:
        template self(): var `t` {.used.} = this[].self
      call s"wasMoved", i"self"

  for x in body:
    case x
    of Call[Ident(strVal: "rows"), @body is StmtList()]:
      rowsImpl = newCall(s"int", body)
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
          varSection: identDefs(pragmaExpr(i"this", pragma(i"used")), ptrTy ct, empty())
          pragma: exprColonExpr(i"emit", bracket(i"this", l" = this;"))
          quote do:
            template self(): var `t` {.used.} = this[].self
          call(s"cint", body)

    of Command[Ident(strVal: "elem"), Ident(strVal: @valname), @body is StmtList()]:
      if dataImpl.len == 0:
        decl.add "QVariant data(QModelIndex const& index, int role) const override;"
        decl.add "QHash<int, QByteArray> roleNames() const override;"
      dataImpl[valname] = body

    else: qobjectCasesImpl t, parent, body, ct, x, decl, impl, constructor, signalNames
  
  if rowsImpl == nil: error("rows must be declarated")

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
        varSection: identDefs(pragmaExpr(i"this", pragma(i"used")), ptrTy ct, empty())
        pragma: exprColonExpr(i"emit", bracket(i"this", l" = this;"))
        quote do:
          template self(): var `t` {.used.} = this[].self
        varSection:
          identDefs(pragmaExpr(i"i", pragma(i"used")), empty(), call(s"int", dotExpr(i, s"row")))
          identDefs(pragmaExpr(i"j", pragma(i"used")), empty(), call(s"int", dotExpr(i, s"column")))
        ifStmt: elifBranch:
          infix(s"notin", i"i"): infix(s"..<", newLit 0, rowsImpl)
          stmtList: returnStmt(empty())
        caseStmt role:
          var ri = 0x0100
          for _, v in dataImpl:
            inc ri
            ofBranch(newLit ri):
              call(s"toQVariant", call(s"toQtVal", v))
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

  let cts = ident"Ct"
  copyLineInfo(cts, body)

  buildAst(stmtList):
    pragma: exprColonExpr i"emit": newLit &"/*INCLUDESECTION*/ #include <{parent}>"
    pragma: exprColonExpr i"emit": bracket(newLit toEmit[0], t, " self;\n".l, newLit toEmit[1], newLit toEmit[2])
    pragma: exprColonExpr i"emit": bracket(newLit moc)
    templateDef:
      cts
      empty()
      empty()
      formalParams:
        i"type"
        identDefs:
          gensym nskParam
          command i"type", t
          empty()
      empty()
      empty()
      ct
    for x in impl: x
    constructor
    pragma:
      exprColonExpr i"emit":
        bracket:
          newLit fmt "{t}::{t}(QObject* parent): {parent}(parent) {{ "
          ctorSym
          l"(this); }"


macro dbusInterface*(t; obj: static string, body) =
  var t = t
  var parent = i"QDBusAbstractAdaptor"
  if t.kind == nnkInfix:
    parent = t[2]
    t = t[1]

  var decl: seq[string]
  var impl = newStmtList()
  var signalNames: seq[string]

  # add class info
  decl.add &"""Q_CLASSINFO("D-Bus Interface", {obj.quoted})"""

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

  let ctorSym = nskProc.gensym "constructor"
  var constructor = buildAst procDef:
    ctorSym
    empty()
    empty()
    formalParams:
      empty()
      identDefs i"this", ptrTy ct, empty()
    empty()
    empty()
    stmtList:
      quote do:
        template self(): var `t` {.used.} = this[].self
      call s"wasMoved", i"self"

  for x in body:
    qobjectCasesImpl t, parent, body, ct, x, decl, impl, constructor, signalNames

  let moc = moc qoClass($t, decl.join("\n"), $parent).join
  let toEmit = qoClass($t, decl.join("\n").indent(2), $parent)

  let cts = ident"Ct"
  copyLineInfo(cts, body)

  buildAst(stmtList):
    pragma: exprColonExpr i"emit": newLit &"/*INCLUDESECTION*/ #include <{parent}>"
    pragma: exprColonExpr i"emit": bracket(newLit toEmit[0], t, " self;\n".l, newLit toEmit[1], newLit toEmit[2])
    pragma: exprColonExpr i"emit": bracket(newLit moc)
    templateDef:
      cts
      empty()
      empty()
      formalParams:
        i"type"
        identDefs:
          gensym nskParam
          command i"type", t
          empty()
      empty()
      empty()
      ct
    for x in impl: x
    constructor
    pragma:
      exprColonExpr i"emit":
        bracket:
          newLit fmt "{t}::{t}(QObject* parent): {parent}(parent) {{ "
          ctorSym
          l"(this); }"


type
  QQmlEngine* {.importcpp: "QQmlEngine", header: "QQmlEngine".} = object
  QJSEngine* {.importcpp: "QJSEngine", header: "QJSEngine".} = object


proc registerInQmlC[T](
  module: cstring, verMajor, verMinor: cint, name: cstring, x: ptr T
) {.importcpp: "qmlRegisterType<'*5>(#, #, #, #)", header: "qqml.h".}

proc registerSingletonInQmlC[T](
  module: cstring, verMajor, verMinor: cint, name: cstring, f: proc(a: ptr QQmlEngine, b: ptr QJSEngine): ptr T {.cdecl.}, x: ptr T
) {.importcpp: "qmlRegisterSingletonType<'*6>(#, #, #, #, #)", header: "qqml.h".}

proc cnew(t: type): ptr t {.importcpp: "(new '*0)", nodecl.}

template registerInQml*(t: type, module: string, verMajor, verMinor: int) =
  bind registerInQmlC
  registerInQmlC[t.Ct](module, verMajor.cint, verMinor.cint, $t, nil)

template registerSingletonInQml*(t: type, module: string, verMajor, verMinor: int) =
  bind registerSingletonInQmlC, cnew
  var x = cnew t.Ct
  proc instance(a: ptr QQmlEngine, b: ptr QJSEngine): ptr t.Ct {.cdecl.} = x
  registerSingletonInQmlC[t.Ct](module.cstring, verMajor.cint, verMinor.cint, $t, instance, nil)

template registerSingletonInQml*(t: type, modules: varargs[(string, int, int)]) =
  bind registerSingletonInQmlC, cnew
  var x = cnew t.Ct
  proc instance(a: ptr QQmlEngine, b: ptr QJSEngine): ptr t.Ct {.cdecl.} = x
  for module in modules:
    registerSingletonInQmlC[t.Ct](module[0].cstring, module[1].cint, module[2].cint, $t, instance, nil)
