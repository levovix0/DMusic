import json, os, math, macros, options, logging
import fusion/matching, fusion/astdsl, localize
import ./utils
export localize
export logging except error, warning, info

{.experimental: "caseStmtMacros".}

type
  Language* {.pure.} = enum
    en, ru

  LoopMode* {.pure.} = enum
    none, playlist, track
  
  ConfigObj* = distinct JsonNode


requireLocalesToBeTranslated ("ru", ""), ("eo", "")

let configDir* =
  when defined(linux): getHomeDir() / ".config/DMusic"
  else: "."

let dataDir* =
  when defined(linux): getHomeDir() / ".local/share/DMusic"
  else: "."

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


template i(s: string{lit}): NimNode = ident s
template s(s: string{lit}): NimNode = bindSym s

proc genconfigImpl(body: NimNode, path: seq[string], prefix: string, stmts: var NimNode) =
  proc entry(typ: NimNode, aname: NimNode, def: Option[NimNode]; stmts: var NimNode, sethook = ident"v") =
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

  for x in body:
    case x
    
    of Command[@typ, Command[@name is Ident(), Command[@def, @sethook]]]:
      entry(typ, name, some def, stmts, sethook)
    
    of Command[@typ, Command[@name is Ident(), @def]]:
      entry(typ, name, some def, stmts)
    
    of Command[@typ, @name is Ident()]:
      entry(typ, name, none NimNode, stmts)
    
    of Command[Ident(strVal: @prefix2), StrLit(strVal: @name), @body is StmtList()]:
      genconfigImpl(body, path & name, prefix & prefix2 & "_", stmts)
    
    else: error("Unexpected syntax", x)

macro genconfig(body) =
  result = newStmtList()
  genconfigImpl(body, @[], "", result)


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
  bool darkHeader false
  bool themeByTime false

  bool discordPresence

  string proxyServer
  string proxyAuth

  string logFile "log.txt"

  ym "Yandex.Music":
    string token
    string email
    
    bool saveAllTracks false
    bool skipRadioDuplicates true


var logger* =
  if config.logFile == "": newConsoleLogger()
  elif config.logFile.isAbsolute: newFileLogger(config.logFile)
  else: newFileLogger(dataDir / config.logFile)
logger.log(lvlInfo, "new session")