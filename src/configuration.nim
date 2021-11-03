import json, os, math, macros, options
import fusion/matching, fusion/astdsl
import qt, utils

{.experimental: "caseStmtMacros".}

let configDir* =
  when defined(linux): getHomeDir() / ".config/DMusic"
  else: "."

let dataDir* =
  when defined(linux): getHomeDir() / ".local/share/DMusic"
  else: "."

proc get(x: JsonNode, t: type): t =
  try: x.to(t) except: t.default
proc get(x: JsonNode, t: type, default: t): t =
  try: x.to(t) except: default

type ConfigObj* = distinct JsonNode

proc readConfig*: ConfigObj =
  if fileExists(configDir/"config.json"):
    readFile(configDir/"config.json").parseJson.ConfigObj
  else: ConfigObj %{:}

proc save*(config: ConfigObj) =
  createDir configDir
  writeFile(configDir/"config.json", config.JsonNode.pretty)

var config* = readConfig()


type
  Language* {.pure.} = enum
    en, ru

  LoopMode* {.pure.} = enum
    none, playlist, track

# some magic
discard
{.emit: """/*TYPESECTION*/
typedef NU8 Language;
typedef NU8 LoopMode;
""".}

type Config = object

template i(s: string{lit}): NimNode = ident s
template s(s: string{lit}): NimNode = bindSym s

proc genconfigImpl(body: NimNode, path: seq[string], prefix: string, stmts, qobj, ctor: var NimNode) =
  proc entry(typ: NimNode, aname: NimNode, def: Option[NimNode]; stmts, qobj, ctor: var NimNode, sethook = ident"v") =
    let name = ident prefix & $aname
    copyLineInfo(name, aname)

    let notify = ident("notify" & ($name).capitalizeFirst & "Changed")

    stmts.add quote do:
      var `notify`*: proc() = proc() = discard
    
    stmts.add: buildAst(procDef):
      postfix i"*", name
      empty()
      empty()
      formalParams:
        typ
        newIdentDefs(i"config", s"ConfigObj")
      empty()
      empty()
      call i"get":
        curlyExpr:
          call i"JsonNode", i"config"
          for x in path: newLit x
          newLit $aname
        command i"type", typ
        if def.isSome: def.get
    
    stmts.add: buildAst(procDef):
      postfix i"*", accQuoted(name, i"=")
      empty()
      empty()
      formalParams:
        empty()
        newIdentDefs(i"config", s"ConfigObj")
        newIdentDefs(i"v", typ)
      empty()
      empty()
      stmtList:
        ifStmt:
          elifBranch:
            call i"==", sethook, call(name, i"config")
            stmtList: returnStmt empty()
        asgn:
          curlyExpr call(i"JsonNode", i"config"):
            for x in path: newLit x
            newLit $aname
          call i"%*", sethook
        call i"save", i"config"
        call notify
    
    qobj.add: buildAst(command):
      i"property"
      command typ, name
      stmtList:
        call i"get":
          call name, i"config"
        call i"set":
          asgn dotExpr(i"config", name), i"value"
        i"notify"
    
    ctor.add: buildAst:
      call i"&=", notify:
        Lambda:
          empty()
          empty()
          empty()
          formalParams: empty()
          empty()
          empty()
          call ident($name & "Changed"), i"this"

  for x in body:
    case x
    
    of Command[@typ, Command[@name is Ident(), Command[@def, @sethook]]]:
      entry(typ, name, some def, stmts, qobj, ctor, sethook)
    
    of Command[@typ, Command[@name is Ident(), @def]]:
      entry(typ, name, some def, stmts, qobj, ctor)
    
    of Command[@typ, @name is Ident()]:
      entry(typ, name, none NimNode, stmts, qobj, ctor)
    
    of Command[Ident(strVal: @prefix2), StrLit(strVal: @name), @body is StmtList()]:
      genconfigImpl(body, path & name, prefix & prefix2 & "_", stmts, qobj, ctor)
    
    else: error("Unexpected syntax", x)

macro genconfig(body) =
  result = newStmtList()
  var qobj = newStmtList()
  var ctor = newStmtList()
  genconfigImpl(body, @[], "", result, qobj, ctor)

  result.add: buildAst:
    call s"qobject", s"Config": stmtList:
      for x in qobj: x
      procDef accQuoted(i"=", i"new"):
        empty()
        empty()
        formalParams: empty()
        empty()
        empty()
        stmtList:
          for x in ctor: x


genconfig:
  int i_language
  string colorAccentDark "#FCE165"
  string colorAccentLight "#FFA800"

  bool csd true

  int width 1280
  int height 720
  
  float volume 0.5 v.round(2).max(0).min(1)
  bool shuffle
  int i_loop

  bool darkTheme true
  bool darkHeader true
  bool themeByTime true

  bool discordPresence

  ym "Yandex.Music":
    string token
    string email
    
    bool saveAllTracks false

registerSingletonInQml Config, ("DMusic", 1, 0), ("Config", 1, 0)

proc language*(config: ConfigObj): Language = Language config.i_language
proc `language=`*(config: ConfigObj, v: Language) = config.i_language = v.ord
proc loop*(config: ConfigObj): LoopMode = LoopMode config.i_loop
proc `loop=`*(config: ConfigObj, v: LoopMode) = config.i_loop = v.ord

config.ym_token = "AgAAAAAwR49zAAG8XhIxS-ofH0kDr_W8ZMZLUkg"
