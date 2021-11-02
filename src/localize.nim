import macros, json, os
import fusion/astdsl
import configuration
export Language

var toTranslate {.compileTime.}: seq[tuple[s, comment, file: string]]
var translationsAccepted {.compileTime.}: bool

macro trImpl(s: static string, comment: static string, file: static string): string =
  if translationsAccepted: error("translations was accepted, put `updateTranslations()` under `tr` call")
  
  var i = toTranslate.find (s, comment, file)
  if i == -1:
    toTranslate.add (s, comment, file)
    i = toTranslate.high
  
  buildAst(caseStmt):
    call(bindSym"language", bindSym"config")
    
    for lang in Language.low..Language.high:
      ofBranch dotExpr(ident"Language", ident $lang):
        newLit:
          if fileExists("translations" / ($lang & ".json")):
            let f = readFile("translations" / ($lang & ".json")).parseJson
            f{file, s, comment}.getStr(s)
          else: s


template tr*(s: static string, comment: static string = ""): string =
  bind trImpl
  trImpl(s, comment, instantiationInfo().filename)


macro updateTranslations* =
  translationsAccepted = true

  var files: array[Language, JsonNode]

  for lang in Language.low..Language.high:
    if fileExists("translations" / ($lang & ".json")):
      files[lang] = readFile("translations" / ($lang & ".json")).parseJson
    else:
      files[lang] = %*{:}

  for lang, f in files.mpairs:
    var r = %*{:}

    for i, x in toTranslate:
      r{x.file, x.s, x.comment} = newJString f{x.file, x.s, x.comment}.getStr(x.s)
    
    writeFile("translations" / ($lang & ".json"), r.pretty)
