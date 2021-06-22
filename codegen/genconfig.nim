import macros, fusion/matching, strformat, strutils, sequtils
import unicode except strip

{.experimental: "caseStmtMacros".}

type
  CEnum = object
    name: string
    fields: seq[string]
    toString: string

  CVar = object
    name: string
    typ: string
    def: string
    prop: string
    decl: string
    signal: string
    get: string
    set: string
    getImpl: string
    setImpl: string
    jsonName: string
    serialize: string
    deserialize: string

  ReadConfigResult = tuple
    types: seq[string]
    properties: string
    getters: string
    setters: string
    signals: string
    privates: string
    impls: seq[string]
    readJson: string
    writeJson: string
    outOfClass: seq[string]


converter toRune(s: string): Rune = s.runeAt(0)
func escape(s: string): string =
  ## escapes stirng to C format
  for c in s.runes:
    case c
    of "\n": result.add r"\n"
    of "\'": result.add r"\'"
    of "\"": result.add r"\"""
    of "\\": result.add r"\\"
    of "\a": result.add r"\a"
    of "\b": result.add r"\b"
    of "\f": result.add r"\f"
    of "\r": result.add r"\r"
    of "\t": result.add r"\t"
    of "\v": result.add r"\v"
    else: result.add c.toUTF8

const
  lb = "{"
  rb = "}"
  newLine = {'\n'}

var enums {.compileTime.}: seq[CEnum]
var classname {.compileTime.}: string
proc setClassname(v: string) {.compileTime.} =
  classname = v

proc function(head, body: string): string =
  head & " {\n" & body.indent(2) & "\n}"

proc fill(a: var CVar, prefix: string, isEnum = false) =
  let isEnum = isEnum or a.typ in enums.mapit(it.name)
  let fullTypename = if a.typ in enums.mapit(it.name): &"{classname}::{a.typ}" else: a.typ
  let capName =
    if prefix == "": a.name.runeAt(0).toUpper.toUTF8 & a.name[a.name.runeLenAt(0)..^1]
    else: &"_{a.name}"

  a.prop = &"Q_PROPERTY({a.typ} {a.name} READ {a.name} WRITE set{capName} NOTIFY {a.name}Changed)"
  a.decl =
    if a.def == "": &"inline static {a.typ} _{a.name};"
    else: &"inline static {a.typ} _{a.name} = {a.def};"
  a.signal = &"void {a.name}Changed({a.typ} {a.name});"

  a.get = &"static {a.typ} {a.name}();"
  a.set = &"void set{capName}({a.typ} v);"
  a.getImpl = function(&"{fullTypename} {classname}::{a.name}()", &"return _{a.name};")
  a.setImpl = function(&"void {classname}::set{capName}({fullTypename} v)", &"""
if (_{a.name} == v) return;
_{a.name} = v;
emit {a.name}Changed(_{a.name});
saveToJson();""")

  let doc = if prefix == "": "doc" else: prefix
  a.serialize = &"{doc}[\"{a.jsonName}\"] = _{a.name};"
  a.deserialize =
    case a.typ
    of "QString": &"_{a.name} = {doc}[\"{a.jsonName}\"].toString({a.def});"
    of "int": &"_{a.name} = {doc}[\"{a.jsonName}\"].toInt({a.def});"
    of "bool": &"_{a.name} = {doc}[\"{a.jsonName}\"].toBool({a.def});"
    of "float": &"_{a.name} = {doc}[\"{a.jsonName}\"].toFloat({a.def});"
    of "double": &"_{a.name} = {doc}[\"{a.jsonName}\"].toDouble({a.def});"
    elif isEnum: &"_{a.name} = ({a.typ}){doc}[\"{a.jsonName}\"].toInt({a.def});"
    else: &"_{a.name} = deserialize<{a.typ}>({doc}[\"{a.jsonName}\"], {a.def});"
  a.deserialize.add &"\nemit {a.name}Changed(_{a.name});"

proc add(a: var ReadConfigResult, b: CVar) =
  a.properties.add b.prop & "\n"
  a.privates.add b.decl & "\n"
  a.signals.add b.signal & "\n"
  a.getters.add b.get & "\n"
  a.setters.add b.set & "\n"
  a.impls.add b.getImpl
  a.impls.add b.setImpl
  a.writeJson.add b.serialize & "\n"
  a.readJson.add b.deserialize & "\n"

