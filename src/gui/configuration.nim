{.used.}
import json, os, math, macros, options
import fusion/matching, fusion/astdsl, localize
import ../utils
import qt

{.experimental: "caseStmtMacros".}

let configDir* =
  when defined(linux): getHomeDir() / ".config/DMusic"
  else: "."

let dataDir* =
  when defined(linux): getHomeDir() / ".local/share/DMusic"
  else: "."

type ConfigObj* = distinct JsonNode

proc readConfig*: ConfigObj =
  if fileExists(configDir/"config.json"):
    return readFile(configDir/"config.json").parseJson.ConfigObj
  else:
    result = ConfigObj newJObject()
    case systemLocale().lang
    of "ru": JsonNode(result){"language"} = newJString "ru"

proc save*(config: ConfigObj) =
  createDir configDir
  writeFile(configDir/"config.json", config.JsonNode.pretty)

var config* = readConfig()


type
  Language* {.pure.} = enum
    en, ru

  LoopMode* {.pure.} = enum
    none, playlist, track


type Config = object

template i(s: string{lit}): NimNode = ident s
template s(s: string{lit}): NimNode = bindSym s

proc genconfigImpl(body: NimNode, path: seq[string], prefix: string, stmts, qobj, ctor: var NimNode) =
  proc entry(typ: NimNode, aname: NimNode, def: Option[NimNode]; stmts, qobj, ctor: var NimNode, sethook = ident"v") =
    let name = ident prefix & $aname
    copyLineInfo(name, aname)

    let notify = ident("notify" & ($name).capitalizeFirst & "Changed")

    let qtyp = case $typ
      of "string", "float", "int", "bool": typ
      else: i"int"

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
      command qtyp, name
      stmtList:
        call i"get":
          if qtyp == typ:
            call name, i"config"
          else:
            call qtyp, call(name, i"config")
        call i"set":
          if qtyp == typ:
            asgn dotExpr(i"config", name), i"value"
          else:
            asgn dotExpr(i"config", name), call(typ, i"value")
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
  Language language
  string colorAccentDark "#FCE165"
  string colorAccentLight "#FFA800"

  bool csd true

  int width 1280
  int height 720
  
  float volume 0.5 v.round(2).max(0).min(1)
  bool shuffle
  LoopMode loop

  bool darkTheme true
  bool darkHeader true
  bool themeByTime true

  bool discordPresence

  ym "Yandex.Music":
    string token
    string email
    
    bool saveAllTracks false
    bool skipRadioDuplicates true

registerSingletonInQml Config, ("DMusic", 1, 0), ("Config", 1, 0)


initLocalize Language, call(bindSym"language", bindSym"config")