proc readConfig(body: NimNode; prefix: string): ReadConfigResult =
  for line in body:
    case line
    of Command[Ident(strVal: "config"), Ident(strVal: @prefix2), StrLit(strVal: @jsonName), @body2 is StmtList()]:
      ## recurse readConfig
      let res = readConfig(body2, &"{prefix}{prefix2}_")
      result.types &= res.types
      result.outOfClass &= res.outOfClass
      result.properties &= "\n" & res.properties
      result.getters &= "\n" & res.getters
      result.setters &= "\n" & res.setters
      result.signals &= "\n" & res.signals
      result.privates &= "\n" & res.privates
      result.impls &= res.impls
      let doc = if prefix == "": "doc" else: prefix
      result.readJson.add "\n"
      result.readJson.add &"""
QJsonObject {prefix}{prefix2}_ = {doc}["{jsonName}"].toObject();
if (!{prefix}{prefix2}_.isEmpty()) {lb}
{res.readJson.strip(chars=newLine).indent(2)}
{rb}"""
      result.writeJson.add &"\nQJsonObject {prefix}{prefix2}_;\n"
      result.writeJson.add res.writeJson
      result.writeJson.add &"{doc}[\"{jsonName}\"] = {prefix}{prefix2}_;\n"
    
    of Command[Ident(strVal: "dir"), Command[Ident(strVal: @name), StrLit(strVal: @uri)]]:
      ## dir
      [@protocol, @path, .._] := uri.split(":")
      let cpath = &"{protocol}Dir()" & "/" & path.split("/").mapit(&"\"{it.escape}\"").join("/")
      result.getters.add &"static Dir {prefix}{name}();\n"
      result.impls.add function(&"Dir {classname}::{prefix}{name}()", &"return {cpath};")
    
    of Command[
      Ident(strVal: "get"),
      Command[
        Ident(strVal: @typ),
        Ident(strVal: @name)
      ],
      StmtList[TripleStrLit(strVal: @cbody)]
    ]:
      ## getter
      result.getters.add &"static {typ} {prefix}{name}();\n"
      result.impls.add function(&"{typ} {classname}::{prefix}{name}()", cbody.unindent.strip)
  
    of Command[
      Ident(strVal: "get"),
      Command[
        Ident(strVal: @typ),
        Call[Ident(strVal: @name), all @args]
      ],
      StmtList[TripleStrLit(strVal: @cbody)]
    ]:
      ## getter
      var cargs: seq[string]
      for arg in args:
        case arg
        of Command[Ident(strVal: @typ), Ident(strVal: @argname)]: cargs.add &"{typ} {argname}"
        else: discard
      let sargs = cargs.join(", ")
      result.getters.add &"static {typ} {prefix}{name}({sargs});\n"
      result.impls.add function(&"{typ} {classname}::{prefix}{name}({sargs})", cbody.unindent.strip)
    
    of Command[Ident(strVal: @typ), Ident(strVal: @name)]:
      ## var
      var res = CVar(name: prefix & name, typ: typ, jsonName: name)

      case typ
      of "string", "QString":
        res.typ = "QString"
        res.def = "\"\""
      of "int", "double", "float":
        res.def = "0"
      of "bool":
        res.def = "false"
      
      fill res, prefix
      result.add res
    
    of Command[Ident(strVal: @typ), Command[Ident(strVal: @name), @defVal]]:
      ## var
      var res = CVar(name: prefix & name, typ: typ, jsonName: name)
      
      if typ == "string": res.typ = "QString"
      res.def = case defVal
      of StrLit(strVal: @v): '"' & v.escape & '"'
      of Ident(): defVal.strVal
      of IntLit(): $defVal.intVal
      of FloatLit(): $defVal.floatVal
      else: ""
      
      fill res, prefix
      result.add res
    
    of Command[PragmaExpr[Ident(strVal: @typ), Pragma[EnumTy()]], Command[Ident(strVal: @name), @defVal]]:
      ## enum var
      var res = CVar(name: prefix & name, typ: typ, jsonName: name)
      
      res.def = case defVal
      of StrLit(strVal: @v): v
      of Ident(), IntLit(), FloatLit(): defVal.strVal
      else: ""
      
      fill res, prefix, true
      result.add res
    
    of TypeSection[TypeDef[Ident(strVal: @name), Empty(), EnumTy[Empty(), all @fields]]]:
      ## enum
      var res = CEnum(name: name)
      let fullName = &"{classname}::{name}"

      for field in fields:
        let `else` = if res.fields.len == 0: "" else: "else "

        case field
        of Ident(strVal: @fieldName):
          res.fields.add fieldName
          res.toString.add &"{`else`}if (v == {fullName}::{fieldName}) return \"{fieldName}\";\n"
        
        of EnumFieldDef[Ident(strVal: @fieldName), StrLit(strVal: @fieldStr)]:
          res.fields.add fieldName
          res.toString.add &"{`else`}if (v == {fullName}::{fieldName}) return \"{fieldStr.escape}\";\n"
      
      res.toString.add &"""return "";"""
      var decl = "{\n" & res.fields.join(",\n").indent(2) & "\n};"
      decl = &"enum {name} {decl}\nQ_ENUM({name})\n"

      res.toString = function(&"inline QString toString({fullName} v)", res.toString)
      result.types.add decl
      result.outOfClass.add res.toString
      
      enums.add res

macro genconfig*(classname, header, source, appname: static[string]; body: untyped): untyped =
  body.expectKind nnkStmtList
  setClassname classname
  var imports = """
// This file was generated, don't edit it
#pragma once
#include <QString>
#include <QObject>
#include "Dir.hpp"
"""
  var srcImports = &"""
// This file was generated, don't edit it
#include "{header}"
#include <QFile>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
"""

  for line in body:
    case line
    of Call[Ident(strVal: "imports"), @imps is StmtList()]:
      for x in imps:
        case x
        of StrLit(strVal: @file):
          imports.add:
            if file.startsWith("<") and file.endsWith(">"): &"#include {file}\n"
            else: &"#include \"{file}\"\n"
        of Ident(strVal: @file):
          imports.add &"#include <{file}>\n"
    
    of Call[Ident(strVal: "srcimports"), @imps is StmtList()]:
      for x in imps:
        case x
        of StrLit(strVal: @file):
          srcImports.add:
            if file.startsWith("<") and file.endsWith(">"): &"#include {file}\n"
            else: &"#include \"{file}\"\n"
        of Ident(strVal: @file):
          srcImports.add &"#include <{file}>\n"
  
  let res = readConfig(body, "")
  let outOfClass = res.outOfClass.join("\n\n")
  let types = res.types.join("\n")
  let impls = res.impls.join("\n\n")

  let hpp = &"""
{imports}
class {classname}: public QObject
{lb}
  Q_OBJECT
public:
  {classname}();
  ~{classname}();

{types.strip(chars=newLine).indent(2)}

{res.properties.strip(chars=newLine).indent(2)}

  static Dir settingsDir();
  static Dir dataDir();

{res.getters.strip(chars=newLine).indent(2)}

public slots:
{res.setters.strip(chars=newLine).indent(2)}

  void reloadFromJson();
  void saveToJson();

signals:
{res.signals.strip(chars=newLine).indent(2)}

private:
{res.privates.strip(chars=newLine).indent(2)}
{rb};

{outOfClass}
"""
  
  let cpp = &"""
{srcimports}

{classname}::{classname}() {lb}
  if (!settingsDir().qfile("config.json").exists())
    saveToJson();  // generate default config
  else
    reloadFromJson();
{rb}

{classname}::~{classname}() {lb}{rb}

Dir {classname}::settingsDir() {lb}
#ifdef Q_OS_LINUX
  if (!(Dir::home()/".config"/"{appname}").exists())
    Dir::home().mkpath(".config/{appname}");
  return Dir::home()/".config"/"{appname}";
#else
  return Dir::current();
#endif
{rb}

Dir {classname}::dataDir() {lb}
#ifdef Q_OS_LINUX
  if (!(Dir::home()/".local"/"share"/"{appname}").exists())
    Dir::home().mkpath(".local/share/{appname}");
  return Dir::home()/".local"/"share"/"{appname}";
#else
  return Dir::current();
#endif
{rb}

{impls}

void {classname}::reloadFromJson() {lb}
  if (!settingsDir().qfile("config.json").exists()) return;
  QJsonObject doc = settingsDir().file("config.json").allJson().object();
  if (doc.isEmpty()) return;

{res.readJson.indent(2)}
{rb}

void {classname}::saveToJson() {lb}
  QJsonObject doc;

{res.writeJson.indent(2)}
  settingsDir().file("config.json").writeAll(doc, QJsonDocument::Indented);
{rb}
"""

  writeFile header, hpp
  writeFile source, cpp
